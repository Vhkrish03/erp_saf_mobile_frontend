import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/progress_card_model.dart';
import '../../core/api_constants.dart';

class ProgressCardService {
  static const String _base = '${ApiConstants.baseUrl}/api/progress';

  // ── Student access (FINALIZED internal + PUBLISHED exam only) ─────────────

  /// Fetch official verified progress card for a student.
  /// Internal marks: only DEAN_APPROVED.
  /// Semester result: only PUBLISHED.
  Future<ProgressCardModel> fetchProgressCard({
    required String studentId,
    required String semester,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/student/$studentId?semester=$semester'),
    );
    _checkStatus(res, 'Fetch student progress card');
    return ProgressCardModel.fromJson(jsonDecode(res.body));
  }

  // ── Staff access (all statuses + workflow context) ─────────────────────────

  /// Fetch full progress card for staff (Teacher / Incharge / HOD / Dean).
  Future<ProgressCardModel> fetchProgressCardForStaff({
    required String studentId,
    required String semester,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/staff/student/$studentId?semester=$semester'),
    );
    _checkStatus(res, 'Fetch staff progress card');
    return ProgressCardModel.fromJson(jsonDecode(res.body));
  }

  // ── Class-level view ──────────────────────────────────────────────────────

  /// Fetch class progress summary for Incharge / HOD dashboard.
  Future<List<Map<String, dynamic>>> fetchClassProgress({
    required String department,
    required String semester,
    required String section,
    required String academicYear,
  }) async {
    final uri = Uri.parse(
      '$_base/class?department=$department&semester=$semester'
      '&section=$section&academicYear=$academicYear',
    );
    final res = await http.get(uri);
    _checkStatus(res, 'Fetch class progress');
    final List data = jsonDecode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ── Internal mark calculation trigger ─────────────────────────────────────

  /// Trigger backend internal mark calculation for a student+subject.
  Future<Map<String, dynamic>> calculateInternalMark({
    required String studentId,
    required int subjectId,
    required String semester,
    required String academicYear,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/internal-marks/calculate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentId': studentId,
        'subjectId': subjectId,
        'semester': semester,
        'academicYear': academicYear,
      }),
    );
    _checkStatus(res, 'Calculate internal mark');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── Remarks ───────────────────────────────────────────────────────────────

  /// Add a performance remark (faculty / HOD / incharge).
  Future<RemarkModel> addRemark({
    required String studentId,
    required String semester,
    required String academicYear,
    required String remarkBy,
    required String remarkByRole,
    required String remarkByName,
    required String remarkText,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/remarks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentId': studentId,
        'semester': semester,
        'academicYear': academicYear,
        'remarkBy': remarkBy,
        'remarkByRole': remarkByRole,
        'remarkByName': remarkByName,
        'remarkText': remarkText,
      }),
    );
    _checkStatus(res, 'Add remark');
    return RemarkModel.fromJson(jsonDecode(res.body));
  }

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
