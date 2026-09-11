import 'dart:convert';
import 'package:http/http.dart' as http;
import 'teacher_student_service.dart';
import '../models/student_summary.dart';
import '../../core/api_constants.dart';

class AssignedClass {
  final String department;
  final String year;
  final String section;

  AssignedClass({
    required this.department,
    required this.year,
    required this.section,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignedClass &&
          runtimeType == other.runtimeType &&
          department == other.department &&
          year == other.year &&
          section == other.section;

  @override
  int get hashCode => department.hashCode ^ year.hashCode ^ section.hashCode;
}

/// Handles fetching class rosters for attendance and saving attendance records.
class AttendanceService {
  final TeacherStudentService _studentService = TeacherStudentService();

  Future<List<StudentSummary>> getStudentsForAttendance({
    required String department,
    String semester = '',
    String year = '',
    required String section,
    required DateTime date,
  }) async {
    List<StudentSummary> students = await _studentService.getStudents();

    students =
        students.where((s) {
          final dept =
              department.isEmpty ||
              s.department.trim().toLowerCase() ==
                  department.trim().toLowerCase();

          final sec =
              section.isEmpty ||
              s.section.trim().toLowerCase() == section.trim().toLowerCase();

          final sem =
              semester.isEmpty ||
              s.semester.trim().toLowerCase() == semester.trim().toLowerCase();

          // Robust matching of Year and Fallback to Roman Numerical/Semester values
          bool matchYear = false;
          if (year.isEmpty) {
            matchYear = true;
          } else {
            final checkYr = year.trim().toLowerCase();
            final studYr = s.year.trim().toLowerCase();
            final studSem = s.semester.trim().toUpperCase();

            if (studYr == checkYr ||
                // 1st Year checks
                (checkYr.contains('1') &&
                    (studYr.contains('1') ||
                        studYr == 'i' ||
                        studSem == 'I' ||
                        studSem == 'II')) ||
                // 2nd Year checks
                (checkYr.contains('2') &&
                    (studYr.contains('2') ||
                        studYr == 'ii' ||
                        studSem == 'III' ||
                        studSem == 'IV')) ||
                // 3rd Year checks
                (checkYr.contains('3') &&
                    (studYr.contains('3') ||
                        studYr == 'iii' ||
                        studSem == 'V' ||
                        studSem == 'VI')) ||
                // 4th Year checks
                (checkYr.contains('4') &&
                    (studYr.contains('4') ||
                        studYr == 'iv' ||
                        studSem == 'VII' ||
                        studSem == 'VIII'))) {
              matchYear = true;
            }
          }

          return dept && sec && sem && matchYear;
        }).toList();

    print("After filter: ${students.length}");
    return students;
  }

  Future<List<AssignedClass>> getAssignedClasses(String employeeId) async {
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/attendance-core/teacher/$employeeId/assignments",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assignments = data['assignments'] as List<dynamic>? ?? [];
        final delegations = data['delegations'] as List<dynamic>? ?? [];
        final incharges = data['incharges'] as List<dynamic>? ?? [];

        Set<AssignedClass> classes = {};
        for (var a in assignments) {
          classes.add(
            AssignedClass(
              department: a['department'] ?? '',
              year: a['year'] ?? '',
              section: a['section'] ?? '',
            ),
          );
        }
        for (var d in delegations) {
          classes.add(
            AssignedClass(
              department: d['department'] ?? '',
              year: d['year'] ?? '',
              section: d['section'] ?? '',
            ),
          );
        }
        for (var i in incharges) {
          classes.add(
            AssignedClass(
              department: i['department'] ?? '',
              year: i['year'] ?? '',
              section: i['section'] ?? '',
            ),
          );
        }

        // WORKAROUND: If the backend deployed on Render doesn't natively return Class Incharge assignments
        // inside the attendance API, we fetch it manually and append it.
        try {
          final inchargeUrl = Uri.parse(
            '${ApiConstants.baseUrl}/api/admin/class-incharge-assignments/teacher/$employeeId',
          );
          final inchargeRes = await http.get(inchargeUrl);
          if (inchargeRes.statusCode == 200 && inchargeRes.body.isNotEmpty) {
            final inchargeMap = jsonDecode(inchargeRes.body);
            if (inchargeMap != null && inchargeMap['active'] == true) {
              classes.add(
                AssignedClass(
                  department: inchargeMap['department'] ?? '',
                  year: inchargeMap['year'] ?? '',
                  section: inchargeMap['section'] ?? '',
                ),
              );
            }
          }
        } catch (e) {
          print("Failed fetching workaround incharge assignment: $e");
        }

        return classes.toList();
      }
    } catch (e) {
      print("Error fetching assigned classes: $e");
    }
    // Return empty if failure, forcing the UI to show they have no permissions
    return [];
  }

  /// Sends attendance data to backend, which persists it so that HOD can access it.
  Future<bool> saveAttendance({
    required String department,
    required String year,
    required String section,
    required String subject,
    required DateTime date,
    required List<AttendanceRecord> records,
    required String submittedBy,
  }) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/api/attendance");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'department': department,
          'studentYear': year,
          'section': section,
          'subject': subject,
          'date':
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
          'submittedBy': submittedBy,
          'records': records.map((r) => r.toJson()).toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Save attendance error: $e");
      return false;
    }
  }

  Future<List<dynamic>> getReportsForHod(String department) async {
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/attendance/department/$department",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print("Error fetching reports for HOD: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> checkAttendanceExists({
    required String department,
    required String year,
    required String section,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/attendance/check"
        "?department=${Uri.encodeComponent(department)}"
        "&studentYear=${Uri.encodeComponent(year)}"
        "&section=${Uri.encodeComponent(section)}"
        "&subject=${Uri.encodeComponent('')}"
        "&date=${Uri.encodeComponent(dateStr)}",
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['exists'] == true) {
          return data['report'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("Check attendance exists error: $e");
    }
    return null;
  }

  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String department,
    required String year,
    required String section,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final students = await _studentService.getStudents();
    return students
        .map((s) => AttendanceRecord(studentId: s.id, isPresent: true))
        .toList();
  }
}
