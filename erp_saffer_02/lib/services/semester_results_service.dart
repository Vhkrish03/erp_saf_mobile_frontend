import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';

class SemesterResultsService {
  final String _baseUrl = ApiConstants.baseUrl;

  /// Fetch students semester results for a teacher's assigned class/section
  Future<List<Map<String, dynamic>>> getTeacherStudentsResults({
    required String teacherId,
    required String academicYear,
    String? semester,
    String? year,
    required String department,
    required String section,
  }) async {
    final queryParams = {
      'teacherId': teacherId,
      'academicYear': academicYear,
      if (semester != null) 'semester': semester,
      if (year != null) 'year': year,
      'department': department,
      'section': section,
    };
    final uri = Uri.parse(
      '$_baseUrl/api/semester-results/teacher/students',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
      jsonDecode(response.body)['message'] ??
          'Failed to load teacher student results',
    );
  }

  /// Fetch student list & results for HOD matching department & semester filters
  Future<List<Map<String, dynamic>>> getHodStudentsResults({
    required String hodId,
    required String academicYear,
    String? semester,
    String? year,
    required String department,
    String? section,
    String? resultStatus,
  }) async {
    final queryParams = {
      'hodId': hodId,
      'academicYear': academicYear,
      if (semester != null) 'semester': semester,
      if (year != null) 'year': year,
      'department': department,
      if (section != null && section.isNotEmpty) 'section': section,
      if (resultStatus != null && resultStatus.isNotEmpty)
        'resultStatus': resultStatus,
    };
    final uri = Uri.parse(
      '$_baseUrl/api/semester-results/hod/students',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
      jsonDecode(response.body)['message'] ??
          'Failed to load HOD student results',
    );
  }

  /// Fetch HOD department analytics and class performance statistics
  Future<Map<String, dynamic>> getHodStatistics({
    required String hodId,
    required String academicYear,
    String? semester,
    String? year,
    required String department,
    String? section,
  }) async {
    final queryParams = {
      'hodId': hodId,
      'academicYear': academicYear,
      if (semester != null) 'semester': semester,
      if (year != null) 'year': year,
      'department': department,
      if (section != null && section.isNotEmpty) 'section': section,
    };
    final uri = Uri.parse(
      '$_baseUrl/api/semester-results/hod/statistics',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Failed to load HOD statistics',
    );
  }

  /// Get student result as a Teacher
  Future<Map<String, dynamic>> getTeacherStudentResult({
    required String studentId,
    required String teacherId,
    required String semester,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/semester-results/teacher/student/$studentId?teacherId=$teacherId&semester=$semester',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Failed to load student result',
    );
  }

  /// Get student result as an HOD
  Future<Map<String, dynamic>> getHodStudentResult({
    required String studentId,
    required String hodId,
    required String semester,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/semester-results/hod/student/$studentId?hodId=$hodId&semester=$semester',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Failed to load student result',
    );
  }
}
