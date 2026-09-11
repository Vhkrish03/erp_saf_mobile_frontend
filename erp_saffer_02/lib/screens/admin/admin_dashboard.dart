import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';
import '../login_screen.dart';
import 'admin_student_dashboard.dart';
import 'teacher_management.dart';
import 'hod_management.dart';
import 'exam_cell_management.dart';
import 'admin_id_card_screen.dart';
import '../../transport/screens/admin_bus_management_dashboard.dart';
import '../notice_management_screen.dart';
import '../approvals/admin_approval_screen.dart';
import '../messages/message_inbox_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? employeeId;
  const AdminDashboardScreen({super.key, this.employeeId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApiService _apiService = AdminApiService();
  bool _isLoading = true;
  String? _errorMessage;

  int _studentCount = 0;
  int _teacherCount = 0;
  int _hodCount = 0;
  int _examCellCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getAllStudents(),
        _apiService.getAllTeachers(),
        _apiService.getAllHods(),
        _apiService.getAllExamCellAdmins(),
      ]);
      setState(() {
        _studentCount = (results[0] as List).length;
        _teacherCount = (results[1] as List).length;
        _hodCount = (results[2] as List).length;
        _examCellCount = (results[3] as List).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load metrics. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Admin Portal',
        subtitle: 'College Management System',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const MessageInboxScreen(
                        userId: 'ADMIN',
                        userName: 'Admin',
                        userRole: 'ADMIN',
                        department: 'ALL',
                        isAdmin: true,
                      ),
                ),
              );
            },
            tooltip: 'Confidential Messages Admin View',
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
              );
            },
            tooltip: 'Approvals Inbox',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _fetchStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildSkeleton()
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchStats)
              : RefreshIndicator(
                color: ErpColors.primary,
                onRefresh: _fetchStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome Card ───────────────────────────────────────
                      ErpCard(
                        color: ErpColors.primary,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  ErpRadius.md,
                                ),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, College Admin',
                                    style: ErpTypography.headlineMedium
                                        .copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage registrations, assignments, and system settings.',
                                    style: ErpTypography.bodySmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        shadow: [],
                      ),
                      const SizedBox(height: 20),

                      // ── KPI Stats ──────────────────────────────────────────
                      const ErpSectionHeader(title: 'Institution Overview'),
                      Row(
                        children: [
                          Expanded(
                            child: ErpStatCard(
                              label: 'Students',
                              value: '$_studentCount',
                              icon: Icons.school_outlined,
                              color: ErpColors.attendance,
                              surfaceColor: ErpColors.attendanceSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErpStatCard(
                              label: 'Faculty',
                              value: '$_teacherCount',
                              icon: Icons.person_outline,
                              color: ErpColors.info,
                              surfaceColor: ErpColors.infoSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ErpStatCard(
                              label: 'HODs',
                              value: '$_hodCount',
                              icon: Icons.supervisor_account_outlined,
                              color: ErpColors.warning,
                              surfaceColor: ErpColors.warningSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErpStatCard(
                              label: 'Exam Officers',
                              value: '$_examCellCount',
                              icon: Icons.analytics_outlined,
                              color: ErpColors.results,
                              surfaceColor: ErpColors.resultsSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Modules ────────────────────────────────────────────
                      const ErpSectionHeader(
                        title: 'Administrative Modules',
                        subtitle: 'Manage all institution operations',
                      ),
                      _AdminModuleList(
                        studentCount: _studentCount,
                        teacherCount: _teacherCount,
                        hodCount: _hodCount,
                        examCellCount: _examCellCount,
                        employeeId: widget.employeeId,
                        onRefresh: _fetchStats,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ErpSkeletonCard(),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              2,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 12 : 0),
                  child: const ErpSkeletonCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              2,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 12 : 0),
                  child: const ErpSkeletonCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ErpSkeletonListItem(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin Module List ──────────────────────────────────────────
class _AdminModuleList extends StatelessWidget {
  final int studentCount, teacherCount, hodCount, examCellCount;
  final String? employeeId;
  final VoidCallback onRefresh;

  const _AdminModuleList({
    required this.studentCount,
    required this.teacherCount,
    required this.hodCount,
    required this.examCellCount,
    required this.employeeId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      (
        title: 'Student Database',
        subtitle: '$studentCount registered students',
        icon: Icons.school_rounded,
        color: ErpColors.attendance,
        surface: ErpColors.attendanceSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminStudentDashboardScreen(),
              ),
            ).then((_) => onRefresh()),
      ),
      (
        title: 'Teacher Registry',
        subtitle: '$teacherCount recruited faculty members',
        icon: Icons.badge_outlined,
        color: ErpColors.info,
        surface: ErpColors.infoSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherManagementScreen(),
              ),
            ).then((_) => onRefresh()),
      ),
      (
        title: 'Head of Departments',
        subtitle: '$hodCount assigned department heads',
        icon: Icons.supervisor_account_rounded,
        color: ErpColors.warning,
        surface: ErpColors.warningSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HodManagementScreen()),
            ).then((_) => onRefresh()),
      ),
      (
        title: 'Exam Cell Officers',
        subtitle: '$examCellCount configured officers',
        icon: Icons.analytics_rounded,
        color: ErpColors.results,
        surface: ErpColors.resultsSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExamCellManagementScreen(),
              ),
            ).then((_) => onRefresh()),
      ),
      (
        title: 'Academic Fees Entry',
        subtitle: 'Configure and assign student fee requirements',
        icon: Icons.payments_rounded,
        color: ErpColors.fees,
        surface: ErpColors.feesSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => const AdminStudentDashboardScreen(isFeeMode: true),
              ),
            ),
      ),
      (
        title: 'Transport Fleet',
        subtitle: 'Routes, drivers, buses & live tracking',
        icon: Icons.directions_bus_outlined,
        color: ErpColors.transport,
        surface: ErpColors.transportSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminBusManagementDashboardScreen(),
              ),
            ),
      ),
      (
        title: 'Digital ID Card',
        subtitle: 'View administrator identification documents',
        icon: Icons.credit_card_outlined,
        color: ErpColors.library,
        surface: ErpColors.librarySurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        AdminIdCardScreen(employeeId: employeeId ?? 'ADM-001'),
              ),
            ),
      ),
      (
        title: 'College Notices',
        subtitle: 'Manage and broadcast announcements',
        icon: Icons.campaign_outlined,
        color: ErpColors.primary,
        surface: ErpColors.primarySurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => const NoticeManagementScreen(
                      role: 'ADMIN',
                      department: 'ALL',
                    ),
              ),
            ),
      ),
    ];

    return Column(
      children:
          modules
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AdminModuleCard(
                    title: m.title,
                    subtitle: m.subtitle,
                    icon: m.icon,
                    color: m.color,
                    surfaceColor: m.surface,
                    onTap: m.onTap,
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _AdminModuleCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color, surfaceColor;
  final VoidCallback onTap;

  const _AdminModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surfaceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ErpCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(ErpRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ErpTypography.titleSmall),
                const SizedBox(height: 3),
                Text(subtitle, style: ErpTypography.bodySmall),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: ErpColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
