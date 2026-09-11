import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import '../../core/design_system.dart';
import '../login_screen.dart';
import 'hod_id_card_screen.dart';
import 'hod_attendance_reports_screen.dart';
import '../../teacher/screens/teacher_dashboard_screen.dart';
import '../../teacher/screens/event_management_screen.dart';
import 'hod_semester_result_screen.dart';
import '../approvals/hod_approval_screen.dart';
import '../messages/message_inbox_screen.dart';
import '../notice_management_screen.dart';
import 'teacher_management.dart';

class HodDashboardScreen extends StatefulWidget {
  final String? employeeId;
  const HodDashboardScreen({super.key, required this.employeeId});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  Map<String, dynamic>? _hodData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHodProfile();
  }

  Future<void> _fetchHodProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (widget.employeeId == null) {
      setState(() {
        _errorMessage = 'Invalid HOD Employee ID';
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/hod/${widget.employeeId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _hodData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'HOD profile not found in database';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to communicate with server: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  String get _dept => _hodData?['department'] ?? 'Department';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'HOD Portal',
        subtitle: _hodData != null ? '$_dept Department' : null,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (widget.employeeId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => MessageInboxScreen(
                          userId: widget.employeeId!,
                          userName: 'HOD',
                          userRole: 'HOD',
                          department: _dept,
                        ),
                  ),
                );
              }
            },
            tooltip: 'Confidential Messages',
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (widget.employeeId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => HodApprovalScreen(hodId: widget.employeeId!),
                  ),
                );
              }
            },
            tooltip: 'Request History',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _fetchHodProfile,
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
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(
                message: _errorMessage!,
                onRetry: _fetchHodProfile,
              )
              : RefreshIndicator(
                color: ErpColors.primary,
                onRefresh: _fetchHodProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile Header ───────────────────────────────────
                      ErpCard(
                        color: ErpColors.primary,
                        shadow: [],
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  ErpRadius.md,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.manage_accounts_rounded,
                                color: ErpColors.accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hodData?['name'] ?? 'Head of Department',
                                    style: ErpTypography.headlineMedium
                                        .copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'HOD, $_dept',
                                    style: ErpTypography.bodySmall.copyWith(
                                      color: ErpColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${widget.employeeId}',
                                    style: ErpTypography.caption.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Departmental Modules ─────────────────────────────
                      const ErpSectionHeader(
                        title: 'Departmental Modules',
                        subtitle: 'HOD management tools',
                      ),
                      _HodModuleList(
                        employeeId: widget.employeeId ?? '',
                        department: _dept,
                      ),
                      const SizedBox(height: 24),

                      // ── Profile Details ──────────────────────────────────
                      const ErpSectionHeader(title: 'Profile Details'),
                      ErpCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _hodData?['email'],
                            ),
                            const Divider(height: 20),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: _hodData?['phone'],
                            ),
                            const Divider(height: 20),
                            _InfoRow(
                              icon: Icons.business_outlined,
                              label: 'Department',
                              value: _hodData?['department'],
                            ),
                            const Divider(height: 20),
                            _InfoRow(
                              icon: Icons.assignment_ind_outlined,
                              label: 'Designation',
                              value: _hodData?['designation'],
                            ),
                            const Divider(height: 20),
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Date of Birth',
                              value: _hodData?['dob'],
                            ),
                            const Divider(height: 20),
                            _InfoRow(
                              icon: Icons.person_pin_outlined,
                              label: 'Gender',
                              value: _hodData?['gender'],
                            ),
                            const Divider(height: 20),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Office',
                              value: _hodData?['address'],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Info Banner ──────────────────────────────────────
                      ErpCard(
                        color: ErpColors.warningSurface,
                        border: Border.all(
                          color: ErpColors.warning.withValues(alpha: 0.25),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: ErpColors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Additional departmental controls (approvals, grade sheets) are planned for the next release.',
                                style: ErpTypography.bodySmall.copyWith(
                                  color: ErpColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}

// ── HOD Module List ────────────────────────────────────────────
class _HodModuleList extends StatelessWidget {
  final String employeeId, department;
  const _HodModuleList({required this.employeeId, required this.department});

  @override
  Widget build(BuildContext context) {
    final modules = [
      (
        title: 'Faculty & Assignments',
        subtitle: 'Manage department staff and class incharge roles',
        icon: Icons.assignment_ind_outlined,
        color: ErpColors.textPrimary,
        surface: Colors.white,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        TeacherManagementScreen(lockedDepartment: department),
              ),
            ),
      ),
      (
        title: 'Student Fees Audit',
        subtitle: 'View fee balances for $department department students',
        icon: Icons.account_balance_wallet_outlined,
        color: ErpColors.fees,
        surface: ErpColors.feesSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => FeesClassSelector(
                      employeeId: employeeId,
                      lockedDepartment: department,
                    ),
              ),
            ),
      ),
      (
        title: 'Attendance Reports',
        subtitle: 'View subject-wise faculty attendance submissions',
        icon: Icons.assignment_turned_in_outlined,
        color: ErpColors.attendance,
        surface: ErpColors.attendanceSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => HodAttendanceReportsScreen(department: department),
              ),
            ),
      ),
      (
        title: 'Semester Exam Results',
        subtitle: 'Class GPA grades, analytics, and pass rates',
        icon: Icons.grading_rounded,
        color: ErpColors.results,
        surface: ErpColors.resultsSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => HodSemesterResultScreen(
                      hodId: employeeId,
                      department: department,
                    ),
              ),
            ),
      ),
      (
        title: 'Events & Approvals',
        subtitle: 'Manage and approve department events',
        icon: Icons.campaign_outlined,
        color: ErpColors.warning,
        surface: ErpColors.warningSurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => EventManagementScreen(
                      employeeId: employeeId,
                      role: 'HOD',
                    ),
              ),
            ),
      ),
      (
        title: 'Digital ID Card',
        subtitle: 'View and download your official ID card',
        icon: Icons.badge_outlined,
        color: ErpColors.library,
        surface: ErpColors.librarySurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HodIdCardScreen(employeeId: employeeId),
              ),
            ),
      ),
      (
        title: 'Department Notices',
        subtitle: 'Broadcast alerts to $department students & staff',
        icon: Icons.campaign_rounded,
        color: ErpColors.primary,
        surface: ErpColors.primarySurface,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => NoticeManagementScreen(
                      role: 'HOD',
                      department: department,
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
                  child: ErpCard(
                    onTap: m.onTap,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: m.surface,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                          ),
                          child: Icon(m.icon, color: m.color, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: ErpTypography.titleSmall),
                              const SizedBox(height: 3),
                              Text(m.subtitle, style: ErpTypography.bodySmall),
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
                  ),
                ),
              )
              .toList(),
    );
  }
}

// ── Info Row ────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ErpColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ErpTypography.caption),
              const SizedBox(height: 3),
              Text(
                (value == null || value!.trim().isEmpty)
                    ? 'Not Provided'
                    : value!,
                style: ErpTypography.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
