import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/assessment_model.dart';
import '../services/assessment_service.dart';
import '../theme/teacher_theme.dart';

class InchargeDashboardScreen extends StatefulWidget {
  final String department;
  final String semester;
  final String section;

  const InchargeDashboardScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.section,
  });

  @override
  State<InchargeDashboardScreen> createState() =>
      _InchargeDashboardScreenState();
}

class _InchargeDashboardScreenState extends State<InchargeDashboardScreen> {
  final AssessmentService _api = AssessmentService();

  Map<String, dynamic>? _consolidatedReport;
  List<AssessmentModel> _assessments = [];
  bool _loading = true;
  String _error = '';
  bool _actioning = false;
  bool _showSpreadsheet = false;
  String? _selectedSubjectCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final futures = await Future.wait([
        _api.getWeeklyAssessments(
          department: widget.department,
          semester: widget.semester,
          section: widget.section,
        ),
        _api.getIatAssessments(
          department: widget.department,
          semester: widget.semester,
          section: widget.section,
        ),
        _api.getModelAssessments(
          department: widget.department,
          semester: widget.semester,
          section: widget.section,
        ),
        _api.getConsolidatedMarks(
          department: widget.department,
          semester: widget.semester,
          section: widget.section,
        ),
      ]);

      setState(() {
        _assessments = [
          ...(futures[0] as List<AssessmentModel>),
          ...(futures[1] as List<AssessmentModel>),
          ...(futures[2] as List<AssessmentModel>),
        ];
        _consolidatedReport = futures[3] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load class internal computations: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _actionVerifyIncharge(bool accept, {String? comment}) async {
    setState(() => _actioning = true);
    try {
      final futures = _assessments.map(
        (asm) => _api.verifyClassIncharge(
          assessmentId: asm.id,
          accept: accept,
          comment: comment,
        ),
      );
      await Future.wait(futures);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'All internal marks verified and forwarded to HOD!'
                  : 'Assessments opened back to subject faculty with remarks.',
            ),
            backgroundColor:
                accept ? TeacherColors.success : TeacherColors.warning,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification execution failed.'),
            backgroundColor: TeacherColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  // Gets the worst status among assessments to show global status
  String _getGlobalStatus() {
    if (_assessments.isEmpty) return 'DRAFT';
    bool allVerified = true;
    bool anySubmitted = false;
    for (var a in _assessments) {
      if (a.status == 'DRAFT') {
        allVerified = false;
      } else if (a.status == 'SUBMITTED') {
        allVerified = false;
        anySubmitted = true;
      }
    }
    if (allVerified && _assessments.first.status.contains('VERIFIED') ||
        _assessments.first.status.contains('APPROVED'))
      return _assessments.first.status;
    if (anySubmitted) return 'SUBMITTED';
    return 'DRAFT';
  }

  Color _getStatusColor(String status) {
    if (status.contains('APPROVED') || status.contains('PUBLISHED'))
      return TeacherColors.info;
    if (status.contains('VERIFIED')) return TeacherColors.brass;
    if (status == 'SUBMITTED') return TeacherColors.success;
    return TeacherColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> studentsReport =
        _consolidatedReport != null
            ? _consolidatedReport!['students'] as List
            : [];

    final Set<String> subjectCodes = {};
    final List<Map<String, String>> subjects = [];
    for (var student in studentsReport) {
      final subList = student['subjectMarks'] as List? ?? [];
      for (var sub in subList) {
        final code = sub['subjectCode']?.toString() ?? '';
        final name = sub['subjectName']?.toString() ?? '';
        if (code.isNotEmpty && !subjectCodes.contains(code)) {
          subjectCodes.add(code);
          subjects.add({'code': code, 'name': name});
        }
      }
    }

    // Evaluate if all tests are submitted by teachers
    bool allSubmittedByFaculty = true;
    final Map<String, int> subCounts = {};
    for (var asm in _assessments) {
      if (asm.status == 'DRAFT') allSubmittedByFaculty = false;
      final code = asm.subject?.code ?? 'UNK';
      subCounts[code] = (subCounts[code] ?? 0) + 1;
    }
    if (_assessments.isEmpty) allSubmittedByFaculty = false;

    String currentGlobalStatus = _getGlobalStatus();
    bool isInchargeVerified =
        currentGlobalStatus == 'CLASS_INCHARGE_VERIFIED' ||
        currentGlobalStatus == 'HOD_VERIFIED' ||
        currentGlobalStatus == 'DEAN_APPROVED';

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        title: Text(
          'Internal Marks Verification',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child:
            _loading
                ? const _InchargeSkeleton()
                : _error.isNotEmpty
                ? _buildErrorView()
                : Column(
                  children: [
                    _buildTopPanel(
                      currentGlobalStatus,
                      studentsReport.length,
                      allSubmittedByFaculty,
                    ),
                    Expanded(
                      child:
                          studentsReport.isEmpty
                              ? _buildEmptyView()
                              : _buildSpreadsheetView(studentsReport, subjects),
                    ),
                    if (!isInchargeVerified && _assessments.isNotEmpty)
                      _buildActionStrip(allSubmittedByFaculty),
                  ],
                ),
      ),
    );
  }

  Widget _buildTopPanel(String status, int studentCount, bool allReady) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ErpColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.department} • Sem ${widget.semester} • Sec ${widget.section}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ErpColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: GoogleFonts.outfit(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Students', studentCount.toString()),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Tests Logged',
                  _assessments.length.toString(),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Readiness',
                  allReady ? 'READY' : 'PENDING',
                  textColor:
                      allReady ? TeacherColors.success : TeacherColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? textColor}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: ErpColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(List<dynamic> studentsReport) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: studentsReport.length,
      itemBuilder: (context, index) {
        final item = studentsReport[index];
        final name = item['studentName']?.toString() ?? 'Unknown Student';
        final roll = item['rollNumber']?.toString() ?? 'N/A';

        // Compute average internal mark out of 20 (assuming 20 is max per subject)
        final subjectMarks = item['subjectMarks'] as List? ?? [];
        double totalInternal = 0.0;
        int subCount = 0;

        for (var sub in subjectMarks) {
          double? finalInt = (sub['finalInternal'] as num?)?.toDouble();
          if (finalInt != null) {
            totalInternal += finalInt;
            subCount++;
          }
        }

        double avgInternal = subCount > 0 ? (totalInternal / subCount) : 0.0;
        bool isGood =
            avgInternal >= 10.0; // Assume 10/20 is passing for internal

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: ErpColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            title: Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ErpColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Roll: $roll',
                style: GoogleFonts.outfit(
                  color: ErpColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Avg: ${avgInternal.toStringAsFixed(1)}/20',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ErpColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (isGood
                            ? TeacherColors.success
                            : TeacherColors.danger)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isGood ? 'GOOD' : 'NEEDS ATTENTION',
                    style: GoogleFonts.outfit(
                      color:
                          isGood ? TeacherColors.success : TeacherColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionStrip(bool allSubmittedByFaculty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ErpColors.bgCard,
        border: Border(top: BorderSide(color: ErpColors.border)),
      ),
      child: Column(
        children: [
          if (!allSubmittedByFaculty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cannot submit to HOD until ALL faculty register their scores.",
                        style: GoogleFonts.outfit(
                          color: ErpColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeacherColors.danger,
                    side: const BorderSide(color: TeacherColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed:
                      _actioning
                          ? null
                          : () async {
                            final remarkController = TextEditingController();
                            final send = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    backgroundColor: ErpColors.bgCard,
                                    title: Text(
                                      "Send Remark & Reject",
                                      style: GoogleFonts.outfit(
                                        color: ErpColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: TextField(
                                      controller: remarkController,
                                      style: const TextStyle(
                                        color: ErpColors.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText:
                                            "Enter reason for rejection...",
                                        hintStyle: TextStyle(
                                          color: ErpColors.textMuted,
                                        ),
                                        filled: true,
                                        fillColor: ErpColors.bg,
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: ErpColors.border,
                                          ),
                                        ),
                                      ),
                                      maxLines: 3,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: ErpColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: TeacherColors.danger,
                                        ),
                                        onPressed: () {
                                          if (remarkController.text
                                              .trim()
                                              .isEmpty)
                                            return;
                                          Navigator.pop(ctx, true);
                                        },
                                        child: const Text(
                                          "Reject",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                            if (send == true) {
                              _actionVerifyIncharge(
                                false,
                                comment: remarkController.text.trim(),
                              );
                            }
                          },
                  child: Text(
                    'Reject / Sub. Remark',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed:
                      _actioning || !allSubmittedByFaculty
                          ? null
                          : () => _actionVerifyIncharge(true),
                  child: Text(
                    'Submit Class Audit to HOD',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: ErpColors.border,
          ),
          const SizedBox(height: 16),
          Text(
            'No computation available',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ErpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Text(_error, style: GoogleFonts.outfit(color: Colors.redAccent)),
    );
  }

  Widget _buildSpreadsheetView(
    List<dynamic> studentsReport,
    List<Map<String, String>> subjects,
  ) {
    if (subjects.isEmpty) {
      return const Center(child: Text("No subject data available."));
    }

    if (_selectedSubjectCode == null ||
        !subjects.any((s) => s['code'] == _selectedSubjectCode)) {
      _selectedSubjectCode = subjects.first['code'];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ErpColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ErpColors.primary.withOpacity(0.03),
            child: Row(
              children: [
                const Icon(
                  Icons.subject,
                  color: ErpColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubjectCode,
                      isExpanded: true,
                      dropdownColor: ErpColors.bgCard,
                      iconEnabledColor: ErpColors.textSecondary,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ErpColors.textPrimary,
                      ),
                      items:
                          subjects.map((sub) {
                            return DropdownMenuItem<String>(
                              value: sub['code'],
                              child: Text("${sub['code']} - ${sub['name']}"),
                            );
                          }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSubjectCode = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ErpColors.border),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                dataTableTheme: DataTableThemeData(
                  headingTextStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: ErpColors.textPrimary,
                  ),
                  dataTextStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    color: ErpColors.textSecondary,
                  ),
                ),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowColor: MaterialStateProperty.all(
                          ErpColors.primary.withOpacity(0.05),
                        ),
                        dataRowHeight: 48,
                        headingRowHeight: 48,
                        columns: [
                          DataColumn(
                            label: Text(
                              'Roll No',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Student Name',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ...List.generate(
                            6,
                            (i) => DataColumn(
                              label: Text(
                                'DT ${i + 1}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I1 Writ',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I1 Ass',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I1 Qz',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I1 Sem',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I1 Wtd',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I2 Writ',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I2 Ass',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I2 Qz',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I2 Sem',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'I2 Wtd',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Model 1',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Model 2',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Final Int',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            studentsReport.map((student) {
                              final roll =
                                  student['rollNumber']?.toString() ?? 'N/A';
                              final name =
                                  student['studentName']?.toString() ??
                                  'Unknown';

                              final subList =
                                  student['subjectMarks'] as List? ?? [];
                              final matchingSub = subList.firstWhere(
                                (sub) =>
                                    sub['subjectCode']?.toString() ==
                                    _selectedSubjectCode,
                                orElse: () => null,
                              );

                              if (matchingSub == null) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        roll,
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...List.generate(
                                      6,
                                      (_) => const DataCell(Text('-')),
                                    ),
                                    ...List.generate(
                                      5,
                                      (_) => const DataCell(Text('-')),
                                    ),
                                    ...List.generate(
                                      5,
                                      (_) => const DataCell(Text('-')),
                                    ),
                                    ...List.generate(
                                      2,
                                      (_) => const DataCell(Text('-')),
                                    ),
                                    const DataCell(Text('-')),
                                  ],
                                );
                              }

                              final dtMap =
                                  matchingSub['dailyTests'] as Map? ?? {};
                              final iat1Map = matchingSub['iat1'] as Map? ?? {};
                              final iat1Weighted =
                                  matchingSub['iat1Internal'] ?? 0.0;
                              final iat2Map = matchingSub['iat2'] as Map? ?? {};
                              final iat2Weighted =
                                  matchingSub['iat2Internal'] ?? 0.0;
                              final modelMap =
                                  matchingSub['modelExams'] as Map? ?? {};
                              final finalInternal =
                                  matchingSub['finalInternal'] ?? 0.0;

                              String formatMark(dynamic m) {
                                if (m == null) return '-';
                                if (m is num) return m.toStringAsFixed(0);
                                return m.toString();
                              }

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      roll,
                                      style: GoogleFonts.outfit(fontSize: 12),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(
                                    6,
                                    (i) => DataCell(
                                      Center(
                                        child: Text(
                                          formatMark(
                                            dtMap['Daily Test ${i + 1}'],
                                          ),
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat1Map['WRITTEN']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat1Map['ASSIGNMENT']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat1Map['QUIZ']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat1Map['SEMINAR']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat1Weighted),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: ErpColors.bgCard,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat2Map['WRITTEN']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat2Map['ASSIGNMENT']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat2Map['QUIZ']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat2Map['SEMINAR']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(iat2Weighted),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: ErpColors.bgCard,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(modelMap['Model Exam 1']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(modelMap['Model Exam 2']),
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        formatMark(finalInternal),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: TeacherColors.brass,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InchargeSkeleton extends StatelessWidget {
  const _InchargeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 120, radius: 16),
        SizedBox(height: 16),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
