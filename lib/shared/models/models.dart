enum TransportStatus {
  waitingForPickup,
  boarded,
  onTheWay,
  arrivedAtSchool,
  waitingForAfternoonPickup,
  droppedOff,
  absent,
  verificationPending;

  String get label => switch (this) {
    waitingForPickup => 'Waiting for pickup',
    boarded => 'Boarded',
    onTheWay => 'On the way to school',
    arrivedAtSchool => 'Arrived at school',
    waitingForAfternoonPickup => 'Waiting for afternoon pickup',
    droppedOff => 'Dropped off',
    absent => 'Absent',
    verificationPending => 'Verification pending',
  };
}

enum TripType { morning, afternoon }

enum AttendanceStatus {
  pending,
  boarded,
  exitScanned,
  awaitingDriverConfirmation,
  dropoffConfirmed,
  verificationException,
  absent;

  String get label => switch (this) {
    pending => 'Pending',
    boarded => 'Boarded',
    exitScanned => 'Exit scanned',
    awaitingDriverConfirmation => 'Awaiting driver confirmation',
    dropoffConfirmed => 'Drop-off confirmed',
    verificationException => 'Verification exception',
    absent => 'Absent',
  };
}

enum NotificationType {
  boarding,
  wrongVehicle,
  schoolArrival,
  homeDropoff,
  attendanceException,
  tripUpdate,
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

TransportStatus _transportStatus(dynamic value) {
  final status = value?.toString().toUpperCase();
  return switch (status) {
    'NOT_BOARDED' || 'WAITINGFORPICKUP' => TransportStatus.waitingForPickup,
    'BOARDED' => TransportStatus.boarded,
    'ON_BUS' || 'ONTHEWAY' || 'ACTIVE' => TransportStatus.onTheWay,
    'EXITED' || 'ARRIVEDATSCHOOL' => TransportStatus.arrivedAtSchool,
    'DROPPED_OFF' || 'DROPPEDOFF' || 'COMPLETED' => TransportStatus.droppedOff,
    'ABSENT' => TransportStatus.absent,
    _ => TransportStatus.verificationPending,
  };
}

TripType _tripType(dynamic value) {
  final type = value?.toString().toUpperCase();
  return type == 'DROPOFF' || type == 'AFTERNOON'
      ? TripType.afternoon
      : TripType.morning;
}

class Parent {
  const Parent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  factory Parent.fromJson(Map<String, dynamic> json) => Parent(
    id: '${json['id']}',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
  );
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.driverName,
    this.driverPhone,
    required this.routeName,
  });
  final String id;
  final String registrationNumber;
  final String driverName;
  final String? driverPhone;
  final String routeName;
  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: '${json['id']}',
    registrationNumber:
        json['registrationNumber'] ?? json['registration_number'] ?? '',
    driverName: json['driverName'] ?? json['driver_name'] ?? 'Assigned driver',
    driverPhone: json['driverPhone'] ?? json['driver_phone'],
    routeName: json['busNumber'] ?? json['route_name'] ?? '',
  );
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.grade,
    this.avatarUrl,
    required this.assignedVehicle,
    required this.status,
    this.statusAt,
    required this.morningRoute,
    required this.afternoonRoute,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.relationship,
  });
  final String id;
  final String name;
  final String schoolName;
  final String grade;
  final String? avatarUrl;
  final Vehicle assignedVehicle;
  final TransportStatus status;
  final DateTime? statusAt;
  final String morningRoute;
  final String afternoonRoute;
  final String pickupLocation;
  final String dropoffLocation;
  final String relationship;
  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: '${json['id']}',
    name: json['name'] ?? '',
    schoolName: json['schoolName'] ?? json['school_name'] ?? '',
    grade: json['grade'] ?? '',
    avatarUrl: json['avatar_url'],
    assignedVehicle: Vehicle.fromJson(
      Map<String, dynamic>.from(
        json['assignedVehicle'] ?? json['assigned_vehicle'] ?? const {},
      ),
    ),
    status: _transportStatus(json['tripStatus'] ?? json['status']),
    statusAt: _date(json['statusAt'] ?? json['status_at']),
    morningRoute: json['morningRoute'] ?? json['morning_route'] ?? '',
    afternoonRoute: json['afternoonRoute'] ?? json['afternoon_route'] ?? '',
    pickupLocation: json['pickupLocation'] ?? json['pickup_location'] ?? '',
    dropoffLocation: json['dropoffLocation'] ?? json['dropoff_location'] ?? '',
    relationship: json['relationship'] ?? '',
  );
}

