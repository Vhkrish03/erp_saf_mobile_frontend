import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_constants.dart';
import '../models/fee_model.dart';

class FeeService {
  static const String baseUrl = "${ApiConstants.baseUrl}/api/fees";
  static const Duration _timeout = Duration(seconds: 15);

  Future<List<Fee>> getFees(String studentId) async {
    // 1. Try detailed endpoint
    try {
      final detailedUrl = "$baseUrl/student-fees/student/$studentId";
      final response = await http.get(Uri.parse(detailedUrl)).timeout(_timeout);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Fee.fromJson(e)).toList();
      }
    } catch (e) {
      print(
        "Detailed student fee API failed, falling back to compatibility: $e",
      );
    }

    // 2. Compatibility old endpoint fallback
    try {
      final compatUrl = "$baseUrl/$studentId";
      final response = await http.get(Uri.parse(compatUrl)).timeout(_timeout);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Fee.fromJson(e)).toList();
      }
    } catch (e) {
      print("Compatibility fee API also failed: $e");
    }

    return [];
  }

  Future<List<FeePayment>> getPaymentHistory(String studentId) async {
    try {
      final paymentsUrl = "$baseUrl/payments/student/$studentId";
      final response = await http.get(Uri.parse(paymentsUrl)).timeout(_timeout);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => FeePayment.fromJson(e)).toList();
      }
    } catch (e) {
      print("Failed loading payment history from backend: $e");
    }
    return [];
  }

  Future<void> configureCustomFees({
    required String studentId,
    required String academicYear,
    required String semester,
    required double tuitionFee,
    required double messFee,
    required double trainingFee,
    required double otherFee,
    required double transportFee,
    required double hostelFee,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/student-fees/configure-custom"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "studentId": studentId,
            "academicYear": academicYear,
            "semester": semester,
            "tuitionFee": tuitionFee,
            "messFee": messFee,
            "trainingFee": trainingFee,
            "otherFee": otherFee,
            "transportFee": transportFee,
            "hostelFee": hostelFee,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["error"] ?? "Failed to configure custom fees");
    }
  }

  Future<void> recordPayment({
    required int studentFeeId,
    required String studentId,
    required double amountPaid,
    required String paymentDate,
    required String paymentMode,
    required String transactionId,
    required String remarks,
    required String recordedBy,
    required String academicYear,
    required String semester,
    required String feeCategory,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/payments"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "studentFeeId": studentFeeId,
            "studentId": studentId,
            "amountPaid": amountPaid,
            "paymentDate": paymentDate,
            "paymentMode": paymentMode,
            "transactionId": transactionId,
            "remarks": remarks,
            "recordedBy": recordedBy,
            "academicYear": academicYear,
            "semester": semester,
            "feeCategory": feeCategory,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["error"] ?? "Failed to record payment");
      } catch (_) {
        throw Exception("Failed to record payment on server");
      }
    }
  }
}
