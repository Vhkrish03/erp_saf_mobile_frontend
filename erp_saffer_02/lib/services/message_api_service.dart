import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/grievance_message.dart';

class MessageApiService {
  Future<void> sendMessage(GrievanceMessage msg) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(msg.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<GrievanceMessage>> getInbox(String receiverId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/inbox/$receiverId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GrievanceMessage.fromJson(e)).toList();
    }
    throw Exception('Failed to load inbox');
  }

  Future<List<GrievanceMessage>> getSentMessages(String senderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/sent/$senderId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GrievanceMessage.fromJson(e)).toList();
    }
    throw Exception('Failed to load sent messages');
  }

  Future<List<GrievanceMessage>> getAllAdminMessages() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/admin/all'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GrievanceMessage.fromJson(e)).toList();
    }
    throw Exception('Failed to load admin messages');
  }

  Future<void> markReadByReceiver(int id) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/mark-read/receiver/$id'),
    );
  }

  Future<void> markReadByAdmin(int id) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/mark-read/admin/$id'),
    );
  }
}
