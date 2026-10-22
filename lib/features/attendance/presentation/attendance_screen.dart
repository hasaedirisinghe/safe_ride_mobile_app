import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/app_providers.dart';

Color attendanceStatusColor(AttendanceStatus status) => switch (status) {
  AttendanceStatus.dropoffConfirmed ||
  AttendanceStatus.boarded => AppColors.success,
  AttendanceStatus.verificationException => AppColors.error,
  AttendanceStatus.awaitingDriverConfirmation ||
  AttendanceStatus.pending ||
  AttendanceStatus.exitScanned => AppColors.warning,
  AttendanceStatus.absent => Colors.grey,
};

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(selectedStudentProvider);
    final records = ref.watch(attendanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance history'),
        actions: [
          if (AppConfig.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: DemoBanner()),
            ),
        ],
      ),
      body: student == null
          ? const EmptyState(
              icon: Icons.event_busy,
              title: 'Select a student',
              message: 'Choose a student on Home to see transport attendance.',
            )
          : records.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  ErrorState(onRetry: () => ref.invalidate(attendanceProvider)),
              data: (items) {
                if (items.isEmpty)
                  return const EmptyState(
                    icon: Icons.event_note,
                    title: 'No attendance yet',
                    message: 'Verified transport events will appear here.',
                  );
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(attendanceProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        <Widget>[
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                child: Text(student.name[0]),
                              ),
                              title: Text(
                                student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: const Text(
                                'Official records are read-only and provided by SafeRide-LK.',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ] +
                        items
                            .map<Widget>(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RecordCard(record: record),
                              ),
                            )
                            .toList(),
                  ),
                );
              },
            ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) {
    final status = record.destinationVerificationStatus;
    final color = attendanceStatusColor(status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/attendance/${record.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(record.date),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.tripType.name[0].toUpperCase()}${record.tripType.name.substring(1)} trip • ${record.vehicle}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 26),
              Row(
                children: [
                  Expanded(
                    child: _TimePoint(
                      icon: Icons.login_rounded,
                      label: 'Boarded',
                      time: formatTime(record.boardingTime),
                      active: record.boardingTime != null,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _TimePoint(
                      icon: Icons.verified_rounded,
                      label: 'Drop-off',
                      time: formatTime(record.dropoffTime),
                      active: record.dropoffTime != null,
                    ),
                  ),
                ],
              ),
              if (record.warning != null)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.warning!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  const _TimePoint({
    required this.icon,
    required this.label,
    required this.time,
    required this.active,
  });
  final IconData icon;
  final String label;
  final String time;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: (active ? AppColors.success : Colors.grey).withValues(
          alpha: .12,
        ),
        child: Icon(
          icon,
          size: 17,
          color: active ? AppColors.success : Colors.grey,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(time, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class TripDetailsScreen extends ConsumerWidget {
  const TripDetailsScreen({super.key, required this.recordId});
  final String recordId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(attendanceProvider).value ?? const <AttendanceRecord>[];
    final matches = records.where((r) => r.id == recordId);
    if (matches.isEmpty)
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Record unavailable',
          message: 'This attendance record could not be found.',
        ),
      );
    final r = matches.first;
    final steps = [
      ('Boarding scan', r.boardingTime, r.boardingStatus.label),
      (
        'Exit scan',
        r.exitScanTime,
        r.exitScanTime == null ? 'Not recorded' : 'Recorded',
      ),
      (
        'Driver confirmation',
        r.driverConfirmationTime,
        r.driverConfirmationTime == null ? 'Pending' : 'Confirmed',
      ),
      (
        'Destination verification',
        r.dropoffTime,
        r.destinationVerificationStatus.label,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            formatDate(r.date),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text('${r.tripType.name} trip • ${r.vehicle}'),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map(
            (entry) => _TimelineStep(
              title: entry.value.$1,
              time: entry.value.$2,
              status: entry.value.$3,
              last: entry.key == steps.length - 1,
            ),
          ),
          if (r.warning != null)
            Card(
              color: AppColors.error.withValues(alpha: .08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  r.warning!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.time,
    required this.status,
    required this.last,
  });
  final String title;
  final DateTime? time;
  final String status;
  final bool last;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: time == null ? Colors.grey : AppColors.success,
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(status),
                Text(
                  formatTime(time),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
