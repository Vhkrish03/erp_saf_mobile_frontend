import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/student_summary.dart';

class TeacherStudentService {

  static const String baseUrl =
      "https://erp-saf-backend.onrender.com/api/teacher/students";

  Future<List<StudentSummary>> getStudents() async {

    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {

      final List data = jsonDecode(response.body);

      return data
          .map((e) => StudentSummary.fromJson(e))
          .toList();

    } else {
      throw Exception("Failed to load students");
    }
  }
}