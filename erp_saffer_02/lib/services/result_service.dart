import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/semester_result.dart';

class ResultService {

  static const String baseUrl =
      "https://erp-saf-backend.onrender.com/api/results";

  Future<List<SemesterResult>> getResults(String studentId) async {

    final response =
    await http.get(Uri.parse("$baseUrl/$studentId"));

    if (response.statusCode == 200) {

      List data = jsonDecode(response.body);

      return data
          .map((e) => SemesterResult.fromJson(e))
          .toList();

    } else {

      throw Exception("Failed to load results");
    }
  }
}