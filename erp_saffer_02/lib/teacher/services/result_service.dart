import '../models/student_summary.dart';

/// Handles fetching student rosters for result entry and saving/publishing results.
///
/// Mock data phase: static roster with blank marks. Later, replace bodies with
/// real `http` calls, e.g. `POST $baseUrl/results/publish`.
class ResultService {
  static final List<ResultEntry> _mockEntries = List.generate(8, (i) {
    final n = i + 1;
    return ResultEntry(
      studentId: 'STU${n.toString().padLeft(3, '0')}',
      studentName: _mockNames[i % _mockNames.length],
      rollNumber: '21CSE${n.toString().padLeft(3, '0')}',
    );
  });

  static const _mockNames = [
    'Arun Kumar', 'Divya Sri', 'Karthik Raja', 'Priya Dharshini',
    'Vignesh S', 'Meena Loshini', 'Suresh Babu', 'Anitha R',
  ];

  /// GET /results/roster
  Future<List<ResultEntry>> getStudentsForResults({
    required String semester,
    required String section,
    required String subject,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return _mockEntries;
  }

  /// POST /results/save (draft, not yet published)
  Future<bool> saveResults({
    required String semester,
    required String section,
    required String subject,
    required List<ResultEntry> entries,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: POST entries to backend as a draft save.
    return true;
  }

  /// POST /results/publish
  Future<bool> publishResults({
    required String semester,
    required String section,
    required String subject,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: POST to backend to mark results as published/visible to students.
    return true;
  }
}
