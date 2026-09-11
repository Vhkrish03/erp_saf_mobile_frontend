import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:erp_saf/core/api_constants.dart';
import 'package:erp_saf/models/student.dart';
import '../models/assessment_model.dart';

class AssessmentService {
  Future<List<AssessmentModel>> getWeeklyAssessments({
    required String department,
    required String semester,
    required String section,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/weekly?department=$department&semester=$semester&section=$section",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => AssessmentModel.fromJson(item)).toList();
    }
    throw Exception("Failed to load weekly assessments");
  }

  Future<List<AssessmentModel>> getIatAssessments({
    required String department,
    required String semester,
    required String section,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/iat?department=$department&semester=$semester&section=$section",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => AssessmentModel.fromJson(item)).toList();
    }
    throw Exception("Failed to load IAT assessments");
  }

  Future<List<AssessmentModel>> getModelAssessments({
    required String department,
    required String semester,
    required String section,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/model?department=$department&semester=$semester&section=$section",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => AssessmentModel.fromJson(item)).toList();
    }
    throw Exception("Failed to load Model Exam assessments");
  }

  Future<List<AssessmentModel>> getAssessmentsByFaculty(
    String facultyId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/faculty/$facultyId",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => AssessmentModel.fromJson(item)).toList();
    }
    throw Exception("Failed to load faculty assessments");
  }

  Future<AssessmentModel> createAssessment(
    Map<String, dynamic> assessmentJson,
  ) async {
    final response = await http
        .post(
          Uri.parse("${ApiConstants.baseUrl}/api/assessments"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(assessmentJson),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return AssessmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create assessment");
  }

  Future<List<Student>> getStudentsForAssessment(int assessmentId) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/students",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Student.fromJson(item)).toList();
    }
    throw Exception("Failed to load students for assessment");
  }

  Future<List<AssessmentMarkModel>> getMarksForAssessment(
    int assessmentId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/marks",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => AssessmentMarkModel.fromJson(item)).toList();
    }
    throw Exception("Failed to load assessment marks");
  }

  Future<bool> saveMarks({
    required int assessmentId,
    required int componentId,
    required List<AssessmentMarkModel> marks,
    required String facultyId,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/marks?componentId=$componentId&facultyId=$facultyId",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(marks.map((m) => m.toJson()).toList()),
        )
        .timeout(const Duration(seconds: 30));
    return response.statusCode == 200;
  }

  Future<AssessmentModel> submitAssessment({
    required int assessmentId,
    required String facultyId,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/submit?facultyId=$facultyId",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return AssessmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to submit assessment");
  }

  Future<AssessmentModel> verifyClassIncharge({
    required int assessmentId,
    required bool accept,
    String? comment,
  }) async {
    final commentParam =
        comment != null ? "&comment=${Uri.encodeComponent(comment)}" : "";
    final response = await http
        .post(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/verify/class-incharge?accept=$accept$commentParam",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return AssessmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to verify as class incharge");
  }

  Future<AssessmentModel> verifyHod({
    required int assessmentId,
    required bool approve,
    String? comment,
  }) async {
    final commentParam =
        comment != null ? "&comment=${Uri.encodeComponent(comment)}" : "";
    final response = await http
        .post(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/verify/hod?approve=$approve$commentParam",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return AssessmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to verify as HOD");
  }

  Future<AssessmentModel> submitToDean({required int assessmentId}) async {
    final response = await http
        .post(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/$assessmentId/submit/dean",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return AssessmentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to submit to Dean");
  }

  Future<Map<String, dynamic>> getConsolidatedMarks({
    required String department,
    required String semester,
    required String section,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/consolidated?department=$department&semester=$semester&section=$section",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load consolidated marks");
  }

  Future<bool> clearClassAssessments({
    required String department,
    required String semester,
    required String section,
  }) async {
    final response = await http
        .delete(
          Uri.parse(
            "${ApiConstants.baseUrl}/api/assessments/clear?department=$department&semester=$semester&section=$section",
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(
      "Server returned code ${response.statusCode}: ${response.body}",
    );
  }
}
