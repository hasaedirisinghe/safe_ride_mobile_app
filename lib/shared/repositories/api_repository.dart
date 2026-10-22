import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../models/models.dart';
import 'app_repository.dart';

class ApiAppRepository implements AppRepository {
  ApiAppRepository(this._client);
  final ApiClient _client;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  List<dynamic> _items(dynamic data) => data is Map && data['data'] is List
      ? data['data']
      : data is List
      ? data
      : const [];
  Map<String, dynamic> _object(dynamic data) => Map<String, dynamic>.from(
    data is Map && data['data'] is Map ? data['data'] : data as Map,
  );

  @override
  Future<String> login(String email, String password) => _guard(() async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await credential.user?.getIdToken();
    if (token == null || token.isEmpty)
      throw const FormatException('Missing authentication token');
    return token;
  });
  @override
  Future<void> logout() => _guard(FirebaseAuth.instance.signOut);
  @override
  Future<Parent> getParent() => _guard(
    () async =>
        Parent.fromJson(_object((await _client.dio.get('parents/me')).data)),
  );
  @override
  Future<List<Student>> getStudents() => _guard(() async {
    final items = _items((await _client.dio.get('parents/me/students')).data);
    return Future.wait(
      items.map((item) => _student(Map<String, dynamic>.from(item))),
    );
  });
  @override
  Future<Student> getStudent(String id) => _guard(
    () async => _student(_object((await _client.dio.get('students/$id')).data)),
  );
  @override
  Future<Trip?> getCurrentTrip(String studentId) => _guard(() async {
    final data = (await _client.dio.get('students/$studentId/current-trip'))
        .data;
    final value = data is Map ? data['data'] : null;
    return value == null
        ? null
        : Trip.fromJson(Map<String, dynamic>.from(value));
  });
  @override
  Future<List<AttendanceRecord>> getAttendance(String studentId) => _guard(
    () async =>
        _items((await _client.dio.get('students/$studentId/attendance')).data)
            .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
  );
  @override
  Future<VehicleLocation?> getVehicleLocation(String studentId) =>
      _guard(() async {
        try {
          final student = _object(
            (await _client.dio.get('students/$studentId')).data,
          );
          final busId = student['assignedBusId']?.toString();
          if (busId == null || busId.isEmpty) return null;
          final data = (await _client.dio.get('buses/$busId/location')).data;
          final value = data is Map ? data['data'] : null;
          return value == null
              ? null
              : VehicleLocation.fromJson(Map<String, dynamic>.from(value));
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      });
  @override
  Future<List<ParentNotification>> getNotifications() => _guard(
    () async => _items((await _client.dio.get('parents/me/notifications')).data)
        .map((e) => ParentNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
  @override
  Future<void> markNotificationRead(String id) => _guard(() async {
    await _client.dio.patch('parents/me/notifications/$id/read');
  });
  @override
  Future<void> registerDeviceToken(String token) => _guard(() async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    await _client.dio.post(
      'notifications/tokens',
      data: {'token': token, 'platform': platform},
    );
  });

  Future<Student> _student(Map<String, dynamic> data) async {
    final id = data['id']?.toString() ?? '';
    final statusResponse = await _client.dio.get('students/$id/current-status');
    final status = _object(statusResponse.data);
    data['tripStatus'] = status['status'];
    data['statusAt'] = status['lastUpdatedAt'];

    final busId = data['assignedBusId']?.toString();
    if (busId != null && busId.isNotEmpty) {
      final bus = _object((await _client.dio.get('buses/$busId')).data);
      data['assignedVehicle'] = bus;
    }
    return Student.fromJson(data);
  }
}
