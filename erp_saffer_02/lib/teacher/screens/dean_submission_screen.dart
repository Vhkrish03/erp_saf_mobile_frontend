import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/assessment_model.dart';
import '../services/assessment_service.dart';
import '../theme/teacher_theme.dart';

class DeanSubmissionScreen extends StatefulWidget {
  final String department;
  final String semester;
  final String section;

  const DeanSubmissionScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.section,
  });

  @override
  State<DeanSubmissionScreen> createState() => _DeanSubmissionScreenState();
}

class _DeanSubmissionScreenState extends State<DeanSubmissionScreen> {
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
      final weekly = await _api.getWeeklyAssessments(
        department: widget.department,
        semester: widget.semester,
        section: widget.section,
      );
      final iats = await _api.getIatAssessments(
        department: widget.department,
        semester: widget.semester,
        section: widget.section,
      );
      final model = await _api.getModelAssessments(
        department: widget.department,
        semester: widget.semester,
        section: widget.section,
      );

      final report = await _api.getConsolidatedMarks(
        department: widget.department,
        semester: widget.semester,
        section: widget.section,
      );

      setState(() {
        _assessments = [...weekly, ...iats, ...model];
        _consolidatedReport = report;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load Dean report computations.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _actionApproveDean() async {
    setState(() => _actioning = true);
    try {
      for (var asm in _assessments) {
        await _api.submitToDean(assessmentId: asm.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks Locked and Published officially!'),
            backgroundColor: TeacherColors.navy,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lock execution failed.'),
            backgroundColor: TeacherColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  String _getGlobalStatus() {
    if (_assessments.isEmpty) return 'DRAFT';
    return _assessments.first.status;
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

    String currentGlobalStatus = _getGlobalStatus();
    bool isHodVerified =
        currentGlobalStatus == 'HOD_VERIFIED' ||
        currentGlobalStatus == 'DEAN_APPROVED';

    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        title: Text(
          'Dean Lock & Publish',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: TeacherColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: TeacherColors.navy),
                )
                : _error.isNotEmpty
                ? _buildErrorView()
                : Column(
                  children: [
                    _buildTopPanel(
                      currentGlobalStatus,
                      studentsReport.length,
                      isHodVerified,
                    ),
                    if (studentsReport.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      !_showSpreadsheet
                                          ? TeacherColors.navy
                                          : Colors.white,
                                  foregroundColor:
                                      !_showSpreadsheet
                                          ? Colors.white
                                          : TeacherColors.navy,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: TeacherColors.navy,
                                    ),
                                  ),
                                ),
                                onPressed:
                                    () => setState(
                                      () => _showSpreadsheet = false,
                                    ),
                                icon: const Icon(Icons.grid_view, size: 14),
                                label: Text(
                                  'Card View',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _showSpreadsheet
                                          ? TeacherColors.navy
                                          : Colors.white,
                                  foregroundColor:
                                      _showSpreadsheet
                                          ? Colors.white
                                          : TeacherColors.navy,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: TeacherColors.navy,
                                    ),
                                  ),
                                ),
                                onPressed:
                                    () =>
                                        setState(() => _showSpreadsheet = true),
                                icon: const Icon(Icons.table_chart, size: 14),
                                label: Text(
                                  'Audit Spreadsheet',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          studentsReport.isEmpty
                              ? _buildEmptyView()
                              : (_showSpreadsheet
                                  ? _buildSpreadsheetView(
                                    studentsReport,
                                    subjects,
                                  )
                                  : _buildStudentsList(studentsReport)),
                    ),
                    if (currentGlobalStatus == 'HOD_VERIFIED')
                      _buildActionStrip(),
                  ],
                ),
      ),
    );
  }

  Widget _buildTopPanel(String status, int studentCount, bool isHodVerified) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: TeacherDecorations.navyCard(radius: 16),
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
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Students', studentCount.toString()),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Assessments',
                  _assessments.length.toString(),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'HOD Status',
                  isHodVerified ? 'VERIFIED' : 'PENDING',
                  textColor:
                      isHodVerified
                          ? TeacherColors.success
                          : TeacherColors.danger,
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
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60),
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
        bool isGood = avgInternal >= 10.0;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
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
                color: TeacherColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Roll: $roll',
                style: GoogleFonts.outfit(color: Colors.black54, fontSize: 13),
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
                    color: TeacherColors.navy,
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

  Widget _buildActionStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: TeacherColors.navy,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _actioning ? null : _actionApproveDean,
        child: Text(
          'LOCK & PUBLISH MARKS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
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
            color: Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No computation available',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: TeacherColors.navy.withOpacity(0.03),
            child: Row(
              children: [
                const Icon(Icons.subject, color: TeacherColors.navy, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubjectCode,
                      isExpanded: true,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: TeacherColors.navy,
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
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: MaterialStateProperty.all(
                        TeacherColors.navy.withOpacity(0.05),
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
                                student['studentName']?.toString() ?? 'Unknown';

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
                                        style: GoogleFonts.outfit(fontSize: 12),
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
                                        color: TeacherColors.navy,
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
                                        color: TeacherColors.navy,
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
        ],
      ),
    );
  }
}