class Trip {
  const Trip({
    required this.id,
    required this.vehicleId,
    required this.tripType,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.estimatedArrival,
  });
  final String id;
  final String vehicleId;
  final TripType tripType;
  final TransportStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? estimatedArrival;
  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: '${json['id']}',
    vehicleId: '${json['busId'] ?? json['vehicle_id'] ?? ''}',
    tripType: _tripType(json['tripType'] ?? json['trip_type']),
    status: _transportStatus(json['status']),
    startedAt: _date(json['startedAt'] ?? json['started_at']),
    completedAt: _date(json['completedAt'] ?? json['completed_at']),
    estimatedArrival: _date(
      json['estimatedArrival'] ?? json['estimated_arrival'],
    ),
  );
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.tripId,
    required this.date,
    required this.tripType,
    this.boardingTime,
    required this.boardingStatus,
    this.exitScanTime,
    this.driverConfirmationTime,
    required this.destinationVerificationStatus,
    this.dropoffTime,
    required this.vehicle,
    this.warning,
  });
  final String id;
  final String studentId;
  final String tripId;
  final DateTime date;
  final TripType tripType;
  final DateTime? boardingTime;
  final AttendanceStatus boardingStatus;
  final DateTime? exitScanTime;
  final DateTime? driverConfirmationTime;
  final AttendanceStatus destinationVerificationStatus;
  final DateTime? dropoffTime;
  final String vehicle;
  final String? warning;
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: '${json['id']}',
        studentId: '${json['studentId'] ?? json['student_id'] ?? ''}',
        tripId: '${json['tripId'] ?? json['trip_id'] ?? ''}',
        date: _date(json['scannedAt'] ?? json['date']) ?? DateTime.now(),
        tripType: _tripType(json['tripType'] ?? json['trip_type']),
        boardingTime: json['eventType'] == 'BOARDED'
            ? _date(json['scannedAt'])
            : _date(json['boarding_time']),
        boardingStatus:
            json['eventType'] == 'BOARDED' || json['eventType'] == 'EXITED'
            ? AttendanceStatus.boarded
            : AttendanceStatus.values.firstWhere(
                (e) => e.name == json['boarding_status'],
                orElse: () => AttendanceStatus.pending,
              ),
        exitScanTime: json['eventType'] == 'EXITED'
            ? _date(json['scannedAt'])
            : _date(json['exit_scan_time']),
        driverConfirmationTime: _date(
          json['driverConfirmationTime'] ?? json['driver_confirmation_time'],
        ),
        destinationVerificationStatus: json['eventType'] == 'EXITED'
            ? AttendanceStatus.exitScanned
            : AttendanceStatus.values.firstWhere(
                (e) => e.name == json['destination_verification_status'],
                orElse: () => AttendanceStatus.pending,
              ),
        dropoffTime: _date(json['dropoffTime'] ?? json['dropoff_time']),
        vehicle: json['busId'] ?? json['vehicle'] ?? '',
        warning: json['warning'],
      );
}

class VehicleLocation {
  const VehicleLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    this.estimatedArrival,
    this.isDemo = false,
  });
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime recordedAt;
  final DateTime? estimatedArrival;
  final bool isDemo;
  bool isStale([DateTime? now]) =>
      (now ?? DateTime.now()).difference(recordedAt) >
      const Duration(minutes: 3);
  factory VehicleLocation.fromJson(Map<String, dynamic> json) =>
      VehicleLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        recordedAt:
            _date(json['recordedAt'] ?? json['recorded_at']) ?? DateTime.now(),
        estimatedArrival: _date(
          json['estimatedArrival'] ?? json['estimated_arrival'],
        ),
      );
}

class ParentNotification {
  const ParentNotification({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });
  final String id;
  final String studentId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  ParentNotification copyWith({bool? isRead}) => ParentNotification(
    id: id,
    studentId: studentId,
    type: type,
    title: title,
    message: message,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
  factory ParentNotification.fromJson(Map<String, dynamic> json) =>
      ParentNotification(
        id: '${json['id']}',
        studentId: '${json['studentId'] ?? json['student_id'] ?? ''}',
        type: NotificationType.values.firstWhere(
          (e) =>
              e.name.toUpperCase() ==
              json['type']?.toString().replaceAll('STUDENT_', '').toUpperCase(),
          orElse: () => NotificationType.tripUpdate,
        ),
        title: json['title'] ?? '',
        message: json['body'] ?? json['message'] ?? '',
        createdAt:
            _date(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
        isRead: json['read'] == true || json['is_read'] == true,
      );
}
