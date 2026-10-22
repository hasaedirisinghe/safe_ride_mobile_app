import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/providers/app_providers.dart';

class StudentDetailsScreen extends ConsumerWidget {
  const StudentDetailsScreen({super.key, required this.studentId});
  final String studentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Student details')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            ErrorState(onRetry: () => ref.invalidate(studentsProvider)),
        data: (items) {
          final matches = items.where((s) => s.id == studentId);
          if (matches.isEmpty)
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Student unavailable',
              message: 'This student is not linked to your account.',
            );
          final s = matches.first;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.blue.withValues(alpha: .12),
                  child: Text(
                    s.name[0],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                s.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${s.grade} • ${s.schoolName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _DetailsCard(
                title: 'Transport assignment',
                rows: [
                  ('Vehicle', s.assignedVehicle.registrationNumber),
                  ('Driver', s.assignedVehicle.driverName),
                  ('Morning route', s.morningRoute),
                  ('Afternoon route', s.afternoonRoute),
                ],
              ),
              const SizedBox(height: 14),
              _DetailsCard(
                title: 'Authorized locations',
                rows: [
                  ('Pickup', s.pickupLocation),
                  ('Drop-off', s.dropoffLocation),
                  ('Guardian relationship', s.relationship),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer
                    .withValues(alpha: .45),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Assignments and safety locations are read-only. Changes require school or backend authorization.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const Divider(height: 24),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
