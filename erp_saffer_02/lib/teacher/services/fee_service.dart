import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import '../models/fees_model.dart';

class FeeService {
  static const _base = '${ApiConstants.baseUrl}/api/fees';
  static const _timeout = Duration(seconds: 30);

  // ─── Fee Structures ────────────────────────────────────────────────────────

  Future<List<FeeStructureModel>> getAllFeeStructures() async {
    final res = await http.get(Uri.parse('$_base/structure')).timeout(_timeout);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => FeeStructureModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load fee structures');
  }

  Future<List<FeeStructureModel>> getFeeStructuresForClass({
    required String department,
    required String semester,
    required String academicYear,
  }) async {
    final uri = Uri.parse('$_base/structure/class').replace(
      queryParameters: {
        'department': department,
        'semester': semester,
        'academicYear': academicYear,
      },
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => FeeStructureModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load fee structures for class');
  }

  Future<FeeStructureModel> createFeeStructure(
    Map<String, dynamic> payload,
  ) async {
    final res = await http
        .post(
          Uri.parse('$_base/structure'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return FeeStructureModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to create fee structure');
  }

  // ─── Student Fees ──────────────────────────────────────────────────────────

  Future<List<StudentFeeModel>> getFeesForStudent(String studentId) async {
    final res = await http
        .get(Uri.parse('$_base/student-fees/student/$studentId'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => StudentFeeModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load student fees');
  }

  Future<List<StudentFeeModel>> getFeesForClass({
    required String department,
    required String semester,
    required String section,
    required String academicYear,
  }) async {
    final uri = Uri.parse('$_base/student-fees/class').replace(
      queryParameters: {
        'department': department,
        'semester': semester,
        'section': section,
        'academicYear': academicYear,
      },
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => StudentFeeModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load class fees');
  }

  Future<List<StudentFeeModel>> getPendingFees({
    required String department,
    required String semester,
    required String section,
    required String academicYear,
  }) async {
    final uri = Uri.parse('$_base/student-fees/pending').replace(
      queryParameters: {
        'department': department,
        'semester': semester,
        'section': section,
        'academicYear': academicYear,
      },
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => StudentFeeModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load pending fees');
  }

  Future<bool> assignFeeToStudent({
    required String studentId,
    required int feeStructureId,
  }) async {
    final uri = Uri.parse('$_base/student-fees/assign').replace(
      queryParameters: {
        'studentId': studentId,
        'feeStructureId': '$feeStructureId',
      },
    );
    final res = await http.post(uri).timeout(_timeout);
    return res.statusCode == 200;
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  Future<bool> recordPayment(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$_base/payments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    return res.statusCode == 200;
  }

  Future<List<FeePaymentModel>> getPaymentHistory(String studentId) async {
    final res = await http
        .get(Uri.parse('$_base/payments/student/$studentId'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => FeePaymentModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load payment history');
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  Future<FeeDashboardModel> getDashboard({
    required String department,
    required String semester,
    required String section,
    required String academicYear,
  }) async {
    final uri = Uri.parse('$_base/dashboard').replace(
      queryParameters: {
        'department': department,
        'semester': semester,
        'section': section,
        'academicYear': academicYear,
      },
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) {
      return FeeDashboardModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load fee dashboard');
  }
}
