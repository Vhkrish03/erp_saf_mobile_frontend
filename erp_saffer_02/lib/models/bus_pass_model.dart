class BusPassModel {
  final String name;
  final String personId;
  final String personType;
  final String rollNumber;
  final String department;
  final String year;
  final String section;
  final String designation; // For staff
  final String passNumber;
  final String route;
  final String pickupPoint;
  final String dropPoint;
  final String pickupTime;
  final String validFrom;
  final String validUntil;
  final String address;
  final String academicYear;
  final String status; // "VALID" or "EXPIRED"
  final String photoUrl;

  BusPassModel({
    required this.name,
    required this.personId,
    required this.personType,
    required this.rollNumber,
    required this.department,
    required this.year,
    required this.section,
    required this.designation,
    required this.passNumber,
    required this.route,
    required this.pickupPoint,
    required this.dropPoint,
    required this.pickupTime,
    required this.validFrom,
    required this.validUntil,
    required this.address,
    required this.academicYear,
    required this.status,
    required this.photoUrl,
  });

  factory BusPassModel.fromJson(Map<String, dynamic> json) {
    return BusPassModel(
      name: json['name']?.toString() ?? '',
      personId: json['personId']?.toString() ?? '',
      personType: json['personType']?.toString() ?? '',
      rollNumber: json['rollNumber']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      passNumber: json['passNumber']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      pickupPoint: json['pickupPoint']?.toString() ?? '',
      dropPoint: json['dropPoint']?.toString() ?? '',
      pickupTime: json['pickupTime']?.toString() ?? '',
      validFrom: json['validFrom']?.toString() ?? '',
      validUntil: json['validUntil']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      academicYear: json['academicYear']?.toString() ?? '',
      status: json['status']?.toString() ?? 'VALID',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }
}
