import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/app_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStatusRefresh();
  }

  void _startStatusRefresh() {
    _refreshTimer?.cancel();
    if (AppConfig.demoMode) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || ref.read(studentsProvider).isLoading) return;
      ref.invalidate(studentsProvider);
      ref.invalidate(currentTripProvider);
      ref.invalidate(attendanceProvider);
      ref.invalidate(notificationsProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(studentsProvider);
      _startStatusRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(parentProvider);
    final students = ref.watch(studentsProvider);
    final selected = ref.watch(selectedStudentProvider);
    final unread = ref.watch(unreadCountProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentProvider);
          ref.invalidate(studentsProvider);
          ref.invalidate(notificationsProvider);
          await Future.wait([
            ref.read(parentProvider.future),
            ref.read(studentsProvider.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 142,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parent.value == null
                                  ? 'Hello'
                                  : 'Hello, ${parent.value!.name.split(' ').first}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(DateTime.now()),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      if (AppConfig.demoMode) const DemoBanner(),
                    ],
                  ),
                ),
              ),
              actions: [
                Badge(
                  label: Text('$unread'),
                  isLabelVisible: unread > 0,
                  child: IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  const SectionTitle('Your children'),
                  const SizedBox(height: 12),
                  students.when(
                    data: (items) => items.isEmpty
                        ? const EmptyState(
                            icon: Icons.family_restroom,
                            title: 'No linked students',
                            message: 'Linked students will appear after school authorization.',
                          )
                        : SizedBox(
                            height: 126,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, index) => _StudentCard(
                                student: items[index],
                                selected: items[index].id == selected?.id,
                                onTap: () => ref
                                    .read(selectedStudentIdProvider.notifier)
                                    .select(items[index].id),
                              ),
                            ),
                          ),
                    loading: () => const SizedBox(
                      height: 126,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => ErrorState(
                      onRetry: () => ref.invalidate(studentsProvider),
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 24),
                    const SectionTitle('Today’s transport'),
                    const SizedBox(height: 12),
                    _StatusCard(student: selected),
                    const SizedBox(height: 24),
                    const SectionTitle('Vehicle information'),
                    const SizedBox(height: 12),
                    _VehicleCard(student: selected),
                    const SizedBox(height: 24),
                    const SectionTitle('Quick actions'),
                    const SizedBox(height: 12),
                    _QuickActions(studentId: selected.id),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.selected,
    required this.onTap,
  });
  final Student student;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.navy
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.navy
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: selected
                ? Colors.white12
                : Theme.of(context).colorScheme.secondaryContainer,
            child: Text(
              student.name.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: selected ? Colors.white : AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${student.grade} • ${student.schoolName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.student});
  final Student student;
  @override
  Widget build(BuildContext context) {
    final pending = student.status == TransportStatus.verificationPending;
    final color = pending
        ? AppColors.warning
        : student.status == TransportStatus.absent
        ? AppColors.error
        : AppColors.success;
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: .14),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pending ? Icons.hourglass_top_rounded : Icons.shield_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.status.label,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (student.statusAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Updated ${formatTime(student.statusAt)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (pending)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Destination safety is not confirmed until verification is completed.',
                        style: TextStyle(
                          color: Color(0xFF8A5A00),
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
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.student});
  final Student student;
  @override
  Widget build(BuildContext context) {
    final v = student.assignedVehicle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.directions_bus_rounded,
              label: 'Vehicle',
              value: v.registrationNumber,
            ),
            _InfoRow(
              icon: Icons.route_rounded,
              label: 'Route',
              value: v.routeName,
            ),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Driver',
              value: v.driverName,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Authorized contact',
              value: v.driverPhone ?? 'Not shared',
            ),
            const _InfoRow(
              icon: Icons.wb_sunny_outlined,
              label: 'Trip',
              value: 'Morning',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.studentId});
  final String studentId;
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.location_on_outlined, 'Track bus', '/tracking'),
      (Icons.event_note_outlined, 'Attendance', '/attendance'),
      (Icons.notifications_none, 'Alerts', '/notifications'),
      (Icons.badge_outlined, 'Student', '/student/$studentId'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.go(actions[i].$3),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(actions[i].$1, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actions[i].$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
