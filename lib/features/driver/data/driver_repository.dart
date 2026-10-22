import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/providers/app_providers.dart';
import 'driver_models.dart';

class DriverRepository {
  const DriverRepository(this._client);

  final ApiClient _client;

  Future<DriverDashboardData> getDashboard() async {
    try {
      final driverResponse = await _client.dio.get('drivers/me');
      final busResponse = await _client.dio.get('drivers/me/bus');
      final studentsResponse = await _client.dio.get('drivers/me/students');
      final driver = DriverProfile.fromJson(_mapData(driverResponse.data)!);
      final busJson = _mapData(busResponse.data);
      final bus = busJson == null ? null : DriverBus.fromJson(busJson);
      DriverTrip? trip;
      if (bus != null) {
        final tripResponse = await _client.dio.get(
          'buses/${bus.id}/active-trip',
        );
        final tripJson = _mapData(tripResponse.data);
        if (tripJson != null) trip = DriverTrip.fromJson(tripJson);
      }
      final students = _listData(studentsResponse.data)
          .map(DriverStudent.fromJson)
          .toList();
      return DriverDashboardData(
        driver: driver,
        bus: bus,
        trip: trip,
        students: students,
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> startTrip(String busId, String tripType) async {
    try {
      await _client.dio.post(
        'trips/start',
        data: {'busId': busId, 'tripType': tripType},
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> confirmDropoff(String tripId, String studentId) async {
    try {
      await _client.dio.post(
        'trips/$tripId/confirm-dropoff',
        data: {'studentId': studentId},
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> completeTrip(String tripId) async {
    try {
      await _client.dio.post('trips/$tripId/complete');
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> setScannerMode(String scanMode) async {
    try {
      await _client.dio.patch(
        'drivers/me/scanner-mode',
        data: {'scanMode': scanMode},
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Map<String, dynamic>? _mapData(dynamic response) {
    if (response is! Map) return null;
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  List<Map<String, dynamic>> _listData(dynamic response) {
    if (response is! Map || response['data'] is! List) return const [];
    return (response['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

final driverRepositoryProvider = Provider(
  (ref) => DriverRepository(ref.watch(apiClientProvider)),
);

final driverDashboardProvider = FutureProvider(
  (ref) => ref.watch(driverRepositoryProvider).getDashboard(),
);
