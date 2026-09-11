import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/exam_cell_model.dart';
import '../../core/api_constants.dart';

class ExamCellService {
  static const String _base = '${ApiConstants.baseUrl}/api/exam-cell';

  // ── Exam Cell Staff Operations ────────────────────────────────────────────

  /// Create or update an official semester result (DRAFT)
  Future<ExamCellResultModel> saveResult({
    required ExamCellResultModel result,
    required String performedBy,
    String role = 'EXAM_CELL',
  }) async {
    final uri = Uri.parse('$_base/results?performedBy=$performedBy&role=$role');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(result.toJson()),
    );
    _checkStatus(res, 'Save result');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  /// Bulk create or update official semester results
  Future<List<ExamCellResultModel>> saveResultBulk({
    required List<ExamCellResultModel> results,
    required String performedBy,
    String role = 'EXAM_CELL',
  }) async {
    final uri = Uri.parse(
      '$_base/results/bulk?performedBy=$performedBy&role=$role',
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(results.map((r) => r.toJson()).toList()),
    );
    _checkStatus(res, 'Bulk save results');
    final List data = jsonDecode(res.body);
    return data.map((e) => ExamCellResultModel.fromJson(e)).toList();
  }

  /// Exam Cell: internally verify result. DRAFT → VERIFIED
  Future<ExamCellResultModel> verifyResult({
    required int resultId,
    required String performedBy,
    String role = 'EXAM_CELL',
    String? comments,
  }) async {
    var url =
        '$_base/results/$resultId/verify?performedBy=$performedBy&role=$role';
    if (comments != null) url += '&comments=${Uri.encodeComponent(comments)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'Verify result');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  /// Dean / Authority: approve result. VERIFIED → APPROVED
  Future<ExamCellResultModel> approveResult({
    required int resultId,
    required String performedBy,
    String role = 'DEAN',
    String? comments,
  }) async {
    var url =
        '$_base/results/$resultId/approve?performedBy=$performedBy&role=$role';
    if (comments != null) url += '&comments=${Uri.encodeComponent(comments)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'Approve result');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  /// Exam Cell: publish result. APPROVED → PUBLISHED (students can now see it)
  Future<ExamCellResultModel> publishResult({
    required int resultId,
    required String performedBy,
    String role = 'EXAM_CELL',
  }) async {
    final uri = Uri.parse(
      '$_base/results/$resultId/publish?performedBy=$performedBy&role=$role',
    );
    final res = await http.post(uri);
    _checkStatus(res, 'Publish result');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  /// Return result for correction. Any non-PUBLISHED → DRAFT
  Future<ExamCellResultModel> returnForCorrection({
    required int resultId,
    required String performedBy,
    String role = 'EXAM_CELL',
    String? reason,
  }) async {
    var url =
        '$_base/results/$resultId/return?performedBy=$performedBy&role=$role';
    if (reason != null) url += '&reason=${Uri.encodeComponent(reason)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'Return result');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Get all results for a student — Exam Cell / Admin
  Future<List<ExamCellResultModel>> getAllResultsForStudent(
    String studentId,
  ) async {
    final res = await http.get(Uri.parse('$_base/results/student/$studentId'));
    _checkStatus(res, 'Get all results for student');
    final List data = jsonDecode(res.body);
    return data.map((e) => ExamCellResultModel.fromJson(e)).toList();
  }

  /// Get results by status — Exam Cell dashboard
  Future<List<ExamCellResultModel>> getResultsByStatus(String status) async {
    final res = await http.get(Uri.parse('$_base/results/status/$status'));
    _checkStatus(res, 'Get results by status');
    final List data = jsonDecode(res.body);
    return data.map((e) => ExamCellResultModel.fromJson(e)).toList();
  }

  /// Get a single result by ID
  Future<ExamCellResultModel> getResultById(int resultId) async {
    final res = await http.get(Uri.parse('$_base/results/$resultId'));
    _checkStatus(res, 'Get result by id');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  /// Get audit trail for a result
  Future<List<ExamCellAuditModel>> getAuditTrail(int resultId) async {
    final res = await http.get(Uri.parse('$_base/results/$resultId/audit'));
    _checkStatus(res, 'Get audit trail');
    final List data = jsonDecode(res.body);
    return data.map((e) => ExamCellAuditModel.fromJson(e)).toList();
  }

  /// Class-wise summary for dashboard
  Future<List<Map<String, dynamic>>> getClassResultSummary({
    required String department,
    required String semester,
    required String academicYear,
    required String year,
    String? section,
  }) async {
    var url =
        '$_base/results/class?department=$department&semester=$semester&academicYear=$academicYear&year=$year';
    if (section != null) url += '&section=$section';
    final res = await http.get(Uri.parse(url));
    _checkStatus(res, 'Get class result summary');
    final List data = jsonDecode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ── Student View (Published Only) ─────────────────────────────────────────

  /// Student: get own PUBLISHED results
  Future<List<ExamCellResultModel>> getPublishedResultsForStudent(
    String studentId,
  ) async {
    final res = await http.get(Uri.parse('$_base/student/$studentId/results'));
    _checkStatus(res, 'Get published results');
    final List data = jsonDecode(res.body);
    return data.map((e) => ExamCellResultModel.fromJson(e)).toList();
  }

  /// Student: get PUBLISHED result for a specific semester
  Future<ExamCellResultModel?> getPublishedResultForSemester(
    String studentId,
    String semester,
  ) async {
    final res = await http.get(
      Uri.parse('$_base/student/$studentId/results/$semester'),
    );
    if (res.statusCode == 404) return null;
    _checkStatus(res, 'Get published result for semester');
    return ExamCellResultModel.fromJson(jsonDecode(res.body));
  }

  // ── Semester Result Batch Operations ──────────────────────────────────────────────

  Future<Map<String, dynamic>> createBatch(Map<String, dynamic> request) async {
    final res = await http.post(
      Uri.parse('$_base/batches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request),
    );
    _checkStatus(res, 'Create result batch');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> submitBatch(
    int batchId,
    String performedBy,
    String role,
  ) async {
    final res = await http.post(
      Uri.parse(
        '$_base/batches/$batchId/submit?performedBy=$performedBy&role=$role',
      ),
    );
    _checkStatus(res, 'Submit result batch');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyBatchIncharge(
    int batchId,
    String performedBy, {
    String remarks = '',
  }) async {
    var url =
        '$_base/batches/$batchId/verify-incharge?performedBy=$performedBy&role=CLASS_INCHARGE';
    if (remarks.isNotEmpty) url += '&remarks=${Uri.encodeComponent(remarks)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'Incharge verify batch');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyBatchHod(
    int batchId,
    String performedBy, {
    String remarks = '',
  }) async {
    var url =
        '$_base/batches/$batchId/verify-hod?performedBy=$performedBy&role=HOD';
    if (remarks.isNotEmpty) url += '&remarks=${Uri.encodeComponent(remarks)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'HOD verify batch');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> approveBatchDean(
    int batchId,
    String performedBy, {
    String remarks = '',
  }) async {
    var url =
        '$_base/batches/$batchId/approve-dean?performedBy=$performedBy&role=DEAN';
    if (remarks.isNotEmpty) url += '&remarks=${Uri.encodeComponent(remarks)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'Dean approve batch');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> rejectBatch(
    int batchId,
    String targetStatus,
    String performedBy,
    String role,
    String remarks,
  ) async {
    final url =
        '$_base/batches/$batchId/reject?targetStatus=$targetStatus&performedBy=$performedBy&role=$role&remarks=${Uri.encodeComponent(remarks)}';
    final res = await http.post(Uri.parse(url));
    _checkStatus(res, 'Reject batch');
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getAllBatches({
    String? department,
    String? status,
  }) async {
    var url = '$_base/batches?';
    if (department != null) url += 'department=$department&';
    if (status != null) url += 'status=$status';
    final res = await http.get(Uri.parse(url));
    _checkStatus(res, 'Get all batches');
    return jsonDecode(res.body);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  void _checkStatus(http.Response res, String op) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = res.body;
      try {
        final decoded = jsonDecode(res.body);
        msg = decoded['error'] ?? msg;
      } catch (_) {}
      throw Exception('[$op] HTTP ${res.statusCode}: $msg');
    }
  }
}
