import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/subject_model.dart';

class SubjectService {

  static const baseUrl =
      "https://erp-saf-backend.onrender.com/api/subjects";

  Future<List<SubjectModel>> getSubjects() async {

    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {

      final List json = jsonDecode(response.body);

      return json
          .map((e) => SubjectModel.fromJson(e))
          .toList();

    }

    throw Exception("Failed to load subjects");
  }
}