import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:erp_saf/core/api_constants.dart';
import '../../models/Timetable_model.dart';

class TeacherTimetableService {
  Future<List<TimetableModel>> getTeacherTimetable(
      String employeeId) async {

    final url = "${ApiConstants.baseUrl}/api/timetable/teacher/$employeeId";
    print(url);

    final response = await http.get(Uri.parse(url));

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => TimetableModel.fromJson(e))
          .toList();
    }

    throw Exception("Failed to load timetable");
  }
}