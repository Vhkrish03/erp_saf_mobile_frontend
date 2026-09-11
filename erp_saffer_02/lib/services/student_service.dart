import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/contact_update_request.dart';
import '../models/student.dart';




class StudentService {

  static const String baseUrl = "https://erp-saf-backend.onrender.com/api/student";

  Future<Student> getStudent(String id) async {

    final response =
    await http.get(Uri.parse("$baseUrl/$id"));

    if (response.statusCode == 200) {

      return Student.fromJson(
          jsonDecode(response.body));

    } else {

      throw Exception("Student not found");
    }
  }


  Future<void> updateContact(
      String studentId,
      ContactUpdateRequest request,
      ) async {

    final response = await http.put(
      Uri.parse("$baseUrl/contact/$studentId"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update contact details");
    }
  }



}