import 'package:erp_saf/services/notice_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notice.dart' hide LibraryBook;
import '../models/subject_model.dart';
import '../services/api_service.dart';
import '../services/student_service.dart';
import '../core/design_system.dart';
import '../models/fee_model.dart';
import '../models/LibraryBookModel.dart';
import '../models/student.dart';
import 'attendance_screen.dart';
import 'results_screen.dart';
import 'fees_screen.dart';
import 'timetable_screen.dart';
import 'library_screen.dart';
import 'notices_screen.dart';
import 'events_screen.dart';
import 'id_card_screen.dart';
import '../progress/screens/progress_card_screen.dart';
import '../transport/screens/student_transport_dashboard.dart';
import 'messages/message_inbox_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String? studentId;
  const DashboardScreen({super.key, this.studentId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StudentService _api = StudentService();
  final NoticeService _noticeService = NoticeService();

  Student? _student;
  List<Notice> _notices = [];
  List<SubjectModel>? _subjects;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final studentId = widget.studentId ?? 'STU25';
      final results = await Future.wait([
        _api.getStudent(studentId),
        _noticeService
            .getNotices('STUDENT', 'ALL')
            .catchError((_) => <Notice>[]),
        ApiService.getSubjects().catchError((_) => <SubjectModel>[]),
        feeService.getFees(studentId).catchError((_) => <Fee>[]),
        libraryService.getBooks(studentId).catchError((_) => <LibraryBook>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _student = results[0] as Student;
        _notices = results[1] as List<Notice>;
        _subjects = results[2] as List<SubjectModel>;
        feeItems = results[3] as dynamic;
        issuedBooks = results[4] as dynamic;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  double get _avgAttendance {
    if (_subjects == null || _subjects!.isEmpty) return 0;
    return _subjects!.map((s) => s.attendancePercent).reduce((a, b) => a + b) /
        _subjects!.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _DashboardSkeleton();
    if (_error || _student == null) {
      return Scaffold(
        backgroundColor: ErpColors.bg,
        body: ErpErrorState(
          message: 'Could not load your profile.',
          onRetry: _load,
        ),
      );
    }

    final student = _student!;

    return Scaffold(
      backgroundColor: ErpColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: ErpColors.primary,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StudentHeader(
                  student: student,
                  onNotificationTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => NoticesScreen(
                              studentId: widget.studentId ?? 'STU25',
                            ),
                      ),
                    );
                  },
                  onMessageTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MessageInboxScreen(
                              userId: student.id,
                              userName: student.name,
                              userRole: 'STUDENT',
                              department: student.department,
                            ),
                      ),
                    );
                  },
                ),
              ),

              // ── Stats ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI row
                      Row(
                        children: [
                          Expanded(
                            child: ErpStatCard(
                              label: 'Overall Attendance',
                              value: '${_avgAttendance.toStringAsFixed(0)}%',
                              icon: Icons.fact_check_outlined,
                              color:
                                  _avgAttendance < 75
                                      ? ErpColors.danger
                                      : ErpColors.attendance,
                              surfaceColor:
                                  _avgAttendance < 75
                                      ? ErpColors.dangerSurface
                                      : ErpColors.attendanceSurface,
                              badge:
                                  _avgAttendance < 75
                                      ? const ErpStatusBadge(
                                        label: 'Low',
                                        type: ErpBadgeType.danger,
                                        compact: true,
                                      )
                                      : null,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AttendanceScreen(),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErpStatCard(
                              label: 'CGPA',
                              value: student.cgpa.toStringAsFixed(2),
                              icon: Icons.emoji_events_outlined,
                              color: ErpColors.results,
                              surfaceColor: ErpColors.resultsSurface,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ResultsScreen(
                                            studentId: widget.studentId,
                                          ),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErpStatCard(
                              label: 'Fee Dues',
                              value:
                                  '₹${feeItems.where((f) => !f.isPaid).fold<double>(0, (a, b) => a + b.amount).toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_outlined,
                              color: ErpColors.fees,
                              surfaceColor: ErpColors.feesSurface,
                              badge:
                                  feeItems.any((f) => !f.isPaid)
                                      ? ErpStatusBadge(
                                        label:
                                            '${feeItems.where((f) => !f.isPaid).length}',
                                        type: ErpBadgeType.warning,
                                        compact: true,
                                      )
                                      : null,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => FeesScreen(
                                            studentId: widget.studentId,
                                          ),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Modules ───────────────────────────────────────────
                      const ErpSectionHeader(
                        title: 'Modules',
                        subtitle: 'Quick access to your academic tools',
                      ),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.90,
                        children: [
                          ErpModuleCard(
                            label: 'Attendance',
                            icon: Icons.fact_check_outlined,
                            color: ErpColors.attendance,
                            surfaceColor: ErpColors.attendanceSurface,
                            badge: _avgAttendance < 75 ? '!' : null,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AttendanceScreen(),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Results',
                            icon: Icons.workspace_premium_outlined,
                            color: ErpColors.results,
                            surfaceColor: ErpColors.resultsSurface,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ResultsScreen(
                                          studentId: widget.studentId,
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Fees',
                            icon: Icons.account_balance_wallet_outlined,
                            color: ErpColors.fees,
                            surfaceColor: ErpColors.feesSurface,
                            badge:
                                feeItems.any((f) => !f.isPaid)
                                    ? '${feeItems.where((f) => !f.isPaid).length}'
                                    : null,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FeesScreen(
                                          studentId: widget.studentId,
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Timetable',
                            icon: Icons.calendar_month_outlined,
                            color: ErpColors.timetable,
                            surfaceColor: ErpColors.timetableSurface,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TimetableScreen(),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Library',
                            icon: Icons.menu_book_outlined,
                            color: ErpColors.library,
                            surfaceColor: ErpColors.librarySurface,
                            badge:
                                issuedBooks.any((b) => b.isOverdue)
                                    ? '!'
                                    : null,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => LibraryScreen(
                                          studentId: widget.studentId,
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Progress',
                            icon: Icons.bar_chart_outlined,
                            color: ErpColors.assessment,
                            surfaceColor: ErpColors.assessmentSurface,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ProgressCardScreen(
                                          studentId:
                                              widget.studentId ?? 'STU25',
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Notices',
                            icon: Icons.campaign_outlined,
                            color: ErpColors.warning,
                            surfaceColor: ErpColors.warningSurface,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => NoticesScreen(
                                          studentId:
                                              widget.studentId ?? 'STU25',
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Events',
                            icon: Icons.celebration_outlined,
                            color: ErpColors.accent,
                            surfaceColor: ErpColors.accentLight,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EventsScreen(
                                          studentId:
                                              widget.studentId ?? 'STU25',
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'ID Card',
                            icon: Icons.badge_outlined,
                            color: ErpColors.info,
                            surfaceColor: ErpColors.infoSurface,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StudentIdCardScreen(
                                          studentId: student.id,
                                        ),
                                  ),
                                ),
                          ),
                          ErpModuleCard(
                            label: 'Transport',
                            icon: Icons.directions_bus_outlined,
                            color: ErpColors.transport,
                            surfaceColor: ErpColors.transportSurface,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StudentTransportDashboardScreen(
                                          studentId: student.id,
                                        ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Notices ───────────────────────────────────────────
                      ErpSectionHeader(
                        title: 'Recent Notices',
                        actionLabel: 'View all',
                        onAction:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => NoticesScreen(
                                      studentId: widget.studentId ?? 'STU25',
                                    ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Notice List ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver:
                    _notices.isEmpty
                        ? const SliverToBoxAdapter(
                          child: ErpEmptyState(
                            message: 'No recent notices',
                            subtitle: 'New notices from admin will appear here',
                            icon: Icons.campaign_outlined,
                          ),
                        )
                        : SliverList.separated(
                          itemCount: _notices.length > 3 ? 3 : _notices.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
                          itemBuilder:
                              (_, i) => _NoticeCard(notice: _notices[i]),
                        ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Student Header ─────────────────────────────────────────────
class _StudentHeader extends StatelessWidget {
  final Student student;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;

  const _StudentHeader({
    required this.student,
    this.onNotificationTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = student.name.split(' ').map((e) => e[0]).take(2).join();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        color: ErpColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ErpRadius.xl),
          bottomRight: Radius.circular(ErpRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ErpRadius.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: ErpColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_greeting()},',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      student.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${student.rollNumber} · ${student.semester}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.mail_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: onMessageTap,
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                onPressed: onNotificationTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick info chips
          Wrap(
            spacing: 8,
            children: [
              _InfoChip(label: student.department),
              _InfoChip(label: student.year),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ErpRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Notice Card ─────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final Notice notice;
  const _NoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return ErpCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: notice.isImportant ? ErpColors.danger : ErpColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ErpTypography.titleSmall,
                      ),
                    ),
                    if (notice.isImportant)
                      const ErpStatusBadge(
                        label: 'Important',
                        type: ErpBadgeType.danger,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notice.date, style: ErpTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: ErpColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Skeleton ──────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 140,
              color: ErpColors.primary,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const ErpSkeleton(width: 50, height: 50, radius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        ErpSkeleton(width: 80, height: 12),
                        SizedBox(height: 8),
                        ErpSkeleton(height: 18),
                        SizedBox(height: 6),
                        ErpSkeleton(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                            child: const ErpSkeletonCard(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const ErpSkeleton(width: 100, height: 16),
                    const SizedBox(height: 14),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                        children: List.generate(
                          9,
                          (_) => const ErpSkeletonCard(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
