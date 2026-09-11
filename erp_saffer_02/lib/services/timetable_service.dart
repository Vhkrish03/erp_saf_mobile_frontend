import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/timetable_model.dart';

class TimetableService {
  static const String baseUrl =
      "https://erp-saf-backend.onrender.com/api/timetable";

  // =============================
  // Student Timetable
  // Fetch timetable by day.
  // =============================
  Future<List<TimetableModel>> getTimetableByDay(String day) async {
    final response = await http.get(Uri.parse("$baseUrl/$day"));

    if (response.statusCode == 200) {
      final List json = jsonDecode(response.body);

      return json
          .map((e) => TimetableModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load timetable");
    }
  }

  // =============================
  // Teacher Timetable
  // Fetch timetable using Employee ID.
  // =============================
  Future<List<TimetableModel>> getTeacherTimetable(
      String employeeId) async {

    final response =
    await http.get(Uri.parse("$baseUrl/teacher/$employeeId"));

    if (response.statusCode == 200) {
      final List json = jsonDecode(response.body);

      return json
          .map((e) => TimetableModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load teacher timetable");
    }
  }
}