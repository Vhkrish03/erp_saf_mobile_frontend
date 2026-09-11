import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../models/exam_cell_model.dart';
import '../services/exam_cell_service.dart';
import '../../services/admin_api_service.dart';
import 'bulk_student_roster_screen.dart';

/// Semester Result Entry Screen — for Exam Cell officers.
///
/// Supports:
///  - Bulk entry mode (selecting Department, Year, Semester, and entering marks for all fetched students)
///  - Editing an existing DRAFT result (single student view)
///  - Dynamic subject row configuration for class results
///  - Auto-calculation of SGPA and Grades based on marks
class SemesterResultEntryScreen extends StatefulWidget {
  final String performedBy;
  final String role;
  final ExamCellResultModel? existingResult;

  const SemesterResultEntryScreen({
    super.key,
    required this.performedBy,
    this.role = 'EXAM_CELL',
    this.existingResult,
  });

  @override
  State<SemesterResultEntryScreen> createState() =>
      _SemesterResultEntryScreenState();
}

class _SemesterResultEntryScreenState extends State<SemesterResultEntryScreen> {
  final ExamCellService _service = ExamCellService();
  final _singleFormKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Grade -> grade point mapping (Anna University scale)
  static const Map<String, double> _gradePoints = {
    'O': 10.0,
    'A+': 9.0,
    'A': 8.0,
    'B+': 7.0,
    'B': 6.0,
    'C': 5.0,
    'U': 0.0,
    'RA': 0.0,
    'UA': 0.0,
    'W': 0.0,
  };

  String getGradeFromMarks(double marks) {
    if (marks >= 90) return 'O';
    if (marks >= 80) return 'A+';
    if (marks >= 70) return 'A';
    if (marks >= 60) return 'B+';
    if (marks >= 50) return 'B';
    return 'U';
  }

  // ==========================================
  // SINGLE STUDENT MODE (Original Edit Flow)
  // ==========================================
  final _studentIdCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _examSessionCtrl = TextEditingController();
  final _examinationCtrl = TextEditingController();
  final _academicYearCtrl = TextEditingController();
  String _selectedSem = 'Semester 5';
  final List<Map<String, dynamic>> _singleSubjectRows = [];

  final List<String> _departments = [
    'CSE',
    'ECE',
    'MECH',
    'EEE',
    'CIVIL',
    'IT',
    'H&S',
  ];
  final List<String> _years = ['I', 'II', 'III', 'IV'];
  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  // ==========================================
  // BULK CLASS MODE
  // ==========================================
  // ==========================================
  String? _bulkDept;
  String? _bulkYear;
  String? _bulkSem;
  String? _bulkAcademicYear;
  final _bulkExamSessionCtrl = TextEditingController();

  List<String> _academicYearOptions = [];
  bool _isLoadingAcademicYears = false;

