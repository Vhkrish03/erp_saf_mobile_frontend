/// Represents a teacher-created assignment.
class Assignment {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String section;
  final String department;
  final String year;
  final String? attachmentFileName;
  final String createdBy;
  final int submissionCount;
  final int totalStudents;
  final bool isPublished;

  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.section,
    required this.department,
    required this.year,
    this.attachmentFileName,
    required this.createdBy,
    this.submissionCount = 0,
    this.totalStudents = 0,
    this.isPublished = false,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
        id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      section: json['section'] as String? ?? '',
      department: json["department"] ?? "",
      year: json["year"] ?? "",
      attachmentFileName: json['attachmentFile'] as String?,
      createdBy: json["createdBy"] ?? "",
      submissionCount: json['submissionCount'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'section': section,
      'department': department,
      'year': year,
      'attachmentFile': attachmentFileName,
      "createdBy": createdBy,
      'submissionCount': submissionCount,
      'totalStudents': totalStudents,
      'isPublished': isPublished,
    };
  }
}

/// A single student submission for an assignment (used on the review screen).
class AssignmentSubmission {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final DateTime submittedAt;
  final bool isReviewed;
  final double? marksAwarded;

  const AssignmentSubmission({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.submittedAt,
    this.isReviewed = false,
    this.marksAwarded,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
      isReviewed: json['isReviewed'] as bool? ?? false,
      marksAwarded: (json['marksAwarded'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'submittedAt': submittedAt.toIso8601String(),
      'isReviewed': isReviewed,
      'marksAwarded': marksAwarded,
    };
  }
}
