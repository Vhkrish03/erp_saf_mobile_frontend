/// Lightweight student record used across teacher-facing screens
/// (Students list, Attendance marking, Results entry).
class StudentSummary {
  final String id;
  final String name;
  final String rollNumber;
  final String department;
  final String semester;
  final String section;
  final double attendancePercentage;
  final double cgpa;
  final String photoUrl;
  final String year;

  const StudentSummary({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.semester,
    required this.section,
    required this.attendancePercentage,
    required this.cgpa,
    this.photoUrl = '',
    this.year = '',
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      department: json['department'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      section: json['section'] as String? ?? '',
      attendancePercentage:
          (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photoUrl'] as String? ?? '',
      year: json['year'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'department': department,
      'semester': semester,
      'section': section,
      'attendancePercentage': attendancePercentage,
      'cgpa': cgpa,
      'photoUrl': photoUrl,
      'year': year,
    };
  }
}

/// A single student's attendance mark for a given date/subject session.
class AttendanceRecord {
  final String studentId;
  final bool isPresent;

  const AttendanceRecord({required this.studentId, required this.isPresent});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'] as String? ?? '',
      isPresent: json['isPresent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'studentId': studentId, 'isPresent': isPresent};
  }
}

/// A single student's result entry for a subject (internal/external marks + grade).
class ResultEntry {
  final String studentId;
  final String studentName;
  final String rollNumber;
  double internalMarks;
  double externalMarks;
  String grade;

  ResultEntry({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    this.internalMarks = 0,
    this.externalMarks = 0,
    this.grade = '-',
  });

  factory ResultEntry.fromJson(Map<String, dynamic> json) {
    return ResultEntry(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      internalMarks: (json['internalMarks'] as num?)?.toDouble() ?? 0,
      externalMarks: (json['externalMarks'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'internalMarks': internalMarks,
      'externalMarks': externalMarks,
      'grade': grade,
    };
  }

  /// Simple grade calculator based on total of internal + external (out of 100).
  static String calculateGrade(double internal, double external) {
    final total = internal + external;
    if (total >= 90) return 'O';
    if (total >= 80) return 'A+';
    if (total >= 70) return 'A';
    if (total >= 60) return 'B+';
    if (total >= 50) return 'B';
    if (total >= 40) return 'C';
    return 'RA';
  }
}