  bool get isEditMode => widget.existingResult != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      // Initialize single student mode details
      final ex = widget.existingResult!;
      _studentIdCtrl.text = ex.studentId;
      _regNoCtrl.text = ex.registerNumber ?? '';
      _studentNameCtrl.text = ex.studentName ?? '';
      _deptCtrl.text = ex.department;
      _examSessionCtrl.text = ex.examSession;
      _examinationCtrl.text = ex.examination ?? '';
      _academicYearCtrl.text = ex.academicYear;
      _selectedSem = ex.semesterName;
      for (final sub in ex.subjects) {
        _singleSubjectRows.add({
          'codeCtrl': TextEditingController(text: sub.subjectCode),
          'nameCtrl': TextEditingController(text: sub.subjectName),
          'creditsCtrl': TextEditingController(text: sub.credits.toString()),
          'grade': sub.grade ?? 'A',
          'resultStatus': sub.resultStatus ?? 'PASS',
          'marksCtrl': TextEditingController(
            text: sub.marksObtained?.toString() ?? '',
          ),
          'maxMarksCtrl': TextEditingController(
            text: sub.maxMarks?.toString() ?? '100',
          ),
          'attemptCtrl': TextEditingController(
            text: sub.attemptNumber?.toString() ?? '1',
          ),
        });
      }
    } else {
      _loadAcademicYears();
    }
  }

  Future<void> _loadAcademicYears() async {
    setState(() => _isLoadingAcademicYears = true);
    try {
      final adminApiService = AdminApiService();
      final raw = await adminApiService.getAllAcademicYears();
      final sortedYears = raw.whereType<Map<String, dynamic>>().toList();
      sortedYears.sort((a, b) {
        final aActive = a['active'] == true || a['isActive'] == true;
        final bActive = b['active'] == true || b['isActive'] == true;
        if (aActive != bActive) return aActive ? -1 : 1;
        return (b['yearName'] ?? '').compareTo(a['yearName'] ?? '');
      });
      setState(() {
        _academicYearOptions =
            sortedYears
                .map((y) => y['yearName']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
        if (_academicYearOptions.isNotEmpty) {
          _bulkAcademicYear = _academicYearOptions.first;
        }
        _isLoadingAcademicYears = false;
      });
    } catch (e) {
      debugPrint("Failed to load academic years: $e");
      setState(() {
        _academicYearOptions = ['2025-26', '2026-27'];
        _bulkAcademicYear = _academicYearOptions.first;
        _isLoadingAcademicYears = false;
      });
    }
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _regNoCtrl.dispose();
    _studentNameCtrl.dispose();
    _deptCtrl.dispose();
    _examSessionCtrl.dispose();
    _examinationCtrl.dispose();
    _academicYearCtrl.dispose();
    _bulkExamSessionCtrl.dispose();
    for (final row in _singleSubjectRows) {
      _disposeRow(row);
    }
    super.dispose();
  }

  void _disposeRow(Map<String, dynamic> row) {
    (row['codeCtrl'] as TextEditingController).dispose();
    (row['nameCtrl'] as TextEditingController).dispose();
    (row['creditsCtrl'] as TextEditingController).dispose();
    if (row.containsKey('marksCtrl') && row['marksCtrl'] != null) {
      (row['marksCtrl'] as TextEditingController).dispose();
    }
    if (row.containsKey('maxMarksCtrl') && row['maxMarksCtrl'] != null) {
      (row['maxMarksCtrl'] as TextEditingController).dispose();
    }
  }

  // ==========================================
  // SINGLE STUDENT MODE ACTIONS (Edit Flow)
  // ==========================================

  double _calcSingleSgpa() {
    double totalCredits = 0, weightedSum = 0;
    for (final row in _singleSubjectRows) {
      final grade = row['grade'] as String;
      final credits =
          double.tryParse(
            (row['creditsCtrl'] as TextEditingController).text.trim(),
          ) ??
          0;
      final gp = _gradePoints[grade] ?? 0.0;
      totalCredits += credits;
      weightedSum += gp * credits;
    }
    return totalCredits > 0 ? weightedSum / totalCredits : 0.0;
  }

  ExamCellResultModel _buildSingleModel({required String status}) {
    final double sgpa = _calcSingleSgpa();
    final subjects =
        _singleSubjectRows.map((row) {
          final grade = row['grade'] as String;
          return ExamCellSubjectModel(
            subjectCode: (row['codeCtrl'] as TextEditingController).text.trim(),
            subjectName: (row['nameCtrl'] as TextEditingController).text.trim(),
            credits:
                int.tryParse(
                  (row['creditsCtrl'] as TextEditingController).text.trim(),
                ) ??
                3,
            grade: grade,
            gradePoint: _gradePoints[grade] ?? 0.0,
            resultStatus: row['resultStatus'],
            marksObtained: double.tryParse(
              (row['marksCtrl'] as TextEditingController).text.trim(),
            ),
            maxMarks: double.tryParse(
              (row['maxMarksCtrl'] as TextEditingController).text.trim(),
            ),
            attemptNumber: int.tryParse(
              (row['attemptCtrl'] as TextEditingController).text.trim(),
            ),
          );
        }).toList();

    return ExamCellResultModel(
      id: widget.existingResult?.id,
      studentId: _studentIdCtrl.text.trim(),
      registerNumber: _regNoCtrl.text.trim(),
      studentName: _studentNameCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
      semesterName: _selectedSem,
      academicYear: _academicYearCtrl.text.trim(),
      examSession: _examSessionCtrl.text.trim(),
      examination: _examinationCtrl.text.trim(),
      status: status,
      sgpa: sgpa,
      subjects: subjects,
    );
  }

  Future<void> _saveSingle({required String status}) async {
    if (!_singleFormKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final model = _buildSingleModel(status: status);
      await _service.saveResult(
        result: model,
        performedBy: widget.performedBy,
        role: widget.role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'PUBLISHED'
                ? 'Result published successfully.'
                : 'Result details successfully saved as DRAFT.',
          ),
          backgroundColor:
              status == 'PUBLISHED' ? Colors.green : const Color(0xFF6C63FF),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // VIEW RENDERING BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        title: Text(
          isEditMode ? 'Edit Student Result' : 'Bulk Results Entry Manager',
          style: ErpTypography.titleLarge.copyWith(color: Colors.white),
        ),
        actions:
            isEditMode
                ? [
                  TextButton.icon(
                    onPressed:
                        _isSaving ? null : () => _saveSingle(status: 'DRAFT'),
                    icon: const Icon(
                      Icons.drafts_outlined,
                      color: ErpColors.accent,
                    ),
                    label: Text(
                      'Save Draft',
                      style: ErpTypography.labelLarge.copyWith(
                        color: ErpColors.accent,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        _isSaving
                            ? null
                            : () => _saveSingle(status: 'PUBLISHED'),
                    icon: const Icon(
                      Icons.send_rounded,
                      color: ErpColors.success,
                    ),
                    label: Text(
                      'Publish',
                      style: ErpTypography.labelLarge.copyWith(
                        color: ErpColors.success,
                      ),
                    ),
                  ),
                ]
                : [],
      ),
      body: isEditMode ? _buildSingleEditLayout() : _buildBulkClassLayout(),
    );
  }

  // 1. Render single edit view
  Widget _buildSingleEditLayout() {
    return Form(
      key: _singleFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Student & Exam Context'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ErpColors.bgWhite,
                borderRadius: ErpRadius.cardSm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Student ID *',
                          _studentIdCtrl,
                          required: true,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Register No', _regNoCtrl)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field('Student Name', _studentNameCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Department *',
                          _deptCtrl,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Academic Year *',
                          _academicYearCtrl,
                          required: true,
                          hint: '2025-26',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semester *',
                              style: GoogleFonts.outfit(
                                color: ErpColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedSem,
                              dropdownColor: ErpColors.bgWhite,
                              style: ErpTypography.bodyLarge,
                              decoration: _inputDecoration(),
                              items:
                                  _semesters
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _selectedSem = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Exam Session *',
                          _examSessionCtrl,
                          required: true,
                          hint: 'Nov/Dec 2025',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(
                    'Examination Name',
                    _examinationCtrl,
                    hint: 'End Semester Examination',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _sectionHeader('Entered Subject Details'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _singleSubjectRows.add({
                        'codeCtrl': TextEditingController(),
                        'nameCtrl': TextEditingController(),
                        'creditsCtrl': TextEditingController(text: '3'),
                        'grade': 'A',
                        'resultStatus': 'PASS',
                        'marksCtrl': TextEditingController(),
                        'maxMarksCtrl': TextEditingController(text: '100'),
                        'attemptCtrl': TextEditingController(text: '1'),
                      });
                    });
                  },
                  icon: const Icon(Icons.add, color: ErpColors.info, size: 18),
                  label: Text(
                    'Add Subject',
                    style: ErpTypography.button.copyWith(
                      color: ErpColors.info,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._singleSubjectRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ErpColors.bgSubtle,
                  borderRadius: ErpRadius.cardSm,
                  border: Border.all(color: ErpColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subject ${idx + 1}',
                          style: ErpTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: ErpColors.danger,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              final removed = _singleSubjectRows.removeAt(idx);
                              _disposeRow(removed);
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Code *',
                            row['codeCtrl'],
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _field(
                            'Subject Name *',
                            row['nameCtrl'],
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: _field(
                            'Credits',
                            row['creditsCtrl'],
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Grade', style: ErpTypography.labelSmall),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: row['grade'],
                                dropdownColor: ErpColors.bgWhite,
                                style: ErpTypography.bodyLarge,
                                decoration: _inputDecoration(),
                                items:
                                    _gradePoints.keys
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(
                                              '$g (${_gradePoints[g]})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setState(() {
                                      row['grade'] = v!;
                                      row['resultStatus'] =
                                          (v == 'U' ||
                                                  v == 'RA' ||
                                                  v == 'UA' ||
                                                  v == 'W')
                                              ? 'FAIL'
                                              : 'PASS';
                                    }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status', style: ErpTypography.labelSmall),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: row['resultStatus'],
                                dropdownColor: ErpColors.bgWhite,
                                style: ErpTypography.bodyLarge,
                                decoration: _inputDecoration(),
                                items:
                                    ['PASS', 'FAIL', 'WITHHELD']
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setState(
                                      () => row['resultStatus'] = v!,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: _field(
                            'Marks',
                            row['marksCtrl'],
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: _field(
                            'Max',
                            row['maxMarksCtrl'],
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ErpColors.bgSubtle,
                borderRadius: ErpRadius.cardSm,
              ),
              child: Row(
                children: [
                  Text('Calculated SGPA:', style: ErpTypography.bodyMedium),
                  const Spacer(),
                  Text(
                    _calcSingleSgpa().toStringAsFixed(2),
                    style: ErpTypography.headlineSmall.copyWith(
                      color: ErpColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkClassLayout() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Cohort Selection Filter'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ErpColors.bgSubtle,
              borderRadius: ErpRadius.card,
              border: Border.all(color: ErpColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                ..._buildFiltersLayout(isMobile),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ErpColors.primary,
                      foregroundColor: ErpColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: ErpRadius.button,
                      ),
                    ),
                    onPressed: () {
                      if (_bulkDept == null ||
                          _bulkAcademicYear == null ||
                          _bulkYear == null ||
                          _bulkSem == null ||
                          _bulkExamSessionCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select all filters and enter the exam session.',
                            ),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BulkStudentRosterScreen(
                                department: _bulkDept!,
                                academicYear: _bulkAcademicYear!,
                                year: _bulkYear!,
                                semester: _bulkSem!,
                                examSession: _bulkExamSessionCtrl.text.trim(),
                                performedBy: widget.performedBy,
                                role: widget.role,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      'Search Student Roster',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: ErpColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool required = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ErpTypography.labelSmall),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboardType,
          style: ErpTypography.bodyLarge,
          decoration: _inputDecoration(hint: hint),
          validator:
              required
                  ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
                  : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: ErpTypography.bodyMedium.copyWith(color: ErpColors.textMuted),
      filled: true,
      fillColor: ErpColors.bgWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: ErpRadius.input,
        borderSide: const BorderSide(color: ErpColors.border),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: ErpRadius.input,
        borderSide: const BorderSide(color: ErpColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: ErpRadius.input,
        borderSide: const BorderSide(color: ErpColors.primary, width: 1.5),
      ),
    );
  }

  List<Widget> _buildFiltersLayout(bool isMobile) {
    final deptField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Department', style: ErpTypography.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _bulkDept,
          hint: Text(
            'Select Department',
            style: ErpTypography.bodyMedium.copyWith(
              color: ErpColors.textMuted,
            ),
          ),
          dropdownColor: ErpColors.bgWhite,
          style: ErpTypography.bodyLarge,
          decoration: _inputDecoration(),
          items:
              _departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
          onChanged: (v) {
            setState(() => _bulkDept = v);
          },
        ),
      ],
    );

    final academicYearField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Academic Year', style: ErpTypography.labelSmall),
        const SizedBox(height: 4),
        _isLoadingAcademicYears
            ? const SizedBox(
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
            : DropdownButtonFormField<String>(
              value: _bulkAcademicYear,
              hint: Text(
                'Select Academic Year',
                style: ErpTypography.bodyMedium.copyWith(
                  color: ErpColors.textMuted,
                ),
              ),
              dropdownColor: ErpColors.bgWhite,
              style: ErpTypography.bodyLarge,
              decoration: _inputDecoration(),
              items:
                  _academicYearOptions
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
              onChanged: (v) {
                setState(() => _bulkAcademicYear = v);
              },
            ),
      ],
    );

    final yearField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Year', style: ErpTypography.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _bulkYear,
          hint: Text(
            'Select Year',
            style: ErpTypography.bodyMedium.copyWith(
              color: ErpColors.textMuted,
            ),
          ),
          dropdownColor: ErpColors.bgWhite,
          style: ErpTypography.bodyLarge,
          decoration: _inputDecoration(),
          items:
              _years
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
          onChanged: (v) {
            setState(() {
              _bulkYear = v;
              if (_bulkYear == 'I') {
                _bulkSem = 'Semester 1';
              } else if (_bulkYear == 'II') {
                _bulkSem = 'Semester 3';
              } else if (_bulkYear == 'III') {
                _bulkSem = 'Semester 5';
              } else if (_bulkYear == 'IV') {
                _bulkSem = 'Semester 7';
              } else {
                _bulkSem = null;
              }
            });
          },
        ),
      ],
    );

    final semField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Semester', style: ErpTypography.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _bulkSem,
          hint: Text(
            'Select Semester',
            style: ErpTypography.bodyMedium.copyWith(
              color: ErpColors.textMuted,
            ),
          ),
          dropdownColor: ErpColors.bgWhite,
          style: ErpTypography.bodyLarge,
          decoration: _inputDecoration(),
          items:
              _semesters
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
          onChanged: (v) {
            setState(() => _bulkSem = v);
          },
        ),
      ],
    );

    final sessionField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exam Session', style: ErpTypography.labelSmall),
        const SizedBox(height: 4),
        TextFormField(
          controller: _bulkExamSessionCtrl,
          style: ErpTypography.bodyLarge,
          decoration: _inputDecoration(hint: 'e.g. Nov/Dec 2025'),
        ),
      ],
    );

    if (isMobile) {
      return [
        deptField,
        const SizedBox(height: 12),
        academicYearField,
        const SizedBox(height: 12),
        yearField,
        const SizedBox(height: 12),
        semField,
        const SizedBox(height: 12),
        sessionField,
      ];
    } else {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: deptField),
            const SizedBox(width: 16),
            Expanded(child: academicYearField),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: yearField),
            const SizedBox(width: 16),
            Expanded(child: semField),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sessionField),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ];
    }
  }
}
