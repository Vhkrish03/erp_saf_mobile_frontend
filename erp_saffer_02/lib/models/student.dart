class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String department;
  final String section;
  final String year;
  final String semester;
  final String email;
  final String phone;
  final String bloodGroup;
  final String dob;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String address;
  final String advisor;
  final double cgpa;
  final String residencyType;

  const Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.section,
    required this.year,
    required this.semester,
    required this.email,
    required this.phone,
    required this.bloodGroup,
    required this.dob,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.address,
    required this.advisor,
    required this.cgpa,
    this.residencyType = 'DAY_SCHOLAR',
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rollNumber: json['rollNumber']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bloodGroup: json['bloodGroup']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      emergencyContactName: json['emergencyContactName']?.toString() ?? '',
      emergencyContactPhone: json['emergencyContactPhone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      advisor: json['advisor']?.toString() ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      residencyType: json['residencyType']?.toString() ?? 'DAY_SCHOLAR',
    );
  }
}
