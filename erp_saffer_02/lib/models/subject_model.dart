class SubjectModel {
  final String code;
  final String name;
  final String faculty;
  final int credits;
  final double attendancePercent;
  final int classesHeld;
  final int classesAttended;
  final String? employeeId;

  SubjectModel({
    required this.code,
    required this.name,
    required this.faculty,
    required this.credits,
    required this.attendancePercent,
    required this.classesHeld,
    required this.classesAttended,
    this.employeeId,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      code: json["code"] ?? '',
      name: json["name"] ?? '',
      faculty: json["faculty"] ?? '',
      credits: json["credits"] ?? 0,
      attendancePercent:
          json["attendancePercent"] != null
              ? (json["attendancePercent"] as num).toDouble()
              : 0.0,
      classesHeld: json["classesHeld"] ?? 0,
      classesAttended: json["classesAttended"] ?? 0,
      employeeId: json["employeeId"],
    );
  }
}

class TimetableSlot {
  final String time;
  final String subject;
  final String room;
  final String faculty;

  const TimetableSlot({
    required this.time,
    required this.subject,
    required this.room,
    required this.faculty,
  });
}

// class ExamResult {
//   final String subjectCode;
//   final String subjectName;
//   final String grade;
//   final double gradePoint;
//   final int marksObtained;
//   final int maxMarks;
//
//   const ExamResult({
//     required this.subjectCode,
//     required this.subjectName,
//     required this.grade,
//     required this.gradePoint,
//     required this.marksObtained,
//     required this.maxMarks,
//   });
// }
//
// class SemesterResult {
//   final String semesterName;
//   final double sgpa;
//   final List<ExamResult> results;
//
//   const SemesterResult({
//     required this.semesterName,
//     required this.sgpa,
//     required this.results,
//   });
// }
