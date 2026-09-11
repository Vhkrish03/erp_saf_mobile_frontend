import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/exam_cell_model.dart';
import '../exam_admin/services/exam_cell_service.dart';
import '../services/semester_results_service.dart';

class SemesterResultDetailScreen extends StatefulWidget {
  final String studentId;
  final String semesterName;
  final String studentName;
  final String rollNumber;
  final String department;
  final double cumulativeCgpa;
  final String? teacherId;
  final String? hodId;

  const SemesterResultDetailScreen({
    super.key,
    required this.studentId,
    required this.semesterName,
    required this.studentName,
    required this.rollNumber,
    required this.department,
    required this.cumulativeCgpa,
    this.teacherId,
    this.hodId,
  });

  @override
  State<SemesterResultDetailScreen> createState() =>
      _SemesterResultDetailScreenState();
}

class _SemesterResultDetailScreenState extends State<SemesterResultDetailScreen>
    with SingleTickerProviderStateMixin {
  final ExamCellService _cellService = ExamCellService();
  bool _isLoading = true;
  ExamCellResultModel? _result;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _fetchDetail();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ExamCellResultModel? res;
      if (widget.teacherId != null && widget.teacherId!.isNotEmpty) {
        final map = await SemesterResultsService().getTeacherStudentResult(
          studentId: widget.studentId,
          teacherId: widget.teacherId!,
          semester: widget.semesterName,
        );
        res = ExamCellResultModel.fromJson(map);
      } else if (widget.hodId != null && widget.hodId!.isNotEmpty) {
        final map = await SemesterResultsService().getHodStudentResult(
          studentId: widget.studentId,
          hodId: widget.hodId!,
          semester: widget.semesterName,
        );
        res = ExamCellResultModel.fromJson(map);
      } else {
        res = await _cellService.getPublishedResultForSemester(
          widget.studentId,
          widget.semesterName,
        );
      }
      setState(() {
        _result = res;
        _isLoading = false;
      });
      if (res != null) {
        _animCtrl.forward();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        title: Text(
          'Official Semester Result',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              )
              : _error != null
              ? _buildErrorView()
              : _result == null
              ? _buildNotPublishedView()
              : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 20),
                      _buildSubjectsTable(),
                      const SizedBox(height: 20),
                      _buildSemesterSummaryCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildNotPublishedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            color: Colors.orangeAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Semester result has not been published yet.',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later once the Exam Cell publishes the official results.',
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading semester result',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred.',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final r = _result!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2F), Color(0xFF25253F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OFFICIAL SEMESTER RESULT',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF00D68F),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.status,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF00D68F),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.studentName,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _metaRow('Register No', widget.rollNumber),
          _metaRow('Department', widget.department),
          _metaRow('Semester', widget.semesterName),
          _metaRow('Academic Year', r.academicYear),
          _metaRow('Exam Session', r.examSession),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
            ),
          ),
          Text(
            ':   $value',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsTable() {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF6C63FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SUBJECT RESULTS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.subjects.length,
            separatorBuilder:
                (_, __) =>
                    Divider(color: Colors.white.withOpacity(0.04), height: 16),
            itemBuilder: (_, i) {
              final sub = r.subjects[i];
              final isPass =
                  sub.resultStatus?.toUpperCase() == 'PASS' ||
                  !(sub.grade == 'U' ||
                      sub.grade == 'RA' ||
                      sub.grade == 'UA' ||
                      sub.grade == 'W');

              final badgeColor =
                  isPass ? const Color(0xFF00D68F) : Colors.redAccent;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.subjectName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sub.subjectCode}  •  Credits: ${sub.credits}',
                              style: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Grade: ',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                sub.grade ?? 'RA',
                                style: GoogleFonts.outfit(
                                  color:
                                      isPass ? Colors.white : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'GP: ${sub.gradePoint.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPass ? 'PASS' : 'FAIL',
                          style: GoogleFonts.outfit(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSummaryCard() {
    final r = _result!;
    int totalCredits = 0;
    int creditsEarned = 0;
    int passedCount = 0;
    int failedCount = 0;

    for (var sub in r.subjects) {
      totalCredits += sub.credits.toInt();
      final isPass =
          sub.resultStatus?.toUpperCase() == 'PASS' ||
          !(sub.grade == 'U' ||
              sub.grade == 'RA' ||
              sub.grade == 'UA' ||
              sub.grade == 'W');

      if (isPass) {
        creditsEarned += sub.credits.toInt();
        passedCount++;
      } else {
        failedCount++;
      }
    }

    final overallPass = failedCount == 0;
    final statusColor =
        overallPass ? const Color(0xFF00D68F) : Colors.redAccent;
    final statusLabel = overallPass ? 'PASS' : 'FAIL';

    String pubDateStr = 'N/A';
    if (r.publishedAt != null) {
      try {
        DateTime dt = DateTime.parse(r.publishedAt!);
        pubDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        pubDateStr = r.publishedAt!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Color(0xFF00D68F),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SEMESTER SUMMARY',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'SGPA',
                  r.sgpa.toStringAsFixed(2),
                  const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  'CGPA',
                  widget.cumulativeCgpa > 0
                      ? widget.cumulativeCgpa.toStringAsFixed(2)
                      : 'N/A',
                  const Color(0xFF3A86FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          _summaryMetaRow('Total Semester Credits', '$totalCredits'),
          _summaryMetaRow('Credits Earned', '$creditsEarned'),
          _summaryMetaRow('Passed Subjects', '$passedCount'),
          _summaryMetaRow('Failed / Arrears', '$failedCount'),
          _summaryMetaRow('Backlogs', '$failedCount'),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Result Status',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryMetaRow('Published Date', pubDateStr),
          _summaryMetaRow('Published By', 'Exam Cell'),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
