import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/attendance/presentation/attendance_screen.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/driver/presentation/driver_dashboard_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/students/presentation/student_details_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import '../core/notifications/notification_service.dart';
import '../shared/providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.status == SessionStatus.checking)
        return state.matchedLocation == '/splash' ? null : '/splash';
      if (session.status == SessionStatus.unauthenticated)
        return state.matchedLocation == '/login' ? null : '/login';
      if (session.role == UserRole.driver) {
        return state.matchedLocation == '/driver' ? null : '/driver';
      }
      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/driver')
        return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/driver',
        builder: (_, __) => const DriverDashboardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tracking',
                builder: (_, __) => const TrackingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                builder: (_, __) => const AttendanceScreen(),
                routes: [
                  GoRoute(
                    path: ':recordId',
                    builder: (_, state) => TripDetailsScreen(
                      recordId: state.pathParameters['recordId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (_, __) => const NotificationsScreen(),
                routes: [
                  GoRoute(
                    path: ':notificationId',
                    builder: (_, state) => NotificationDetailsScreen(
                      notificationId: state.pathParameters['notificationId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (_, __) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/student/:studentId',
        builder: (_, state) =>
            StudentDetailsScreen(studentId: state.pathParameters['studentId']!),
      ),
    ],
  );
  void handleNotificationTap() {
    final route = NotificationService.instance.tappedPayload.value;
    if (route == null || route.isEmpty) return;
    NotificationService.instance.tappedPayload.value = null;
    router.go(route.startsWith('/') ? route : '/notifications');
  }

  NotificationService.instance.tappedPayload.addListener(handleNotificationTap);
  ref.onDispose(() {
    NotificationService.instance.tappedPayload.removeListener(
      handleNotificationTap,
    );
    refresh.dispose();
    router.dispose();
  });
  return router;
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: 'Tracking',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Attendance',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none),
          selectedIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
