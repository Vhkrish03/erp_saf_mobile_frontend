import 'package:erp_saf/teacher/screens/settings_screen.dart';
import 'package:erp_saf/teacher/screens/students_screen.dart';
import 'package:erp_saf/teacher/services/timetable_service.dart';
import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/Timetable_model.dart';
import 'results_screen.dart';
import 'test_entry_screen.dart';
import '../models/teacher.dart';
import '../services/teacher_service.dart';
import 'attendance_screen.dart';
import 'assignments_screen.dart';
import 'teacher_semester_result_screen.dart';
import '../../screens/messages/message_inbox_screen.dart';
import 'timetable_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'fees_dashboard_screen.dart';
import 'id_card_screen.dart';
import 'event_management_screen.dart';
import '../../screens/notice_management_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String employeeId;
  const TeacherDashboardScreen({super.key, required this.employeeId});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final TeacherService _teacherService = TeacherService();
  final TeacherTimetableService _timetableService = TeacherTimetableService();

  late Future<Teacher> _teacherFuture;
  late Future<DashboardStats> _statsFuture;
  late Future<List<TimetableModel>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _teacherFuture = _teacherService.getTeacherProfile(widget.employeeId);
    _statsFuture = _teacherService.getDashboardStats(widget.employeeId);
    _scheduleFuture = _timetableService.getTeacherTimetable(widget.employeeId);
  }

  Future<void> _onRefresh() async {
    setState(_loadData);
    await Future.wait([_teacherFuture, _statsFuture, _scheduleFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: ErpColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: FutureBuilder<Teacher>(
                  future: _teacherFuture,
                  builder: (context, snapshot) {
                    final teacher = snapshot.data;
                    return ErpPageHeader(
                      name: teacher?.name ?? 'Loading...',
                      role: 'Faculty',
                      subtitle:
                          teacher != null
                              ? '${teacher.department} Department · ${teacher.employeeId}'
                              : null,
                      onNotificationTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EventManagementScreen(
                                    employeeId: widget.employeeId,
                                    role: 'FACULTY',
                                  ),
                            ),
                          ),
                      onProfileTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ProfileScreen(
                                    employeeId: widget.employeeId,
                                  ),
                            ),
                          ),
                    );
                  },
                ),
              ),

              // ── Stats ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ErpSectionHeader(title: 'Overview'),
                      FutureBuilder<DashboardStats>(
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Row(
                              children: List.generate(
                                4,
                                (i) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: i < 3 ? 10 : 0,
                                    ),
                                    child: const ErpSkeletonCard(),
                                  ),
                                ),
                              ),
                            );
                          }
                          final stats = snapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: ErpStatCard(
                                    label: "Today's Classes",
                                    value: '${stats.todaysClasses}',
                                    icon: Icons.today_outlined,
                                    color: ErpColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 150,
                                  child: ErpStatCard(
                                    label: 'Total Students',
                                    value: '${stats.totalStudents}',
                                    icon: Icons.groups_outlined,
                                    color: ErpColors.info,
                                    surfaceColor: ErpColors.infoSurface,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 150,
                                  child: ErpStatCard(
                                    label: 'Pending Attendance',
                                    value: '${stats.pendingAttendance}',
                                    icon: Icons.fact_check_outlined,
                                    color: ErpColors.warning,
                                    surfaceColor: ErpColors.warningSurface,
                                    badge:
                                        stats.pendingAttendance > 0
                                            ? const ErpStatusBadge(
                                              label: 'Action',
                                              type: ErpBadgeType.warning,
                                              compact: true,
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 150,
                                  child: ErpStatCard(
                                    label: 'Avg. Attendance',
                                    value:
                                        '${stats.averageClassAttendance.toStringAsFixed(1)}%',
                                    icon: Icons.insights_outlined,
                                    color: ErpColors.success,
                                    surfaceColor: ErpColors.successSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Modules ──────────────────────────────────────────
                      const ErpSectionHeader(
                        title: 'Modules',
                        subtitle: 'Faculty management tools',
                      ),
                      _TeacherModuleGrid(employeeId: widget.employeeId),
                      const SizedBox(height: 28),

                      // ── Today's Schedule ──────────────────────────────────
                      const ErpSectionHeader(title: "Today's Schedule"),
                      FutureBuilder<List<TimetableModel>>(
                        future: _scheduleFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Column(
                              children: List.generate(
                                3,
                                (_) => const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: ErpSkeletonListItem(),
                                ),
                              ),
                            );
                          }
                          final slots = snapshot.data!;
                          if (slots.isEmpty) {
                            return const ErpEmptyState(
                              message: 'No classes today',
                              subtitle: 'Your schedule is free for today.',
                              icon: Icons.free_breakfast_outlined,
                            );
                          }
                          return Column(
                            children:
                                slots
                                    .map((s) => _ScheduleCard(slot: s))
                                    .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Teacher Module Grid ────────────────────────────────────────
class _TeacherModuleGrid extends StatelessWidget {
  final String employeeId;
  const _TeacherModuleGrid({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final modules = [
      (
        label: 'Students',
        icon: Icons.groups_outlined,
        color: ErpColors.info,
        surface: ErpColors.infoSurface,
        screen: (context) => StudentsScreen(employeeId: employeeId),
      ),
      (
        label: 'Attendance',
        icon: Icons.fact_check_outlined,
        color: ErpColors.attendance,
        surface: ErpColors.attendanceSurface,
        screen: (context) => AttendanceScreen(employeeId: employeeId),
      ),
      (
        label: 'Test Entry',
        icon: Icons.checklist_outlined,
        color: ErpColors.assessment,
        surface: ErpColors.assessmentSurface,
        screen: (context) => TestEntryScreen(employeeId: employeeId),
      ),
      (
        label: 'Assignments',
        icon: Icons.assignment_outlined,
        color: ErpColors.results,
        surface: ErpColors.resultsSurface,
        screen: (context) => AssignmentsScreen(employeeId: employeeId),
      ),
      (
        label: 'Results',
        icon: Icons.grading_outlined,
        color: ErpColors.primary,
        surface: ErpColors.primarySurface,
        screen: (context) => ResultsScreen(employeeId: employeeId),
      ),
      (
        label: 'Semester',
        icon: Icons.bookmark_added_outlined,
        color: ErpColors.accent,
        surface: ErpColors.accentLight,
        screen:
            (context) => TeacherSemesterResultScreen(employeeId: employeeId),
      ),
      (
        label: 'Fees',
        icon: Icons.account_balance_wallet_outlined,
        color: ErpColors.fees,
        surface: ErpColors.feesSurface,
        screen: (context) => FeesClassSelector(employeeId: employeeId),
      ),
      (
        label: 'Timetable',
        icon: Icons.calendar_month_outlined,
        color: ErpColors.timetable,
        surface: ErpColors.timetableSurface,
        screen: (context) => TimetableScreen(employeeId: employeeId),
      ),
      (
        label: 'Events',
        icon: Icons.campaign_rounded,
        color: ErpColors.warning,
        surface: ErpColors.warningSurface,
        screen:
            (context) =>
                EventManagementScreen(employeeId: employeeId, role: 'FACULTY'),
      ),
      (
        label: 'Notices',
        icon: Icons.notifications_active_outlined,
        color: ErpColors.primary,
        surface: ErpColors.primarySurface,
        screen:
            (context) => NoticeManagementScreenWrapper(employeeId: employeeId),
      ),
      (
        label: 'Messages',
        icon: Icons.chat_bubble_outline,
        color: ErpColors.info,
        surface: ErpColors.infoSurface,
        screen:
            (context) => MessageInboxScreen(
              userId: employeeId,
              userName: 'Teacher',
              userRole: 'TEACHER',
              department: 'Department',
            ),
      ),
      (
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        color: ErpColors.transport,
        surface: ErpColors.transportSurface,
        screen: (context) => const ReportsScreen(),
      ),
      (
        label: 'Profile',
        icon: Icons.person_outline,
        color: ErpColors.textSecondary,
        surface: ErpColors.bgSubtle,
        screen: (context) => ProfileScreen(employeeId: employeeId),
      ),
      (
        label: 'ID Card',
        icon: Icons.badge_outlined,
        color: ErpColors.library,
        surface: ErpColors.librarySurface,
        screen: (context) => TeacherIdCardScreen(employeeId: employeeId),
      ),
      (
        label: 'Settings',
        icon: Icons.settings_outlined,
        color: ErpColors.textMuted,
        surface: ErpColors.bgSubtle,
        screen: (context) => const SettingsScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.90,
      ),
      itemBuilder: (context, i) {
        final m = modules[i];
        return ErpModuleCard(
          label: m.label,
          icon: m.icon,
          color: m.color,
          surfaceColor: m.surface,
          onTap:
              () =>
                  Navigator.push(context, MaterialPageRoute(builder: m.screen)),
        );
      },
    );
  }
}

// ── Schedule Card ──────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final TimetableModel slot;
  const _ScheduleCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ErpCard(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: ErpColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.subject, style: ErpTypography.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    '${slot.time} · ${slot.room} · ${slot.section}',
                    style: ErpTypography.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ErpColors.primarySurface,
                borderRadius: BorderRadius.circular(ErpRadius.full),
              ),
              child: Text(
                slot.day,
                style: ErpTypography.caption.copyWith(
                  color: ErpColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fees Class Selector ────────────────────────────────────────
class FeesClassSelector extends StatefulWidget {
  final String employeeId;
  final String? lockedDepartment;

  const FeesClassSelector({
    super.key,
    required this.employeeId,
    this.lockedDepartment,
  });

  @override
  State<FeesClassSelector> createState() => _FeesClassSelectorState();
}

class _FeesClassSelectorState extends State<FeesClassSelector> {
  String _dept = 'CSE';
  String _year = '4';
  String _sec = 'A';
  String _ay = '2026-27';
  bool _loading = false;

  final _years = ['1', '2', '3', '4'];
  final _secs = ['A', 'B', 'C'];

  String _getSemesterForYear(String year) {
    return switch (year) {
      '1' => 'I',
      '2' => 'III',
      '3' => 'V',
      '4' => 'VII',
      _ => 'I',
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.lockedDepartment != null &&
        widget.lockedDepartment!.isNotEmpty) {
      _dept = widget.lockedDepartment!.toUpperCase();
    } else {
      _fetchTeacherDept();
    }
  }

  Future<void> _fetchTeacherDept() async {
    setState(() => _loading = true);
    try {
      final teacher = await TeacherService().getTeacherProfile(
        widget.employeeId,
      );
      if (mounted)
        setState(() {
          _dept = teacher.department.toUpperCase();
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Fees Module',
        subtitle: 'Select class to view fees',
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    ErpCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ErpColors.primarySurface,
                                  borderRadius: BorderRadius.circular(
                                    ErpRadius.sm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: ErpColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Select Class',
                                style: ErpTypography.headlineSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          ErpCard(
                            border: Border.all(color: ErpColors.border),
                            color: ErpColors.bgSubtle,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Department',
                                  style: ErpTypography.bodySmall,
                                ),
                                Text(
                                  _dept,
                                  style: ErpTypography.titleSmall.copyWith(
                                    color: ErpColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Year',
                                      style: ErpTypography.titleSmall,
                                    ),
                                    const SizedBox(height: 7),
                                    _buildDropdown(
                                      _year,
                                      _years,
                                      (v) => setState(() => _year = v!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Section',
                                      style: ErpTypography.titleSmall,
                                    ),
                                    const SizedBox(height: 7),
                                    _buildDropdown(
                                      _sec,
                                      _secs,
                                      (v) => setState(() => _sec = v!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Text(
                            'Academic Year',
                            style: ErpTypography.titleSmall,
                          ),
                          const SizedBox(height: 7),
                          TextField(
                            style: ErpTypography.bodyLarge,
                            controller: TextEditingController(text: _ay),
                            onChanged: (v) => _ay = v,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 2026-27',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('Open Fees Dashboard'),
                        onPressed:
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => FeesDashboardScreen(
                                      employeeId: widget.employeeId,
                                      department: _dept,
                                      semester: _getSemesterForYear(_year),
                                      section: _sec,
                                      academicYear: _ay,
                                    ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: ErpTypography.bodyLarge,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}

class NoticeManagementScreenWrapper extends StatefulWidget {
  final String employeeId;
  const NoticeManagementScreenWrapper({super.key, required this.employeeId});
  @override
  State<NoticeManagementScreenWrapper> createState() =>
      _NoticeManagementScreenWrapperState();
}

class _NoticeManagementScreenWrapperState
    extends State<NoticeManagementScreenWrapper> {
  String _department = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TeacherService()
        .getTeacherProfile(widget.employeeId)
        .then((teacher) {
          if (mounted)
            setState(() {
              _department = teacher.department;
              _loading = false;
            });
        })
        .catchError((_) {
          if (mounted) setState(() => _loading = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return NoticeManagementScreen(role: 'TEACHER', department: _department);
  }
}
