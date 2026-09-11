import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/subject_model.dart';

class ApiService {

  static const String baseUrl =
      "https://erp-saf-backend.onrender.com/api";

  static Future<List<SubjectModel>> getSubjects() async {

    final response = await http.get(
      Uri.parse("$baseUrl/subjects"),
    );

    if (response.statusCode == 200) {

      List jsonData = jsonDecode(response.body);

      return jsonData
          .map((e) => SubjectModel.fromJson(e))
          .toList();

    } else {

      throw Exception("Failed to load subjects");

    }
  }
}