// Model for the new Exam Cell result (separate from internal marks)
class ExamCellResultModel {
  final int? id;
  final String studentId;
  final String? registerNumber;
  final String? studentName;
  final String department;
  final String semesterName;
  final String academicYear;
  final String examSession;
  final String? examination;
  final double sgpa;
  final String status;
  final String? publishedAt;
  final List<ExamCellSubjectModel> subjects;

  ExamCellResultModel({
    this.id,
    required this.studentId,
    this.registerNumber,
    this.studentName,
    required this.department,
    required this.semesterName,
    required this.academicYear,
    required this.examSession,
    this.examination,
    this.sgpa = 0.0,
    this.status = 'DRAFT',
    this.publishedAt,
    this.subjects = const [],
  });

  factory ExamCellResultModel.fromJson(Map<String, dynamic> json) {
    return ExamCellResultModel(
      id: json['id'],
      studentId: json['studentId'] ?? '',
      registerNumber: json['registerNumber'],
      studentName: json['studentName'],
      department: json['department'] ?? '',
      semesterName: json['semesterName'] ?? '',
      academicYear: json['academicYear'] ?? '',
      examSession: json['examSession'] ?? '',
      examination: json['examination'],
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'DRAFT',
      publishedAt: json['publishedAt']?.toString(),
      subjects:
          (json['subjects'] as List<dynamic>? ?? [])
              .map((s) => ExamCellSubjectModel.fromJson(s))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'studentId': studentId,
    if (registerNumber != null) 'registerNumber': registerNumber,
    if (studentName != null) 'studentName': studentName,
    'department': department,
    'semesterName': semesterName,
    'academicYear': academicYear,
    'examSession': examSession,
    if (examination != null) 'examination': examination,
    'sgpa': sgpa,
    'status': status,
    'subjects': subjects.map((s) => s.toJson()).toList(),
  };

  bool get isDraft => status == 'DRAFT';
  bool get isVerified => status == 'VERIFIED';
  bool get isApproved => status == 'APPROVED';
  bool get isPublished => status == 'PUBLISHED';
}

class ExamCellSubjectModel {
  final int? id;
  final String subjectCode;
  final String subjectName;
  final int credits;
  final String? grade;
  final double gradePoint;
  final String? resultStatus;
  final double? marksObtained;
  final double? maxMarks;
  final int? attemptNumber;

  ExamCellSubjectModel({
    this.id,
    required this.subjectCode,
    required this.subjectName,
    this.credits = 3,
    this.grade,
    this.gradePoint = 0.0,
    this.resultStatus,
    this.marksObtained,
    this.maxMarks,
    this.attemptNumber,
  });

  factory ExamCellSubjectModel.fromJson(Map<String, dynamic> json) {
    return ExamCellSubjectModel(
      id: json['id'],
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      credits: json['credits'] ?? 3,
      grade: json['grade'],
      gradePoint: (json['gradePoint'] as num?)?.toDouble() ?? 0.0,
      resultStatus: json['resultStatus'],
      marksObtained: (json['marksObtained'] as num?)?.toDouble(),
      maxMarks: (json['maxMarks'] as num?)?.toDouble(),
      attemptNumber: json['attemptNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'credits': credits,
    if (grade != null) 'grade': grade,
    'gradePoint': gradePoint,
    if (resultStatus != null) 'resultStatus': resultStatus,
    if (marksObtained != null) 'marksObtained': marksObtained,
    if (maxMarks != null) 'maxMarks': maxMarks,
    if (attemptNumber != null) 'attemptNumber': attemptNumber,
  };

  bool get isPassed => resultStatus == 'PASS';
  bool get isFailed => resultStatus == 'FAIL';
}

class ExamCellAuditModel {
  final int id;
  final int examCellResultId;
  final String studentId;
  final String action;
  final String? previousStatus;
  final String? newStatus;
  final String performedBy;
  final String? performedByRole;
  final String performedAt;
  final String? comments;

  ExamCellAuditModel({
    required this.id,
    required this.examCellResultId,
    required this.studentId,
    required this.action,
    this.previousStatus,
    this.newStatus,
    required this.performedBy,
    this.performedByRole,
    required this.performedAt,
    this.comments,
  });

  factory ExamCellAuditModel.fromJson(Map<String, dynamic> json) {
    return ExamCellAuditModel(
      id: json['id'],
      examCellResultId: json['examCellResultId'],
      studentId: json['studentId'] ?? '',
      action: json['action'] ?? '',
      previousStatus: json['previousStatus'],
      newStatus: json['newStatus'],
      performedBy: json['performedBy'] ?? '',
      performedByRole: json['performedByRole'],
      performedAt: json['performedAt']?.toString() ?? '',
      comments: json['comments'],
    );
  }
}
