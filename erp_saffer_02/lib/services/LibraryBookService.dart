import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/LibraryBookModel.dart';



class LibraryService {
  static const String baseUrl =
      "https://erp-saf-backend.onrender.com/api/library";

  Future<List<LibraryBook>> getBooks(String studentId) async {
    final response =
    await http.get(Uri.parse("$baseUrl/$studentId"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data
          .map((e) => LibraryBook.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load library books");
    }
  }
}