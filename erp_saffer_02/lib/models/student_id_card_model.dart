class StudentIdCardModel {
  final String name;
  final String idOrRollNumber;
  final String department;
  final String section;
  final String year;
  final String semester;
  final String designation;
  final String validity;
  final String dayscholarStatus;
  final String barcodeData;
  final String bloodGroup;
  final String dob;
  final String emergencyContact;
  final String address;
  final String photoUrl;
  final String status;

  StudentIdCardModel({
    required this.name,
    required this.idOrRollNumber,
    required this.department,
    required this.section,
    required this.year,
    required this.semester,
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

  factory StudentIdCardModel.fromJson(Map<String, dynamic> json) {
    return StudentIdCardModel(
      name: json['name']?.toString() ?? '',
      idOrRollNumber: json['idOrRollNumber']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'STUDENT',
      validity: json['validity']?.toString() ?? '',
      dayscholarStatus: json['dayscholarStatus']?.toString() ?? 'DAYSCHOLAR',
      barcodeData: json['barcodeData']?.toString() ?? '',
      bloodGroup: json['bloodGroup']?.toString() ?? 'AB+VE',
      dob: json['dob']?.toString() ?? '',
      emergencyContact: json['emergencyContact']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}
