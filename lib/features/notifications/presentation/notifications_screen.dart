import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/app_providers.dart';

IconData _icon(NotificationType type) => switch (type) {
  NotificationType.boarding => Icons.directions_bus_rounded,
  NotificationType.wrongVehicle => Icons.gpp_bad_rounded,
  NotificationType.schoolArrival => Icons.school_rounded,
  NotificationType.homeDropoff => Icons.home_rounded,
  NotificationType.attendanceException => Icons.warning_amber_rounded,
  NotificationType.tripUpdate => Icons.route_rounded,
};
Color _color(NotificationType type) => switch (type) {
  NotificationType.wrongVehicle ||
  NotificationType.attendanceException => AppColors.error,
  NotificationType.schoolArrival ||
  NotificationType.homeDropoff => AppColors.success,
  _ => AppColors.blue,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (AppConfig.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: DemoBanner()),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            ErrorState(onRetry: () => ref.invalidate(notificationsProvider)),
        data: (items) {
          if (items.isEmpty)
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'You’re all caught up',
              message: 'Transport and safety updates will appear here.',
            );
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = items[index];
                final color = _color(item.type);
                return Card(
                  color: item.isRead ? null : color.withValues(alpha: .055),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      ref
                          .read(notificationsProvider.notifier)
                          .markRead(item.id);
                      context.go('/notifications/${item.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: .12),
                            child: Icon(
                              _icon(item.type),
                              color: color,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  relativeTime(item.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationDetailsScreen extends ConsumerWidget {
  const NotificationDetailsScreen({super.key, required this.notificationId});
  final String notificationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(notificationsProvider).value ?? const <ParentNotification>[];
    final matches = items.where((n) => n.id == notificationId);
    if (matches.isEmpty)
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.notifications_off,
          title: 'Notification unavailable',
          message: 'This notification could not be found.',
        ),
      );
    final item = matches.first;
    final color = _color(item.type);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification details')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(_icon(item.type), color: color, size: 34),
          ),
          const SizedBox(height: 22),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            formatDate(item.createdAt),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                item.message,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This alert was generated from authorized backend transport data. Contact your school if any detail appears incorrect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
