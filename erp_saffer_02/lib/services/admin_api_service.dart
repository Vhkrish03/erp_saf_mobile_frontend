import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/student.dart';
import '../teacher/models/teacher.dart';

class AdminApiService {
  static const String baseAdminUrl = "${ApiConstants.baseUrl}/api/admin";

  // ==========================================
  // STUDENT MANAGEMENT
  // ==========================================

  Future<List<Student>> getAllStudents() async {
    final response = await http.get(Uri.parse("$baseAdminUrl/students"));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load students");
    }
  }

  Future<String> getStudentPassword(String id) async {
    final response = await http.get(
      Uri.parse("$baseAdminUrl/students/${Uri.encodeComponent(id)}/password"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["password"] ?? "";
    } else {
      throw Exception("Failed to load password");
    }
  }

  Future<void> createStudent(
    Map<String, dynamic> studentData,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseAdminUrl/students"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"student": studentData, "password": password}),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to create student");
    }
  }

  Future<void> updateStudent(
    String id,
    Map<String, dynamic> studentData, {
    String? password,
  }) async {
    Map<String, dynamic> body = {"student": studentData};
    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }
    final response = await http.put(
      Uri.parse("$baseAdminUrl/students/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to update student");
    }
  }

  Future<void> deleteStudent(String id) async {
    final response = await http.delete(Uri.parse("$baseAdminUrl/students/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete student");
    }
  }

  // ==========================================
  // TEACHER MANAGEMENT
  // ==========================================

  Future<List<Teacher>> getAllTeachers() async {
    final response = await http.get(Uri.parse("$baseAdminUrl/teachers"));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Teacher.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load teachers");
    }
  }

  Future<String> getTeacherPassword(int id) async {
    final response = await http.get(
      Uri.parse("$baseAdminUrl/teachers/$id/password"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["password"] ?? "";
    } else {
      throw Exception("Failed to load password");
    }
  }

  Future<void> createTeacher(
    Map<String, dynamic> teacherData,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseAdminUrl/teachers"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"teacher": teacherData, "password": password}),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to create teacher");
    }
  }

  Future<void> updateTeacher(
    int id,
    Map<String, dynamic> teacherData, {
    String? password,
  }) async {
    if (password != null && password.isNotEmpty) {
      teacherData["password"] = password;
    }
    final response = await http.put(
      Uri.parse("$baseAdminUrl/teachers/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(teacherData),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to update teacher");
    }
  }

  Future<void> deleteTeacher(int id) async {
    final response = await http.delete(Uri.parse("$baseAdminUrl/teachers/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete teacher");
    }
  }

  // ==========================================
  // HOD MANAGEMENT
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllHods() async {
    final response = await http.get(Uri.parse("$baseAdminUrl/hods"));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to load HODs");
    }
  }

  Future<void> createHod(Map<String, dynamic> hodData, String password) async {
    final response = await http.post(
      Uri.parse("$baseAdminUrl/hods"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"hod": hodData, "password": password}),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to create HOD");
    }
  }

  Future<String> getHodPassword(int id) async {
    final response = await http.get(
      Uri.parse("$baseAdminUrl/hods/$id/password"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["password"] ?? "";
    } else {
      throw Exception("Failed to load password");
    }
  }

  Future<void> updateHod(
    int id,
    Map<String, dynamic> hodData, {
    String? password,
  }) async {
    if (password != null && password.isNotEmpty) {
      hodData["password"] = password;
    }
    final response = await http.put(
      Uri.parse("$baseAdminUrl/hods/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(hodData),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to update HOD");
    }
  }

  Future<void> deleteHod(int id) async {
    final response = await http.delete(Uri.parse("$baseAdminUrl/hods/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete HOD");
    }
  }

  // ==========================================
  // EXAM CELL ADMIN MANAGEMENT
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllExamCellAdmins() async {
    final response = await http.get(
      Uri.parse("$baseAdminUrl/exam-cell-admins"),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to load exam cell admins");
    }
  }

  Future<void> createExamCellAdmin(
    Map<String, dynamic> adminData,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseAdminUrl/exam-cell-admins"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"examCellAdmin": adminData, "password": password}),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData["message"] ?? "Failed to create Exam Cell Admin",
      );
    }
  }

  Future<String> getExamCellPassword(int id) async {
    final response = await http.get(
      Uri.parse("$baseAdminUrl/exam-cell-admins/$id/password"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["password"] ?? "";
    } else {
      throw Exception("Failed to load password");
    }
  }

  Future<void> updateExamCellAdmin(
    int id,
    Map<String, dynamic> adminData, {
    String? password,
  }) async {
    if (password != null && password.isNotEmpty) {
      adminData["password"] = password;
    }
    final response = await http.put(
      Uri.parse("$baseAdminUrl/exam-cell-admins/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(adminData),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData["message"] ?? "Failed to update Exam Cell Admin",
      );
    }
  }

  Future<void> deleteExamCellAdmin(int id) async {
    final response = await http.delete(
      Uri.parse("$baseAdminUrl/exam-cell-admins/$id"),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to delete exam cell admin");
    }
  }

  // ==========================================
  // SUPER ADMIN ACTIONS
  // ==========================================

  Future<void> createAdmin(
    String fullName,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseAdminUrl/create-admin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "password": password,
      }),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["message"] ?? "Failed to create Admin");
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await http.get(Uri.parse("$baseAdminUrl/users"));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to load users");
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse("$baseAdminUrl/users/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete user");
    }
  }

  // ==========================================
  // FACULTY SUBJECT ASSIGNMENT & ACADEMICS
  // ==========================================

  Future<List<dynamic>> getAllSubjects() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/subjects"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load subjects");
  }

  Future<List<dynamic>> getFilteredSubjects(
    String department,
    String year,
    int semester,
  ) async {
    final response = await http.get(
      Uri.parse(
        "${ApiConstants.baseUrl}/api/subjects/filter?department=${Uri.encodeComponent(department)}&year=${Uri.encodeComponent(year)}&semester=$semester",
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to filter subjects");
  }

  Future<List<dynamic>> getAllAcademicYears() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/academic-years"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load academic years");
  }

  Future<List<dynamic>> getTeacherAssignments(String employeeId) async {
    final response = await http.get(
      Uri.parse(
        "${ApiConstants.baseUrl}/api/faculty-subjects/teacher/$employeeId",
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load teacher assignments");
  }

  Future<void> createSubjectAssignment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/faculty-subjects"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["error"] ?? "Failed to create subject assignment");
    }
  }

  Future<void> deleteSubjectAssignment(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/faculty-subjects/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove assignment');
    }
  }

  // ==== CLASS INCHARGE API ====

  Future<Map<String, dynamic>?> getClassInchargeAssignmentForTeacher(
    String employeeId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/admin/class-incharge-assignments/teacher/$employeeId',
      ),
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return null;
      }
    }
    throw Exception('Failed to check class in-charge assignment');
  }

  Future<Map<String, dynamic>?> getClassInchargeAssignmentForClass({
    required String department,
    required String year,
    required String section,
    required String academicYear,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/admin/class-incharge-assignments/class?department=$department&year=$year&section=$section&academicYear=$academicYear',
      ),
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return null;
      }
    }
    throw Exception('Failed to check class in-charge assignment');
  }

  Future<void> assignClassIncharge(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/class-incharge-assignments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to assign class incharge: ${response.body}');
    }
  }

  Future<void> removeClassIncharge(String employeeId) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/admin/class-incharge-assignments/teacher/$employeeId',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove class incharge assignment');
    }
  }
}
