/// A generic labeled value, used for simple bar/line chart series
/// (e.g. average attendance trend, pass percentage trend).
class ReportDataPoint {
  final String label;
  final double value;

  const ReportDataPoint({required this.label, required this.value});

  factory ReportDataPoint.fromJson(Map<String, dynamic> json) {
    return ReportDataPoint(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

/// Subject-wise performance summary.
class SubjectPerformance {
  final String subject;
  final double averageScore;
  final double passPercentage;

  const SubjectPerformance({
    required this.subject,
    required this.averageScore,
    required this.passPercentage,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subject: json['subject'] as String? ?? '',
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      passPercentage: (json['passPercentage'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'averageScore': averageScore,
        'passPercentage': passPercentage,
      };
}

/// Departmental analytics summary.
class DepartmentAnalytics {
  final String department;
  final double averageAttendance;
  final double passPercentage;
  final int totalStudents;

  const DepartmentAnalytics({
    required this.department,
    required this.averageAttendance,
    required this.passPercentage,
    required this.totalStudents,
  });

  factory DepartmentAnalytics.fromJson(Map<String, dynamic> json) {
    return DepartmentAnalytics(
      department: json['department'] as String? ?? '',
      averageAttendance: (json['averageAttendance'] as num?)?.toDouble() ?? 0,
      passPercentage: (json['passPercentage'] as num?)?.toDouble() ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'department': department,
        'averageAttendance': averageAttendance,
        'passPercentage': passPercentage,
        'totalStudents': totalStudents,
      };
}

/// A top-performing student entry for the Reports screen leaderboard.
class TopPerformer {
  final String name;
  final String rollNumber;
  final double cgpa;

  const TopPerformer({required this.name, required this.rollNumber, required this.cgpa});

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'rollNumber': rollNumber, 'cgpa': cgpa};
}
