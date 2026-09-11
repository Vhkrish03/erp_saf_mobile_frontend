class TeacherIdCardModel {
  final String name;
  final String idOrRollNumber; // Employee ID
  final String department;
  final String designation;
  final String validity;
  final String dayscholarStatus; // e.g. "STAFF"
  final String barcodeData;
  final String bloodGroup;
  final String dob;
  final String emergencyContact;
  final String address;
  final String photoUrl;
  final String status;

  TeacherIdCardModel({
    required this.name,
    required this.idOrRollNumber,
    required this.department,
    required this.designation,
    required this.validity,
    required this.dayscholarStatus,
    required this.barcodeData,
    required this.bloodGroup,
    required this.dob,
    required this.emergencyContact,
    required this.address,
    required this.photoUrl,
    required this.status,
  });

  factory TeacherIdCardModel.fromJson(Map<String, dynamic> json) {
    return TeacherIdCardModel(
      name: json['name']?.toString() ?? '',
      idOrRollNumber: json['idOrRollNumber']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Faculty',
      validity: json['validity']?.toString() ?? 'LIFETIME',
      dayscholarStatus: json['dayscholarStatus']?.toString() ?? 'STAFF',
      barcodeData: json['barcodeData']?.toString() ?? '',
      bloodGroup: json['bloodGroup']?.toString() ?? 'A+VE',
      dob: json['dob']?.toString() ?? '',
      emergencyContact: json['emergencyContact']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}
