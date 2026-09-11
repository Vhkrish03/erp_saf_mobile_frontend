class DriverModel {
  final int id;
  final String employeeId;
  final String name;
  final String phone;
  final String licenseNumber;
  final String licenseExpiry;
  final String status;

  DriverModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeId: json['employeeId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      licenseExpiry: json['licenseExpiry']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'employeeId': employeeId,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      'status': status,
    };
    if (id != 0) {
      data['id'] = id;
    }
    return data;
  }
}
