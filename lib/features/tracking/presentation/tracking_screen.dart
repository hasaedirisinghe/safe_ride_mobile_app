import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/app_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  Timer? _poller;
  GoogleMapController? _controller;
  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(
      const Duration(seconds: 15),
      (_) => ref.invalidate(locationProvider),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);
    final location = ref.watch(locationProvider);
    final trip = ref.watch(currentTripProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track bus'),
        actions: [
          if (AppConfig.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: DemoBanner(label: 'SIMULATED')),
            ),
        ],
      ),
      body: student == null
          ? const EmptyState(
              icon: Icons.directions_bus_outlined,
              title: 'Select a student',
              message: 'Choose a student on Home to view assigned transport.',
            )
          : location.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  ErrorState(onRetry: () => ref.invalidate(locationProvider)),
              data: (point) => point == null
                  ? const EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'Location unavailable',
                      message: 'The driver has not shared a recent vehicle location. No position has been estimated.',
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              _TrackingMap(
                                location: point,
                                onCreated: (controller) =>
                                    _controller = controller,
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                top: 16,
                                child: _MapBanner(location: point),
                              ),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton.small(
                                  heroTag: 'centerMap',
                                  onPressed: () => _controller?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(point.latitude, point.longitude),
                                      15,
                                    ),
                                  ),
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _TripSheet(
                          student: student,
                          location: point,
                          status:
                              trip.value?.status.label ?? student.status.label,
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.location, required this.onCreated});
  final VehicleLocation location;
  final ValueChanged<GoogleMapController> onCreated;
  @override
  Widget build(BuildContext context) {
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!AppConfig.demoMode && mobile)
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('vehicle'),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: const InfoWindow(title: 'Assigned vehicle'),
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: onCreated,
      );
    return CustomPaint(
      painter: _DemoMapPainter(Theme.of(context).brightness),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _DemoMapPainter extends CustomPainter {
  const _DemoMapPainter(this.brightness);
  final Brightness brightness;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF152638)
          : const Color(0xFFE8EEF3);
    canvas.drawRect(Offset.zero & size, bg);
    final road = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF31485C)
          : Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF22384B)
          : const Color(0xFFD5E1E8)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    for (var i = -1; i < 6; i++) {
      canvas.drawLine(
        Offset(i * 95, 0),
        Offset(i * 95 + 180, size.height),
        i.isEven ? road : thin,
      );
      canvas.drawLine(
        Offset(0, i * 85 + 30),
        Offset(size.width, i * 85 - 50),
        i.isOdd ? road : thin,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DemoMapPainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}

class _MapBanner extends StatelessWidget {
  const _MapBanner({required this.location});
  final VehicleLocation location;
  @override
  Widget build(BuildContext context) {
    final stale = location.isStale();
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: stale
          ? const Color(0xFFFFF4E0)
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              stale ? Icons.warning_amber_rounded : Icons.sensors_rounded,
              color: stale ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stale
                    ? 'Location is stale — last update ${relativeTime(location.recordedAt)}'
                    : 'Location updated ${relativeTime(location.recordedAt)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripSheet extends StatelessWidget {
  const _TripSheet({
    required this.student,
    required this.location,
    required this.status,
  });
  final Student student;
  final VehicleLocation location;
  final String status;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.assignedVehicle.registrationNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      student.assignedVehicle.routeName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Last update',
                  value: formatTime(location.recordedAt),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Estimated arrival',
                  value: formatTime(location.estimatedArrival),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'GPS accuracy',
                  value: '±${location.accuracy.round()} m',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
