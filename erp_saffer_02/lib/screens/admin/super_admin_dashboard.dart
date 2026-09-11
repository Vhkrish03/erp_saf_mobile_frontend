import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';
import '../login_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _creating = false;

  int get _totalUsers => _users.length;
  int get _adminCount => _users.where((u) => u['role'] == 'ADMIN').length;
  int get _studentCount => _users.where((u) => u['role'] == 'STUDENT').length;
  int get _teacherCount => _users.where((u) => u['role'] == 'FACULTY').length;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _apiService.getAllUsers();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    try {
      await _apiService.createAdmin(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      ErpSnackbar.show(
        context,
        message: 'Admin account created successfully.',
        type: ErpBadgeType.success,
      );
      await _fetchUsers();
    } catch (e) {
      ErpSnackbar.show(
        context,
        message: 'Error: $e',
        type: ErpBadgeType.danger,
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.card),
            title: Text('Delete Account', style: ErpTypography.headlineSmall),
            content: Text(
              'Are you sure you want to permanently delete "$name" from the ERP?',
              style: ErpTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: ErpColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteUser(id);
        ErpSnackbar.show(
          context,
          message: 'User deleted successfully.',
          type: ErpBadgeType.success,
        );
        await _fetchUsers();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error deleting user: $e',
          type: ErpBadgeType.danger,
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _logout() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final adminsList = _users.where((u) => u['role'] == 'ADMIN').toList();

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Super Admin',
        subtitle: 'System Control Panel',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _fetchUsers,
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
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchUsers)
              : RefreshIndicator(
                color: ErpColors.primary,
                onRefresh: _fetchUsers,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── System Stats ───────────────────────────────────────
                      const ErpSectionHeader(
                        title: 'System Statistics',
                        subtitle: 'Live user counts across all roles',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ErpStatCard(
                              label: 'Total Users',
                              value: '$_totalUsers',
                              icon: Icons.people_outline_rounded,
                              color: ErpColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErpStatCard(
                              label: 'Admins',
                              value: '$_adminCount',
                              icon: Icons.admin_panel_settings_outlined,
                              color: ErpColors.warning,
                              surfaceColor: ErpColors.warningSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                              icon: Icons.badge_outlined,
                              color: ErpColors.info,
                              surfaceColor: ErpColors.infoSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Create Admin ───────────────────────────────────────
                      const ErpSectionHeader(title: 'Create New Administrator'),
                      ErpCard(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                'Full Name',
                                style: ErpTypography.titleSmall,
                              ),
                              const SizedBox(height: 7),
                              TextFormField(
                                controller: _nameController,
                                style: ErpTypography.bodyLarge,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Dr. Ramesh Kumar',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 18,
                                    color: ErpColors.textMuted,
                                  ),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Name is required'
                                            : null,
                              ),
                              const SizedBox(height: 14),
                              // Email
                              Text(
                                'Login Email',
                                style: ErpTypography.titleSmall,
                              ),
                              const SizedBox(height: 7),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: ErpTypography.bodyLarge,
                                decoration: const InputDecoration(
                                  hintText: 'admin@college.edu',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 18,
                                    color: ErpColors.textMuted,
                                  ),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Email is required'
                                            : null,
                              ),
                              const SizedBox(height: 14),
                              // Password
                              Text('Password', style: ErpTypography.titleSmall),
                              const SizedBox(height: 7),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                style: ErpTypography.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Min. 4 characters',
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
                                        () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                  ),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.length < 4)
                                            ? 'Min. 4 characters required'
                                            : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  icon:
                                      _creating
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.person_add_outlined,
                                            size: 18,
                                          ),
                                  label: Text(
                                    _creating
                                        ? 'Creating...'
                                        : 'Create Administrator Account',
                                    style: ErpTypography.button.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: _creating ? null : _createAdmin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ErpColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: ErpRadius.button,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Admin Accounts List ────────────────────────────────
                      ErpSectionHeader(
                        title: 'Administrator Accounts',
                        badge: ErpStatusBadge(
                          label: '$_adminCount Admins',
                          type: ErpBadgeType.info,
                        ),
                      ),
                      adminsList.isEmpty
                          ? const ErpEmptyState(
                            message: 'No administrators registered',
                            subtitle:
                                'Create the first admin account using the form above.',
                            icon: Icons.admin_panel_settings_outlined,
                          )
                          : Column(
                            children:
                                adminsList
                                    .map(
                                      (adm) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: ErpCard(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      ErpColors.warningSurface,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        ErpRadius.md,
                                                      ),
                                                ),
                                                child: const Icon(
                                                  Icons
                                                      .admin_panel_settings_rounded,
                                                  color: ErpColors.warning,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      adm['fullName'] ??
                                                          'Admin User',
                                                      style:
                                                          ErpTypography
                                                              .titleSmall,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      adm['email'] ?? '',
                                                      style:
                                                          ErpTypography
                                                              .bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: ErpColors.danger,
                                                  size: 20,
                                                ),
                                                onPressed:
                                                    () => _deleteUser(
                                                      adm['id'] as int,
                                                      adm['fullName'] ??
                                                          'Admin',
                                                    ),
                                                tooltip: 'Delete',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
