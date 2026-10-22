import '../models/models.dart';

abstract interface class AppRepository {
  Future<String> login(String email, String password);
  Future<void> logout();
  Future<Parent> getParent();
  Future<List<Student>> getStudents();
  Future<Student> getStudent(String id);
  Future<Trip?> getCurrentTrip(String studentId);
  Future<List<AttendanceRecord>> getAttendance(String studentId);
  Future<VehicleLocation?> getVehicleLocation(String studentId);
  Future<List<ParentNotification>> getNotifications();
  Future<void> markNotificationRead(String id);
  Future<void> registerDeviceToken(String token);
}
