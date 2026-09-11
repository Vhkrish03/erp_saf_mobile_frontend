class ExamResult {
  final String subjectCode;
  final String subjectName;
  final String grade;
  final double gradePoint;
  final int marksObtained;
  final int maxMarks;

  ExamResult({
    required this.subjectCode,
    required this.subjectName,
    required this.grade,
    required this.gradePoint,
    required this.marksObtained,
    required this.maxMarks,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      subjectCode: json['subjectCode'],
      subjectName: json['subjectName'],
      grade: json['grade'],
      gradePoint: (json['gradePoint'] as num).toDouble(),
      marksObtained: json['marksObtained'],
      maxMarks: json['maxMarks'],
    );
  }
}