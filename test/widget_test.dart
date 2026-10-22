import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_ride_lk/core/network/api_client.dart';
import 'package:safe_ride_lk/features/auth/presentation/auth_screens.dart';
import 'package:safe_ride_lk/features/dashboard/presentation/dashboard_screen.dart';
import 'package:safe_ride_lk/shared/models/models.dart';
import 'package:safe_ride_lk/shared/providers/app_providers.dart';

class TestSessionController extends SessionController {
  @override
  SessionState build() => const SessionState(SessionStatus.unauthenticated);
}

void main() {
  testWidgets('login validates malformed credentials', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(TestSessionController.new)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  test('tracking marks locations stale after three minutes', () {
    final now = DateTime(2026, 1, 1, 8);
    final location = VehicleLocation(
      latitude: 6.9,
      longitude: 79.8,
      accuracy: 8,
      recordedAt: now.subtract(const Duration(minutes: 4)),
    );
    expect(location.isStale(now), isTrue);
  });

  test('attendance labels map to parent-facing text', () {
    expect(
      AttendanceStatus.awaitingDriverConfirmation.label,
      'Awaiting driver confirmation',
    );
    expect(AttendanceStatus.dropoffConfirmed.label, 'Drop-off confirmed');
  });

  test('student selection switches the selected student', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final students = await container.read(studentsProvider.future);
    container.read(selectedStudentIdProvider.notifier).select(students.last.id);
    expect(container.read(selectedStudentProvider)?.id, students.last.id);
  });

  test('marking a notification read updates state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final items = await container.read(notificationsProvider.future);
    final unread = items.firstWhere((item) => !item.isRead);
    await container.read(notificationsProvider.notifier).markRead(unread.id);
    expect(
      container
          .read(notificationsProvider)
          .value!
          .firstWhere((item) => item.id == unread.id)
          .isRead,
      isTrue,
    );
  });

  test('network timeout maps to a parent-friendly repository error', () {
    final exception = DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionTimeout,
    );
    expect(ApiClient.mapError(exception).message, contains('timed out'));
  });

  testWidgets('dashboard renders transport sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Your children'), findsOneWidget);
    expect(find.text('Today’s transport'), findsOneWidget);
    expect(find.text('Vehicle information'), findsOneWidget);
  });
}
