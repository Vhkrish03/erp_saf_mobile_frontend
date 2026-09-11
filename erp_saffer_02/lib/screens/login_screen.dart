import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';
import 'main_shell.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import 'package:erp_saf/teacher/screens/teacher_dashboard_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/super_admin_dashboard.dart';
import 'admin/hod_dashboard.dart';
import '../exam_admin/screens/exam_admin_dashboard_screen.dart';

class _RoleOption {
  final String label;
  final String role;
  final String idLabel;
  final String hint;
  final IconData icon;

  const _RoleOption({
    required this.label,
    required this.role,
    required this.idLabel,
    required this.hint,
    required this.icon,
  });
}

const List<_RoleOption> _roles = [
  _RoleOption(
    label: 'Student',
    role: 'STUDENT',
    idLabel: 'Student ID',
    hint: 'e.g.  STU2309',
    icon: Icons.school_rounded,
  ),
  _RoleOption(
    label: 'Faculty',
    role: 'FACULTY',
    idLabel: 'Employee ID',
    hint: 'e.g.  EMP008',
    icon: Icons.person_rounded,
  ),
  _RoleOption(
    label: 'HOD',
    role: 'HOD',
    idLabel: 'HOD ID',
    hint: 'e.g.  HOD001',
    icon: Icons.manage_accounts_rounded,
  ),
  _RoleOption(
    label: 'Exam Cell',
    role: 'EXAM_CELL',
    idLabel: 'Exam Cell ID',
    hint: 'e.g.  EXM001',
    icon: Icons.analytics_rounded,
  ),
  _RoleOption(
    label: 'Admin',
    role: 'ADMIN',
    idLabel: 'Email Address',
    hint: 'admin@college.edu',
    icon: Icons.admin_panel_settings_rounded,
  ),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  int _selectedRoleIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  _RoleOption get _currentRole => _roles[_selectedRoleIndex];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final loginId = _idController.text.trim();
    final password = _passwordController.text;

    if (loginId.isEmpty) {
      ErpSnackbar.show(
        context,
        message: 'Please enter your ${_currentRole.idLabel}.',
        type: ErpBadgeType.warning,
      );
      return;
    }
    if (password.isEmpty) {
      ErpSnackbar.show(
        context,
        message: 'Please enter your password.',
        type: ErpBadgeType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'loginId': loginId,
              'password': password,
              'role': _currentRole.role,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final String role = data['role'] ?? '';
          final String? referenceId = data['referenceId'];
          final String fullName = data['fullName'] ?? '';
          ErpSnackbar.show(
            context,
            message: 'Welcome back, $fullName 👋',
            type: ErpBadgeType.success,
          );
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;

          switch (role) {
            case 'STUDENT':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MainShell(studentId: referenceId ?? ''),
                ),
              );
              break;
            case 'FACULTY':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          TeacherDashboardScreen(employeeId: referenceId ?? ''),
                ),
              );
              break;
            case 'HOD':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => HodDashboardScreen(employeeId: referenceId ?? ''),
                ),
              );
              break;
            case 'EXAM_CELL':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ExamAdminDashboardScreen(
                        performedBy: referenceId ?? 'EXM001',
                        role: 'EXAM_CELL',
                      ),
                ),
              );
              break;
            case 'ADMIN':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AdminDashboardScreen(
                        employeeId: referenceId ?? 'ADM-001',
                      ),
                ),
              );
              break;
            case 'SUPER_ADMIN':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SuperAdminDashboardScreen(),
                ),
              );
              break;
          }
        } else {
          ErpSnackbar.show(
            context,
            message: data['message'] ?? 'Login failed.',
            type: ErpBadgeType.danger,
          );
        }
      } else {
        ErpSnackbar.show(
          context,
          message: 'Server error (${response.statusCode}). Try again.',
          type: ErpBadgeType.danger,
        );
      }
    } on TimeoutException {
      ErpSnackbar.show(
        context,
        message: 'Connection timed out. Check your network.',
        type: ErpBadgeType.warning,
      );
    } on SocketException {
      ErpSnackbar.show(
        context,
        message: 'Cannot reach server. Check your connection.',
        type: ErpBadgeType.danger,
      );
    } catch (e) {
      ErpSnackbar.show(
        context,
        message: e.toString(),
        type: ErpBadgeType.danger,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectRole(int index) {
    if (_selectedRoleIndex == index) return;
    setState(() {
      _selectedRoleIndex = index;
      _idController.clear();
    });
    _fadeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      body: SafeArea(
        child: Row(
          children: [
            // Left decorative panel (visible on wide screens)
            if (MediaQuery.of(context).size.width > 700)
              Expanded(
                flex: 2,
                child: Container(
                  color: ErpColors.primary,
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(ErpRadius.md),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: ErpColors.accent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'College ERP',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enterprise Academic Resource Planning',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ...[
                        'Student Portal',
                        'Faculty Dashboard',
                        'HOD Management',
                        'Admin Console',
                        'Exam Cell',
                      ].map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: ErpColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13.5,
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
              ),

            // Right: Login Form
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 48,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + Title (on mobile)
                        if (MediaQuery.of(context).size.width <= 700) ...[
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: ErpColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    ErpRadius.md,
                                  ),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: ErpColors.accent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'College ERP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: ErpColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Academic Management System',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: ErpColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                        ],

                        Text(
                          'Welcome back',
                          style: ErpTypography.displayMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to access your portal',
                          style: ErpTypography.bodyMedium,
                        ),
                        const SizedBox(height: 32),

                        // Role Selector
                        Text(
                          'LOGIN AS',
                          style: ErpTypography.labelSmall.copyWith(
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ErpColors.bgWhite,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                            border: Border.all(color: ErpColors.border),
                          ),
                          child: Row(
                            children: List.generate(_roles.length, (i) {
                              final r = _roles[i];
                              final sel = _selectedRoleIndex == i;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectRole(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          sel
                                              ? ErpColors.primary
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        ErpRadius.sm,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          r.icon,
                                          size: 17,
                                          color:
                                              sel
                                                  ? ErpColors.accent
                                                  : ErpColors.textMuted,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          r.label,
                                          style: GoogleFonts.inter(
                                            color:
                                                sel
                                                    ? Colors.white
                                                    : ErpColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ID Field
                        Text(
                          _currentRole.idLabel,
                          style: ErpTypography.titleSmall,
                        ),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _idController,
                          keyboardType:
                              _currentRole.role == 'ADMIN'
                                  ? TextInputType.emailAddress
                                  : TextInputType.text,
                          style: ErpTypography.bodyLarge,
                          decoration: InputDecoration(
                            hintText: _currentRole.hint,
                            prefixIcon: Icon(
                              _currentRole.icon,
                              size: 18,
                              color: ErpColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        Text('Password', style: ErpTypography.titleSmall),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          style: ErpTypography.bodyLarge,
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: ErpColors.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: ErpColors.textMuted,
                              ),
                              onPressed:
                                  () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ErpColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: ErpRadius.button,
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.login_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sign in as ${_currentRole.label}',
                                          style: ErpTypography.button.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Help Guide
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ErpColors.primarySurface,
                            borderRadius: ErpRadius.card,
                            border: Border.all(color: ErpColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.help_outline_rounded,
                                    size: 15,
                                    color: ErpColors.primary,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Login ID Guide',
                                    style: ErpTypography.titleSmall.copyWith(
                                      color: ErpColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...[
                                ('Student', 'Student ID', 'STU2309'),
                                ('Faculty', 'Employee ID', 'EMP008'),
                                ('HOD', 'HOD ID', 'HOD001'),
                                ('Exam Cell', 'Exam Cell ID', 'EXM001'),
                                ('Admin', 'Email address', 'admin@college.edu'),
                              ].map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          e.$1,
                                          style: ErpTypography.caption.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: ErpColors.primary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '→ ',
                                        style: ErpTypography.caption.copyWith(
                                          color: ErpColors.textMuted,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${e.$2} (e.g. ${e.$3})',
                                          style: ErpTypography.caption,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
