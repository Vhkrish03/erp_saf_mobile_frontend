/// Represents a teacher's profile information.
class Teacher {
  final int? id;
  final String employeeId;
  final String name;
  final String? gender;
  final String? dob;
  final String department;
  final String designation;
  final String qualification;
  final String experience;
  final int? experienceYears;
  final String phone;
  final String email;
  final String address;
  final String? joiningDate;
  final String? status;
  final String photoUrl;
  final String? emergencyContactName;
  final String? emergencyContactNumber;

  const Teacher({
    this.id,
    required this.employeeId,
    required this.name,
    this.gender,
    this.dob,
    required this.department,
    required this.designation,
    required this.qualification,
    required this.experience,
    this.experienceYears,
    required this.phone,
    required this.email,
    required this.address,
    this.joiningDate,
    this.status,
    this.photoUrl = '',
    this.emergencyContactName,
    this.emergencyContactNumber,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String?,
      dob: json['dob'] as String?,
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      experience:
          json['experienceYears']?.toString() ??
          json['experience']?.toString() ??
          '',
      experienceYears: json['experienceYears'] as int?,
      photoUrl: json['photoUrl'] ?? json['photo_url'] ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      joiningDate: json['joiningDate'] as String?,
      status: json['status'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactNumber: json['emergencyContactNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'gender': gender,
      'dob': dob,
      'department': department,
      'designation': designation,
      'qualification': qualification,
      'experience': experience,
      'experienceYears': experienceYears,
      'phone': phone,
      'email': email,
      'address': address,
      'joiningDate': joiningDate,
      'status': status,
      'photoUrl': photoUrl,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
    };
  }

  Teacher copyWith({
    int? id,
    String? name,
    String? gender,
    String? dob,
    String? department,
    String? designation,
    String? qualification,
    String? experience,
    int? experienceYears,
    String? phone,
    String? email,
    String? address,
    String? joiningDate,
    String? status,
    String? photoUrl,
    String? emergencyContactName,
    String? emergencyContactNumber,
  }) {
    return Teacher(
      id: id ?? this.id,
      employeeId: employeeId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      experienceYears: experienceYears ?? this.experienceYears,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber:
          emergencyContactNumber ?? this.emergencyContactNumber,
    );
  }
}

/// Aggregated dashboard statistics for a teacher.
class DashboardStats {
  final int todaysClasses;
  final int totalStudents;
  final int pendingAttendance;
  final int assignmentsToReview;
  final double averageClassAttendance;

  const DashboardStats({
    required this.todaysClasses,
    required this.totalStudents,
    required this.pendingAttendance,
    required this.assignmentsToReview,
    required this.averageClassAttendance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todaysClasses: json['todaysClasses'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      pendingAttendance: json['pendingAttendance'] as int? ?? 0,
      assignmentsToReview: json['assignmentsToReview'] as int? ?? 0,
      averageClassAttendance:
          (json['averageClassAttendance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todaysClasses': todaysClasses,
      'totalStudents': totalStudents,
      'pendingAttendance': pendingAttendance,
      'assignmentsToReview': assignmentsToReview,
      'averageClassAttendance': averageClassAttendance,
    };
  }
}
