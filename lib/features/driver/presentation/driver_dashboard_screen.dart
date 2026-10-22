import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/app_providers.dart';
import '../data/driver_models.dart';
import '../data/driver_repository.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  Timer? _refreshTimer;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ref.invalidate(driverDashboardProvider),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action, String success) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      ref.invalidate(driverDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(driverDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(driverDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _working
                ? null
                : () => ref.read(sessionProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(driverDashboardProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(DriverDashboardData data) => RefreshIndicator(
    onRefresh: () => ref.refresh(driverDashboardProvider.future),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Hello, ${data.driver.name}',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _BusCard(bus: data.bus),
        const SizedBox(height: 16),
        _TripCard(
          trip: data.trip,
          bus: data.bus,
          students: data.students,
          working: _working,
          onStart: (type) => _perform(
            () => ref
                .read(driverRepositoryProvider)
                .startTrip(data.bus!.id, type),
            '${type == 'PICKUP' ? 'Pickup' : 'Drop-off'} trip started',
          ),
          onComplete: () => _perform(
            () =>
                ref.read(driverRepositoryProvider).completeTrip(data.trip!.id),
            'Trip completed',
          ),
        ),
        if (data.trip != null && data.bus != null) ...[
          const SizedBox(height: 16),
          _ScannerModeCard(
            scanMode: data.bus!.scanMode,
            working: _working,
            onChanged: (mode) => _perform(
              () => ref.read(driverRepositoryProvider).setScannerMode(mode),
              mode == 'BOARDING'
                  ? 'Scanner ready for boarding'
                  : 'Scanner ready for student exits',
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Assigned students (${data.students.length})',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'This list refreshes automatically after RFID scans.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (data.students.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No students are assigned to this bus.'),
            ),
          )
        else
          for (final student in data.students) ...[
            _StudentCard(
              student: student,
              hasActiveTrip: data.trip != null,
              working: _working,
              onConfirm: () => _perform(
                () => ref
                    .read(driverRepositoryProvider)
                    .confirmDropoff(data.trip!.id, student.id),
                '${student.name} drop-off confirmed',
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    ),
  );
}

class _ScannerModeCard extends StatelessWidget {
  const _ScannerModeCard({
    required this.scanMode,
    required this.working,
    required this.onChanged,
  });

  final String? scanMode;
  final bool working;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isBoarding = scanMode == 'BOARDING';
    final isExit = scanMode == 'EXIT';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isExit ? Icons.logout_rounded : Icons.login_rounded,
                  color: isExit ? AppColors.warning : AppColors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'RFID scanner mode',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isExit
                  ? 'Scans now record students leaving the bus.'
                  : 'Scans now record students entering the bus.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: working || isBoarding
                        ? null
                        : () => onChanged('BOARDING'),
                    icon: const Icon(Icons.directions_bus_filled_outlined),
                    label: const Text('Boarding'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: working || isExit
                        ? null
                        : () => onChanged('EXIT'),
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Student exits'),
                  ),
                ),
              ],
            ),
            if (scanMode == null) ...[
              const SizedBox(height: 10),
              const Text(
                'No scanner is assigned to this bus.',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  const _BusCard({required this.bus});
  final DriverBus? bus;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.navy,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF264566),
            child: Icon(Icons.directions_bus_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus == null ? 'No bus assigned' : 'Bus ${bus!.busNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (bus != null)
                  Text(
                    bus!.registrationNumber,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.bus,
    required this.students,
    required this.working,
    required this.onStart,
    required this.onComplete,
  });

  final DriverTrip? trip;
  final DriverBus? bus;
  final List<DriverStudent> students;
  final bool working;
  final ValueChanged<String> onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final stillOnBus = students
        .where((student) => student.tripStatus == 'ON_BUS')
        .length;
    final awaitingConfirmation = students
        .where((student) => student.tripStatus == 'EXITED')
        .length;
    final canComplete = stillOnBus == 0 && awaitingConfirmation == 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              trip == null
                  ? 'No active trip'
                  : '${trip!.typeLabel} trip active',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              trip == null
                  ? 'Choose a trip type when you are ready to begin.'
                  : 'RFID boarding and exit scans will appear below.',
            ),
            const SizedBox(height: 16),
            if (trip == null) ...[
              FilledButton.icon(
                onPressed: working || bus == null
                    ? null
                    : () => onStart('PICKUP'),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Start pickup trip'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: working || bus == null
                    ? null
                    : () => onStart('DROPOFF'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Start drop-off trip'),
              ),
            ] else ...[
              if (!canComplete) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stillOnBus > 0
                        ? '$stillOnBus ${stillOnBus == 1 ? 'student is' : 'students are'} still on the bus. Record the exit scan before completing the trip.'
                        : '$awaitingConfirmation drop-off ${awaitingConfirmation == 1 ? 'confirmation is' : 'confirmations are'} still required.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: working || !canComplete ? null : onComplete,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Complete trip'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.hasActiveTrip,
    required this.working,
    required this.onConfirm,
  });

  final DriverStudent student;
  final bool hasActiveTrip;
  final bool working;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final color = switch (student.tripStatus) {
      'ON_BUS' => AppColors.blue,
      'EXITED' => AppColors.warning,
      'DROPPED_OFF' => AppColors.success,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: .14),
                  foregroundColor: color,
                  child: Text(student.name.isEmpty ? '?' : student.name[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${student.studentNumber} • Grade ${student.grade}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    student.statusLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (student.tripStatus == 'ON_BUS') ...[
              const SizedBox(height: 8),
              const Text('Waiting for the student’s exit RFID scan.'),
            ],
            if (student.canConfirmDropoff && hasActiveTrip) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: working ? null : onConfirm,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Confirm student drop-off'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
