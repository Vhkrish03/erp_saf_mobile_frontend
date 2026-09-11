import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/approval_request.dart';

class ApprovalApiService {
  Future<void> submitRequest(ApprovalRequest req) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/approvals/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit approval request: ${response.body}');
    }
  }

  Future<List<ApprovalRequest>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/approvals/pending'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ApprovalRequest.fromJson(e)).toList();
    }
    throw Exception('Failed to load pending requests');
  }

  Future<List<ApprovalRequest>> getHodRequests(String hodId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/approvals/hod/$hodId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ApprovalRequest.fromJson(e)).toList();
    }
    throw Exception('Failed to load HOD requests');
  }

  Future<void> approveRequest(int id, String feedback) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/approvals/$id/approve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'feedback': feedback}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve request: ${response.body}');
    }
  }

  Future<void> rejectRequest(int id, String feedback) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/approvals/$id/reject'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'feedback': feedback}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }
}
