import 'exam_result.dart';

class SemesterResult {
  final String semesterName;
  final double sgpa;
  final List<ExamResult> results;

  SemesterResult({
    required this.semesterName,
    required this.sgpa,
    required this.results,
  });

  factory SemesterResult.fromJson(Map<String, dynamic> json) {
    return SemesterResult(
      semesterName: json['semesterName'],
      sgpa: (json['sgpa'] as num).toDouble(),
      results: (json['results'] as List)
          .map((e) => ExamResult.fromJson(e))
          .toList(),
    );
  }
}