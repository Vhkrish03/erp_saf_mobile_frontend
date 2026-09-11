import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notice.dart';
import '../core/api_constants.dart';

class NoticeService {
  Future<List<Notice>> getNotices(String role, String department) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/notices?role=$role&department=$department",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      List<Notice> notices = [];
      for (var e in data) {
        try {
          notices.add(Notice.fromJson(e));
        } catch (err) {
          print('Error parsing notice $e: $err');
        }
      }
      return notices;
    }
    throw Exception("Failed to load notices");
  }

  Future<Notice> publishNotice({
    required String title,
    required String description,
    required String purpose,
    required String category,
    required String department,
    required String uploaderRole,
    required bool isImportant,
    String? filePath,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("${ApiConstants.baseUrl}/api/notices"),
    );
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['purpose'] = purpose;
    request.fields['category'] = category;
    request.fields['department'] = department;
    request.fields['uploaderRole'] = uploaderRole;
    request.fields['isImportant'] = isImportant.toString();

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      return Notice.fromJson(jsonDecode(respStr));
    }
    throw Exception("Failed to publish notice");
  }

  Future<bool> approveNotice(String id, String role) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/notices/$id/approve?role=$role'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
