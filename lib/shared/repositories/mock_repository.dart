import 'dart:math';

import '../models/models.dart';
import 'app_repository.dart';

class MockAppRepository implements AppRepository {
  final _vehicle1 = const Vehicle(
    id: 'bus-03',
    registrationNumber: 'WP NC-3403',
    driverName: 'Sunil Perera',
    driverPhone: '+94 77 245 8890',
    routeName: 'Colombo 05 • School Route',
  );
  final _vehicle2 = const Vehicle(
    id: 'van-07',
    registrationNumber: 'WP PA-1207',
    driverName: 'M. Fairooz',
    driverPhone: '+94 76 804 1120',
    routeName: 'Nugegoda • School Route',
  );
  late final List<Student> _students = [
    Student(
      id: 'stu-1',
      name: 'Nimal Jayasinghe',
      schoolName: 'Royal College, Colombo',
      grade: 'Grade 6',
      assignedVehicle: _vehicle1,
      status: TransportStatus.onTheWay,
      statusAt: DateTime.now().subtract(const Duration(minutes: 12)),
      morningRoute: 'Colombo 05 → Royal College',
      afternoonRoute: 'Royal College → Colombo 05',
      pickupLocation: 'Havelock Road, Colombo 05',
      dropoffLocation: 'Home — Havelock Road',
      relationship: 'Father',
    ),
    Student(
      id: 'stu-2',
      name: 'Anuki Jayasinghe',
      schoolName: 'Visakha Vidyalaya',
      grade: 'Grade 3',
      assignedVehicle: _vehicle2,
      status: TransportStatus.verificationPending,
      statusAt: DateTime.now().subtract(const Duration(minutes: 4)),
      morningRoute: 'Nugegoda → Visakha Vidyalaya',
      afternoonRoute: 'Visakha Vidyalaya → Nugegoda',
      pickupLocation: 'High Level Road, Nugegoda',
      dropoffLocation: 'Grandmother’s residence — Nugegoda',
      relationship: 'Father',
    ),
  ];
  late final List<ParentNotification> _notifications = [
    ParentNotification(
      id: 'n1',
      studentId: 'stu-1',
      type: NotificationType.boarding,
      title: 'Boarding confirmed',
      message: 'Nimal boarded Bus 03 at 7:10 AM.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
      isRead: false,
    ),
    ParentNotification(
      id: 'n2',
      studentId: 'stu-2',
      type: NotificationType.attendanceException,
      title: 'Verification required',
      message: 'Anuki’s transport attendance requires verification.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    ParentNotification(
      id: 'n3',
      studentId: 'stu-1',
      type: NotificationType.schoolArrival,
      title: 'Arrival confirmed',
      message: 'Nimal’s drop-off at school was confirmed yesterday.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    ParentNotification(
      id: 'n4',
      studentId: 'stu-2',
      type: NotificationType.wrongVehicle,
      title: 'Wrong vehicle attempt',
      message:
          'An unrecognized vehicle boarding attempt was detected for Anuki.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];
  int _locationStep = 0;

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return value;
  }

  @override
  Future<String> login(String email, String password) async {
    if (!email.contains('@') || password.length < 6)
      throw Exception('Invalid email or password.');
    return _delay('demo-session-token');
  }

  @override
  Future<void> logout() => _delay(null);
  @override
  Future<Parent> getParent() => _delay(
    const Parent(
      id: 'parent-1',
      name: 'Kasun Jayasinghe',
      email: 'kasun@example.com',
      phone: '+94 71 234 5678',
    ),
  );
  @override
  Future<List<Student>> getStudents() => _delay(List.unmodifiable(_students));
  @override
  Future<Student> getStudent(String id) =>
      _delay(_students.firstWhere((student) => student.id == id));
  @override
  Future<Trip?> getCurrentTrip(String studentId) => _delay(
    Trip(
      id: 'trip-today',
      vehicleId: _students
          .firstWhere((s) => s.id == studentId)
          .assignedVehicle
          .id,
      tripType: TripType.morning,
      status: TransportStatus.onTheWay,
      startedAt: DateTime.now().subtract(const Duration(minutes: 42)),
      estimatedArrival: DateTime.now().add(const Duration(minutes: 14)),
    ),
  );
  @override
  Future<List<AttendanceRecord>> getAttendance(String studentId) {
    final now = DateTime.now();
    return _delay(
      List.generate(7, (i) {
        final date = now.subtract(Duration(days: i));
        final exception = i == 2;
        final absent = i == 4;
        return AttendanceRecord(
          id: 'att-$studentId-$i',
          studentId: studentId,
          tripId: 'trip-$i',
          date: date,
          tripType: i.isEven ? TripType.morning : TripType.afternoon,
          boardingTime: absent
              ? null
              : DateTime(
                  date.year,
                  date.month,
                  date.day,
                  i.isEven ? 7 : 13,
                  10,
                ),
          boardingStatus: absent
              ? AttendanceStatus.absent
              : AttendanceStatus.boarded,
          exitScanTime: absent
              ? null
              : DateTime(
                  date.year,
                  date.month,
                  date.day,
                  i.isEven ? 7 : 14,
                  50,
                ),
          driverConfirmationTime: exception || absent
              ? null
              : DateTime(date.year, date.month, date.day, i.isEven ? 8 : 15, 2),
          destinationVerificationStatus: absent
              ? AttendanceStatus.absent
              : exception
              ? AttendanceStatus.verificationException
              : AttendanceStatus.dropoffConfirmed,
          dropoffTime: exception || absent
              ? null
              : DateTime(date.year, date.month, date.day, i.isEven ? 8 : 15, 2),
          vehicle: _students
              .firstWhere((s) => s.id == studentId)
              .assignedVehicle
              .registrationNumber,
          warning: exception
              ? 'Destination confirmation was not received.'
              : null,
        );
      }),
    );
  }

  @override
  Future<VehicleLocation?> getVehicleLocation(String studentId) async {
    _locationStep++;
    final jitter = sin(_locationStep / 3) * .0003;
    return _delay(
      VehicleLocation(
        latitude: 6.9147 + (_locationStep * .00025),
        longitude: 79.8588 + jitter,
        accuracy: 8,
        recordedAt: DateTime.now(),
        estimatedArrival: DateTime.now().add(const Duration(minutes: 14)),
        isDemo: true,
      ),
    );
  }

  @override
  Future<List<ParentNotification>> getNotifications() =>
      _delay(List.unmodifiable(_notifications));
  @override
  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0)
      _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> registerDeviceToken(String token) => _delay(null);
}
