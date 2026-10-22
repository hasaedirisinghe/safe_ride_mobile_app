class DriverProfile {
  const DriverProfile({required this.id, required this.name});

  final String id;
  final String name;

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Driver',
  );
}

class DriverBus {
  const DriverBus({
    required this.id,
    required this.registrationNumber,
    required this.busNumber,
    required this.scanMode,
  });

  final String id;
  final String registrationNumber;
  final String busNumber;
  final String? scanMode;

  factory DriverBus.fromJson(Map<String, dynamic> json) => DriverBus(
    id: json['id']?.toString() ?? '',
    registrationNumber: json['registrationNumber']?.toString() ?? 'Unknown',
    busNumber: json['busNumber']?.toString() ?? '—',
    scanMode: json['scanMode']?.toString(),
  );
}

class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.tripType,
    required this.status,
  });

  final String id;
  final String tripType;
  final String status;

  factory DriverTrip.fromJson(Map<String, dynamic> json) => DriverTrip(
    id: json['id']?.toString() ?? '',
    tripType: json['tripType']?.toString() ?? 'PICKUP',
    status: json['status']?.toString() ?? 'ACTIVE',
  );

  String get typeLabel => tripType == 'DROPOFF' ? 'Drop-off' : 'Pickup';
}

class DriverStudent {
  const DriverStudent({
    required this.id,
    required this.name,
    required this.studentNumber,
    required this.schoolName,
    required this.grade,
    required this.tripStatus,
  });

  final String id;
  final String name;
  final String studentNumber;
  final String schoolName;
  final String grade;
  final String tripStatus;

  factory DriverStudent.fromJson(Map<String, dynamic> json) => DriverStudent(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Student',
    studentNumber: json['studentNumber']?.toString() ?? '',
    schoolName: json['schoolName']?.toString() ?? '',
    grade: json['grade']?.toString() ?? '',
    tripStatus: json['tripStatus']?.toString() ?? 'NOT_BOARDED',
  );

  bool get canConfirmDropoff => tripStatus == 'EXITED';

  String get statusLabel => switch (tripStatus) {
    'ON_BUS' => 'On the bus',
    'EXITED' => 'Exit scanned — confirm drop-off',
    'DROPPED_OFF' => 'Drop-off confirmed',
    _ => 'Waiting to board',
  };
}

class DriverDashboardData {
  const DriverDashboardData({
    required this.driver,
    required this.bus,
    required this.trip,
    required this.students,
  });

  final DriverProfile driver;
  final DriverBus? bus;
  final DriverTrip? trip;
  final List<DriverStudent> students;
}
