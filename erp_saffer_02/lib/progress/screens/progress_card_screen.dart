import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/progress_card_model.dart';
import '../services/progress_card_service.dart';

/// Official Student Progress Card Screen.
///
/// Shows ONLY verified/finalized data:
///  - Internal marks: only DEAN_APPROVED assessments
///  - Semester result: only PUBLISHED Exam Cell result
///  - Performance categories: from backend DB config (never hard-coded)
class ProgressCardScreen extends StatefulWidget {
  final String studentId;
  const ProgressCardScreen({super.key, required this.studentId});

  @override
  State<ProgressCardScreen> createState() => _ProgressCardScreenState();
}

class _ProgressCardScreenState extends State<ProgressCardScreen>
    with SingleTickerProviderStateMixin {
  final ProgressCardService _service = ProgressCardService();

  String _normalizeDept(String dept) {
    String d = dept.toLowerCase().trim();
    if (d.contains('computer') || d == 'cs' || d == 'cse') return 'CSE';
    if (d.contains('electronics') || d == 'ece') return 'ECE';
    if (d.contains('electrical') || d == 'eee') return 'EEE';
    if (d.contains('mechanical') || d == 'mech') return 'MECH';
    if (d.contains('civil')) return 'CIVIL';
    if (d.contains('information') || d == 'it') return 'IT';
    if (d.contains('artificial') || d == 'ai' || d == 'aids') return 'AI&DS';
    return dept.trim().toUpperCase();
  }

  String _normalizeYear(String yearStr) {
    String y = yearStr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (y == '1' || y == '1st' || y == 'first' || y == 'i') return '1';
    if (y == '2' || y == '2nd' || y == 'second' || y == 'ii') return '2';
    if (y == '3' || y == '3rd' || y == 'third' || y == 'iii') return '3';
    if (y == '4' || y == '4th' || y == 'fourth' || y == 'iv') return '4';
    return yearStr.trim();
  }

  String _selectedSem = 'S5';
  final List<String> _semesters = [
    'S1',
    'S2',
    'S3',
    'S4',
    'S5',
    'S6',
    'S7',
    'S8',
  ];

  bool _isLoading = false;
  ProgressCardModel? _card;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadCard();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchProgressCard(
        studentId: widget.studentId,
        semester: _selectedSem,
      );
      setState(() {
        _card = data;
        _isLoading = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: Text(
          'Academic Progress Card',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildSemSelector(),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              )
              : _error != null
              ? _buildError()
              : _card == null
              ? const Center(
                child: Text('No data', style: TextStyle(color: Colors.white38)),
              )
              : FadeTransition(opacity: _fadeAnim, child: _buildBody()),
    );
  }

  // ─── Semester Selector ────────────────────────────────────────────────────

  Widget _buildSemSelector() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _semesters.length,
        itemBuilder: (_, i) {
          final sem = _semesters[i];
          final sel = _selectedSem == sem;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedSem = sem);
                _loadCard();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient:
                      sel
                          ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3A86FF)],
                          )
                          : null,
                  color: sel ? null : const Color(0xFF252535),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sem,
                  style: GoogleFonts.outfit(
                    color: sel ? Colors.white : Colors.white54,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Main Body ────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final card = _card!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(card),
          const SizedBox(height: 16),
          _buildStudentHeader(card.studentInfo),
          const SizedBox(height: 16),
          _buildGpaRow(card.sgpa, card.cgpa, card.semesterResultStatus),
          const SizedBox(height: 20),
          _buildVerificationTimeline(card.verificationTrail),
          const SizedBox(height: 20),
          _buildPerformanceOverviewCard(card.performanceOverview),
          const SizedBox(height: 20),
          _buildSectionTitle('📚 Subject-wise Internal Assessment'),
          const SizedBox(height: 10),
          ...card.internalPerformance.map(_buildSubjectCard),
          if (card.overallProgress.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('📈 Semester SGPA Trend'),
            const SizedBox(height: 10),
            _buildSemesterTrend(card.overallProgress),
          ],
          if (card.remarks.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('💬 Remarks'),
            const SizedBox(height: 10),
            ...card.remarks.map(_buildRemarkTile),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Status Banner ────────────────────────────────────────────────────────

  Widget _buildStatusBanner(ProgressCardModel card) {
    final status = card.overallInternalStatus;
    final isFinalized = card.isFinalized;
    final isPublished = card.isResultPublished;

    Color bg;
    String msg;
    IconData icon;

    if (isFinalized && isPublished) {
      bg = const Color(0xFF1A3A1A);
      msg = '✅ Official Progress Card — All data finalized & published';
      icon = Icons.verified;
    } else if (isFinalized) {
      bg = const Color(0xFF1A2A3A);
      msg =
          '🔒 Internal marks finalized. Awaiting semester result publication.';
      icon = Icons.lock_outline;
    } else {
      bg = const Color(0xFF2A2010);
      msg = '⏳ Pending: $status — Mark verification in progress';
      icon = Icons.hourglass_top_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Student Header ───────────────────────────────────────────────────────

  Widget _buildStudentHeader(Map<String, dynamic> info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E35), Color(0xFF252540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3A86FF)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ACADEMIC PROGRESS CARD',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6C63FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 8),
          Text(
            info['name'] ?? 'N/A',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow('Reg No', info['rollNumber'] ?? 'N/A'),
          _infoRow('Dept', _normalizeDept(info['department'] ?? 'N/A')),
          _infoRow('Semester', info['semester'] ?? _selectedSem),
          _infoRow('Section', info['section'] ?? 'N/A'),
          _infoRow('Year', _normalizeYear(info['year']?.toString() ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
          ),
          Text(
            value,
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

  // ─── GPA Row ──────────────────────────────────────────────────────────────

  Widget _buildGpaRow(double sgpa, double cgpa, String semStatus) {
    return Row(
      children: [
        Expanded(
          child: _gpaCard(
            'Term SGPA',
            sgpa > 0 ? sgpa.toStringAsFixed(2) : 'N/A',
            const Color(0xFF6C63FF),
            semStatus,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _gpaCard(
            'Cumulative CGPA',
            cgpa > 0 ? cgpa.toStringAsFixed(2) : 'N/A',
            const Color(0xFF3A86FF),
            'ALL SEMESTERS',
          ),
        ),
      ],
    );
  }

  Widget _gpaCard(String label, String value, Color accent, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: accent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub.toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white24,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Verification Timeline ────────────────────────────────────────────────

  Widget _buildVerificationTimeline(Map<String, dynamic> trail) {
    final total = trail['totalAssessments'] ?? 0;
    final submitted = trail['facultySubmitted'] ?? 0;
    final incharge = trail['classInchargeVerified'] ?? 0;
    final hod = trail['hodApproved'] ?? 0;
    final dean = trail['deanFinalized'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Status',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _timelineStep(
            'Faculty Submitted',
            '$submitted/$total',
            submitted == total,
          ),
          _timelineStep(
            'Class Incharge Verified',
            '$incharge/$total',
            incharge == total,
          ),
          _timelineStep('HOD Approved', '$hod/$total', hod == total),
          _timelineStep(
            'Dean Finalized',
            '$dean/$total',
            dean == total,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep(
    String label,
    String prog,
    bool done, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFF00D68F) : const Color(0xFF3A3A55),
              ),
              child: Icon(
                done ? Icons.check : Icons.radio_button_unchecked,
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color:
                    done
                        ? const Color(0xFF00D68F).withOpacity(0.4)
                        : const Color(0xFF3A3A55),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: done ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                prog,
                style: GoogleFonts.outfit(
                  color: done ? const Color(0xFF00D68F) : Colors.white30,
                  fontSize: 11,
                ),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Performance Overview ─────────────────────────────────────────────────

  Widget _buildPerformanceOverviewCard(Map<String, dynamic> ov) {
    final label = ov['performanceDisplay'] ?? 'Insufficient Data';
    final avg = (ov['averageInternal'] as num?)?.toDouble() ?? 0.0;
    final count = ov['subjectCount'] ?? 0;
    final catLabel = ov['performanceLabel'] ?? '';

    Color accent = _performanceColor(catLabel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.12), const Color(0xFF1E1E35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Overview',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Avg Internal: ${avg.toStringAsFixed(1)} • $count subjects',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avg.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _performanceColor(String label) {
    switch (label.toUpperCase()) {
      case 'EXCELLENT':
        return const Color(0xFF00D68F);
      case 'VERY_GOOD':
        return const Color(0xFF3A86FF);
      case 'GOOD':
        return const Color(0xFF6C63FF);
      case 'AVERAGE':
        return Colors.orangeAccent;
      case 'AT_RISK':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  // ─── Subject Card ─────────────────────────────────────────────────────────

  Widget _buildSubjectCard(SubjectInternalModel sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF6C63FF),
          collapsedIconColor: Colors.white38,
          title: Text(
            sub.subjectName,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '${sub.subjectCode}  |  Credits: ${sub.credits}',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              _statusChip(sub.weeklyTestStatus),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white.withOpacity(0.06)),
                  const SizedBox(height: 8),

                  // Final internal mark
                  Row(
                    children: [
                      _blockDetail(
                        'Final Internal Mark',
                        '${sub.finalInternal} / 50',
                        const Color(0xFFFFBE0B),
                      ),
                      const SizedBox(width: 24),
                      _blockDetail(
                        'Consolidated',
                        sub.consolidatedInternal.toStringAsFixed(1),
                        Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Daily tests
                  Text(
                    'Daily Tests (Max 20 each)',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDailyTestsRow(sub.dailyTests),
                  const SizedBox(height: 14),

                  // IAT breakdown
                  _buildIatCard(
                    'IAT-1',
                    sub.iat1,
                    sub.iat1Internal,
                    sub.iat1Status,
                  ),
                  const SizedBox(height: 10),
                  _buildIatCard(
                    'IAT-2',
                    sub.iat2,
                    sub.iat2Internal,
                    sub.iat2Status,
                  ),
                  _buildSubjectSemesterResult(sub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSemesterResult(SubjectInternalModel sub) {
    final bool isPublished = _card?.isResultPublished ?? false;
    final Map<String, dynamic> semResult = _card?.semesterResult ?? {};
    final String status = semResult['status']?.toString() ?? 'NOT_PUBLISHED';

    if (!isPublished || status != 'PUBLISHED') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white30, size: 14),
            const SizedBox(width: 8),
            Text(
              'Semester result has not been published yet.',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final List subjects = semResult['subjects'] as List? ?? [];
    final subjectMatch = subjects.firstWhere(
      (element) => element['subjectCode'] == sub.subjectCode,
      orElse: () => null,
    );

    if (subjectMatch == null) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white30, size: 14),
            const SizedBox(width: 8),
            Text(
              'Semester result has not been published yet.',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final grade = subjectMatch['grade']?.toString() ?? 'RA';
    final double gp = (subjectMatch['gradePoint'] as num?)?.toDouble() ?? 0.0;
    final int credits =
        (subjectMatch['credits'] as num?)?.toInt() ?? sub.credits;
    final String resStatus =
        subjectMatch['resultStatus']?.toString().toUpperCase() ?? 'FAIL';
    final bool isPassed =
        resStatus == 'PASS' ||
        !(grade == 'U' || grade == 'RA' || grade == 'UA' || grade == 'W');
    final Color gradeColor =
        isPassed ? const Color(0xFF00D68F) : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: gradeColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                color: Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'OFFICIAL SEMESTER RESULT',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniDetailBlock('Credits', '$credits'),
              _miniDetailBlock('Grade', grade, valColor: gradeColor),
              _miniDetailBlock('GP', gp.toStringAsFixed(0)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPassed ? 'PASS' : 'FAIL',
                  style: GoogleFonts.outfit(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniDetailBlock(String label, String val, {Color? valColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 8),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.outfit(
            color: valColor ?? Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: GoogleFonts.outfit(
          color: c,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'DEAN_APPROVED':
        return const Color(0xFF00D68F);
      case 'HOD_VERIFIED':
        return const Color(0xFF3A86FF);
      case 'CLASS_INCHARGE_VERIFIED':
        return const Color(0xFF6C63FF);
      case 'SUBMITTED':
        return Colors.orangeAccent;
      case 'DRAFT':
        return Colors.white30;
      default:
        return Colors.white24;
    }
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'DEAN_APPROVED':
        return 'FINALIZED';
      case 'HOD_VERIFIED':
        return 'HOD APPROVED';
      case 'CLASS_INCHARGE_VERIFIED':
        return 'INCHARGE VERIFIED';
      case 'SUBMITTED':
        return 'SUBMITTED';
      case 'DRAFT':
        return 'DRAFT';
      default:
        return s;
    }
  }

  Widget _blockDetail(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTestsRow(Map<String, dynamic> tests) {
    return Row(
      children: List.generate(6, (i) {
        final key = 'Daily Test ${i + 1}';
        final val = tests[key];
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DT${i + 1}',
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 8),
                ),
                const SizedBox(height: 2),
                Text(
                  val?.toString() ?? '—',
                  style: GoogleFonts.outfit(
                    color: val != null ? Colors.white70 : Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIatCard(
    String title,
    Map<String, dynamic> data,
    double weighted,
    String status,
  ) {
    String fmt(String key, String max) =>
        data[key] != null ? '${data[key]}/$max' : '—';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    'CIE: ${weighted.toStringAsFixed(1)}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFFBE0B),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _statusChip(status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniComp('Written', fmt('WRITTEN', '50')),
              _miniComp('Assign', fmt('ASSIGNMENT', '10')),
              _miniComp('Seminar', fmt('SEMINAR', '10')),
              _miniComp('Quiz', fmt('QUIZ', '10')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniComp(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Semester Trend ───────────────────────────────────────────────────────

  Widget _buildSemesterTrend(List<SemesterOverviewModel> progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            progress.map((item) {
              final color =
                  item.sgpa >= 8.5
                      ? const Color(0xFF00D68F)
                      : item.sgpa >= 7.0
                      ? const Color(0xFF3A86FF)
                      : item.sgpa >= 6.0
                      ? const Color(0xFF6C63FF)
                      : Colors.orangeAccent;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.semesterName,
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      item.sgpa.toStringAsFixed(2),
                      style: GoogleFonts.outfit(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // ─── Remarks ─────────────────────────────────────────────────────────────

  Widget _buildRemarkTile(RemarkModel rem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rem.remarkByRole,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6C63FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rem.remarkByName ?? rem.remarkBy,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rem.remarkText,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load progress card',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadCard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
