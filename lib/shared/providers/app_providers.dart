import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';
import '../repositories/api_repository.dart';
import '../repositories/app_repository.dart';
import '../repositories/mock_repository.dart';

enum SessionStatus { checking, authenticated, unauthenticated }

enum UserRole { parent, driver, admin }

class SessionState {
  const SessionState(this.status, {this.role, this.error});
  final SessionStatus status;
  final UserRole? role;
  final String? error;
}

final apiClientProvider = Provider((ref) => ApiClient());
final appRepositoryProvider = Provider<AppRepository>(
  (ref) => AppConfig.demoMode
      ? MockAppRepository()
      : ApiAppRepository(ref.watch(apiClientProvider)),
);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    Future<void>.microtask(restore);
    return const SessionState(SessionStatus.checking);
  }

  Future<void> restore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = const SessionState(SessionStatus.unauthenticated);
      return;
    }
    state = SessionState(
      SessionStatus.authenticated,
      role: await _roleFor(user),
    );
  }

  Future<bool> login(String email, String password) async {
    state = const SessionState(SessionStatus.checking);
    try {
      await ref.read(appRepositoryProvider).login(email, password);
      final user = FirebaseAuth.instance.currentUser;
      state = SessionState(
        SessionStatus.authenticated,
        role: user == null ? UserRole.parent : await _roleFor(user),
      );
      return true;
    } catch (error) {
      state = SessionState(
        SessionStatus.unauthenticated,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(appRepositoryProvider).logout();
    } finally {
      state = const SessionState(SessionStatus.unauthenticated);
    }
  }

  void expire() {
    state = const SessionState(
      SessionStatus.unauthenticated,
      error: 'Your session expired. Please sign in again.',
    );
  }

  Future<UserRole> _roleFor(User user) async {
    if (AppConfig.demoMode) return UserRole.parent;
    final token = await user.getIdTokenResult(true);
    return switch (token.claims?['role']?.toString().toUpperCase()) {
      'DRIVER' => UserRole.driver,
      'ADMIN' => UserRole.admin,
      _ => UserRole.parent,
    };
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SelectedStudentController extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String id) => state = id;
}

final selectedStudentIdProvider =
    NotifierProvider<SelectedStudentController, String?>(
      SelectedStudentController.new,
    );

final parentProvider = FutureProvider(
  (ref) => ref.watch(appRepositoryProvider).getParent(),
);
final studentsProvider = FutureProvider((ref) async {
  final students = await ref.watch(appRepositoryProvider).getStudents();
  if (students.isNotEmpty && ref.read(selectedStudentIdProvider) == null)
    Future<void>.microtask(
      () => ref
          .read(selectedStudentIdProvider.notifier)
          .select(students.first.id),
    );
  return students;
});
final selectedStudentProvider = Provider<Student?>((ref) {
  final id = ref.watch(selectedStudentIdProvider);
  return ref
      .watch(studentsProvider)
      .value
      ?.where((s) => s.id == id)
      .firstOrNull;
});
final attendanceProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final id = ref.watch(selectedStudentIdProvider);
  return id == null
      ? <AttendanceRecord>[]
      : await ref.watch(appRepositoryProvider).getAttendance(id);
});
final currentTripProvider = FutureProvider<Trip?>((ref) async {
  final id = ref.watch(selectedStudentIdProvider);
  return id == null
      ? null
      : await ref.watch(appRepositoryProvider).getCurrentTrip(id);
});
final locationProvider = FutureProvider<VehicleLocation?>((ref) async {
  final id = ref.watch(selectedStudentIdProvider);
  return id == null
      ? null
      : await ref.watch(appRepositoryProvider).getVehicleLocation(id);
});

class NotificationsController extends AsyncNotifier<List<ParentNotification>> {
  @override
  Future<List<ParentNotification>> build() =>
      ref.watch(appRepositoryProvider).getNotifications();
  Future<void> markRead(String id) async {
    final current = state.value ?? const [];
    state = AsyncData([
      for (final item in current)
        item.id == id ? item.copyWith(isRead: true) : item,
    ]);
    await ref.read(appRepositoryProvider).markNotificationRead(id);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<ParentNotification>>(
      NotificationsController.new,
    );
final unreadCountProvider = Provider(
  (ref) =>
      ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ??
      0,
);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> toggle(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
