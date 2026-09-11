import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';

class ExamAdminService {
  final String _baseUrl = ApiConstants.baseUrl;

  Future<List<Map<String, dynamic>>> fetchStudentsWithResults({
    required String department,
    required String semester,
    required String section,
    required String academicYear,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/results/admin/list").replace(
      queryParameters: {
        'department': department,
        'semester': semester,
        'section': section,
        'academicYear': academicYear,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
        "Failed to fetch students with results: ${response.statusCode}",
      );
    }
  }

  Future<Map<String, dynamic>> fetchStats({
    required String department,
    required String semester,
    required String section,
    required String academicYear,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/results/admin/stats").replace(
      queryParameters: {
        'department': department,
        'semester': semester,
        'section': section,
        'academicYear': academicYear,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch statistics: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubjectsForClass({
    required String department,
    required String semester,
  }) async {
    // Extract integer from semester (e.g., "S6" -> 6, "Semester 6" -> 6, "6" -> 6)
    int semNum = 1;
    try {
      semNum = int.parse(semester.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (_) {
      semNum = 1;
    }

    final uri = Uri.parse(
      "$_baseUrl/api/subjects/department/$department/semester/$semNum",
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
        "Failed to load subjects for $department / Sem $semNum: ${response.statusCode}",
      );
    }
  }

  Future<Map<String, dynamic>> saveSemesterResult({
    required Map<String, dynamic> semesterResult,
    required String performedBy,
    String? comments,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/results/admin/save").replace(
      queryParameters: {
        'performedBy': performedBy,
        if (comments != null) 'comments': comments,
      },
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(semesterResult),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to save semester result: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateStatus({
    required int resultId,
    required String status,
    required String performedBy,
    String? comments,
  }) async {
    final uri = Uri.parse(
      "$_baseUrl/api/results/admin/$resultId/status",
    ).replace(
      queryParameters: {
        'status': status,
        'performedBy': performedBy,
        if (comments != null) 'comments': comments,
      },
    );

    final response = await http.post(uri);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update status to $status: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchAudits(int resultId) async {
    final uri = Uri.parse("$_baseUrl/api/results/admin/$resultId/audits");
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to fetch audits: ${response.statusCode}");
    }
  }
}
