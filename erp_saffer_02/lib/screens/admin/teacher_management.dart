import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../teacher/models/teacher.dart';
import '../../services/admin_api_service.dart';
import '../../services/approval_api_service.dart';
import '../../models/approval_request.dart';
import 'dart:convert';
import 'teacher_subject_assignment_screen.dart';

class TeacherManagementScreen extends StatefulWidget {
  final String? lockedDepartment;
  const TeacherManagementScreen({super.key, this.lockedDepartment});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<Teacher> _allTeachers = [];
  Map<String, List<Teacher>> _departmentMap = {};
  List<Teacher> _filteredTeachers = [];
  String? _selectedDepartment;

  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.lockedDepartment != null) {
      _selectedDepartment = widget.lockedDepartment;
    }
    _fetchTeachers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _apiService.getAllTeachers();
      _departmentMap.clear();

      const staticDepts = ['CSE', 'ECE', 'EEE', 'AIDS', 'CIVIL', 'MECH', 'S&H'];
      for (var d in staticDepts) {
        _departmentMap[d] = [];
      }

      for (var t in list) {
        final dept =
            t.department.isNotEmpty ? t.department.toUpperCase() : 'OTHER';
        if (!_departmentMap.containsKey(dept)) {
          _departmentMap[dept] = [];
        }
        _departmentMap[dept]!.add(t);
      }

      setState(() {
        _allTeachers = list;
        if (_selectedDepartment != null) {
          _filteredTeachers = _departmentMap[_selectedDepartment!] ?? [];
          _onSearch();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load teachers: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    if (_selectedDepartment == null) return;
    final q = _searchController.text.toLowerCase();
    setState(() {
      final deptList = _departmentMap[_selectedDepartment!] ?? [];
      _filteredTeachers =
          deptList
              .where(
                (t) =>
                    t.name.toLowerCase().contains(q) ||
                    t.employeeId.toLowerCase().contains(q) ||
                    t.department.toLowerCase().contains(q) ||
                    t.designation.toLowerCase().contains(q),
              )
              .toList();
    });
  }

  Future<void> _delete(int? id, String empId, String name) async {
    if (id == null) return;

    final isHodMode = widget.lockedDepartment != null;
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
            title: Text(
              isHodMode ? 'Request Deletion' : 'Delete Teacher',
              style: ErpTypography.headlineSmall,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isHodMode
                      ? 'Request admin to remove $name ($empId) from your department.'
                      : 'Are you sure you want to delete $name ($empId)? All credentials and schedules will be removed.',
                  style: ErpTypography.bodyMedium,
                ),
                if (isHodMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for deletion (Required)',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isHodMode ? 'Submit Request' : 'Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      if (isHodMode && reasonController.text.trim().isEmpty) {
        ErpSnackbar.show(
          context,
          message: 'Reason is required for HOD requests.',
          type: ErpBadgeType.warning,
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        if (isHodMode) {
          final req = ApprovalRequest(
            hodId: 'HOD', // In real app, pull from secure storage
            department: widget.lockedDepartment!,
            actionType: 'DELETE',
            teacherId: id,
            teacherName: name,
            reason: reasonController.text.trim(),
            status: 'PENDING',
          );
          await ApprovalApiService().submitRequest(req);
          ErpSnackbar.show(
            context,
            message: 'Deletion request sent to Admin for approval.',
            type: ErpBadgeType.success,
          );
        } else {
          await _apiService.deleteTeacher(id);
          ErpSnackbar.show(
            context,
            message: 'Teacher deleted successfully.',
            type: ErpBadgeType.success,
          );
        }
        await _fetchTeachers();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error processing action: $e',
          type: ErpBadgeType.danger,
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _openForm({Teacher? teacher}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _TeacherFormDialog(
            teacher: teacher,
            onSave: (data, password) async {
              Navigator.pop(ctx);
              final isHodMode = widget.lockedDepartment != null;

              if (isHodMode) {
                // If HOD mode, we ask for a reason first!
                final reasonController = TextEditingController();
                final proceed = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        backgroundColor: ErpColors.bgWhite,
                        title: Text(
                          teacher == null
                              ? 'Request New Faculty'
                              : 'Request Profile Update',
                          style: ErpTypography.titleMedium,
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Please state the reason for this change. This will be reviewed by the Admin.',
                              style: ErpTypography.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: reasonController,
                              decoration: const InputDecoration(
                                labelText: 'Reason (Required)',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ErpColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Send to Admin'),
                          ),
                        ],
                      ),
                );

                if (proceed != true) return;
                if (reasonController.text.trim().isEmpty) {
                  ErpSnackbar.show(
                    context,
                    message: 'Reason is required for HOD requests.',
                    type: ErpBadgeType.warning,
                  );
                  return;
                }

                setState(() => _isLoading = true);
                try {
                  if (password != null && password.trim().isNotEmpty) {
                    data['password'] = password.trim();
                  }
                  final req = ApprovalRequest(
                    hodId:
                        'HOD', // Use actual HOD ID from storage in production
                    department: widget.lockedDepartment!,
                    actionType: teacher == null ? 'ADD' : 'EDIT',
                    teacherId: teacher?.id,
                    teacherName: data['name'] ?? 'Unknown',
                    payload: jsonEncode(data),
                    reason: reasonController.text.trim(),
                    status: 'PENDING',
                  );
                  await ApprovalApiService().submitRequest(req);
                  ErpSnackbar.show(
                    context,
                    message: 'Request sent to Admin.',
                    type: ErpBadgeType.success,
                  );
                  await _fetchTeachers();
                } catch (e) {
                  ErpSnackbar.show(
                    context,
                    message: 'Error: $e',
                    type: ErpBadgeType.danger,
                  );
                  if (mounted) setState(() => _isLoading = false);
                }
                return;
              }

              setState(() => _isLoading = true);
              try {
                if (teacher == null) {
                  await _apiService.createTeacher(data, password!);
                  ErpSnackbar.show(
                    context,
                    message: 'Teacher registered successfully.',
                    type: ErpBadgeType.success,
                  );
                } else {
                  await _apiService.updateTeacher(
                    teacher.id!,
                    data,
                    password: password,
                  );
                  ErpSnackbar.show(
                    context,
                    message: 'Teacher updated successfully.',
                    type: ErpBadgeType.success,
                  );
                }
                await _fetchTeachers();
              } catch (e) {
                ErpSnackbar.show(
                  context,
                  message: 'Error saving teacher: $e',
                  type: ErpBadgeType.danger,
                );
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
    );
  }

  Widget _buildDepartmentsGrid() {
    final depts = _departmentMap.keys.toList()..sort();
    if (depts.isEmpty) {
      return const ErpEmptyState(
        message: 'No faculty departments found',
        icon: Icons.account_balance_outlined,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ErpSectionHeader(
            title: 'Select Department',
            subtitle: 'Tap a department to view faculty members',
          ),
          Expanded(
            child: RefreshIndicator(
              color: ErpColors.primary,
              onRefresh: _fetchTeachers,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                itemCount: depts.length,
                itemBuilder: (ctx, i) {
                  final dept = depts[i];
                  final count = _departmentMap[dept]!.length;

                  IconData iconData = Icons.apartment_rounded;
                  Color color = ErpColors.primary;
                  Color surface = ErpColors.primarySurface;

                  switch (dept) {
                    case 'CSE':
                      iconData = Icons.computer_outlined;
                      color = ErpColors.info;
                      surface = ErpColors.infoSurface;
                      break;
                    case 'ECE':
                      iconData = Icons.memory_outlined;
                      color = ErpColors.attendance;
                      surface = ErpColors.attendanceSurface;
                      break;
                    case 'EEE':
                      iconData = Icons.electrical_services_outlined;
                      color = ErpColors.fees;
                      surface = ErpColors.feesSurface;
                      break;
                    case 'MECH':
                      iconData = Icons.settings_outlined;
                      color = ErpColors.warning;
                      surface = ErpColors.warningSurface;
                      break;
                    case 'CIVIL':
                      iconData = Icons.architecture_outlined;
                      color = ErpColors.library;
                      surface = ErpColors.librarySurface;
                      break;
                    case 'AIDS':
                      iconData = Icons.psychology_outlined;
                      color = ErpColors.results;
                      surface = ErpColors.resultsSurface;
                      break;
                    case 'S&H':
                      iconData = Icons.science_outlined;
                      color = ErpColors.transport;
                      surface = ErpColors.transportSurface;
                      break;
                  }

                  return ErpCard(
                    onTap: () {
                      setState(() {
                        _selectedDepartment = dept;
                        _onSearch();
                      });
                    },
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                          ),
                          child: Icon(iconData, size: 30, color: color),
                        ),
                        const SizedBox(height: 12),
                        Text(dept, style: ErpTypography.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          '$count Teachers',
                          style: ErpTypography.caption,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: ErpSearchBar(
            controller: _searchController,
            onChanged: (_) {},
            hint: 'Search by name, ID, designation...',
          ),
        ),
        Expanded(
          child:
              _filteredTeachers.isEmpty
                  ? const ErpEmptyState(
                    message: 'No faculty profiles found',
                    icon: Icons.badge_outlined,
                  )
                  : RefreshIndicator(
                    color: ErpColors.primary,
                    onRefresh: _fetchTeachers,
                    child: ListView.builder(
                      itemCount: _filteredTeachers.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (ctx, i) {
                        final t = _filteredTeachers[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ErpCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: ErpColors.primarySurface,
                                        borderRadius: BorderRadius.circular(
                                          ErpRadius.md,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        t.name.isNotEmpty
                                            ? t.name[0].toUpperCase()
                                            : 'F',
                                        style: ErpTypography.headlineMedium
                                            .copyWith(color: ErpColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.name,
                                            style: ErpTypography.titleLarge,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              ErpStatusBadge(
                                                label: t.department,
                                                type: ErpBadgeType.accent,
                                                compact: true,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'ID: ${t.employeeId}',
                                                  style: ErpTypography.bodySmall
                                                      .copyWith(
                                                        color:
                                                            ErpColors.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t.designation,
                                            style: ErpTypography.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                            color: ErpColors.textMuted,
                                          ),
                                          onPressed:
                                              () => _openForm(teacher: t),
                                          tooltip: 'Edit Profile',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: ErpColors.danger,
                                          ),
                                          onPressed:
                                              () => _delete(
                                                t.id,
                                                t.employeeId,
                                                t.name,
                                              ),
                                          tooltip: 'Delete Teacher',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(height: 1, color: ErpColors.divider),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmall = constraints.maxWidth < 360;

                                    Widget assignmentLabel = Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: ErpColors.warningSurface,
                                            borderRadius: BorderRadius.circular(
                                              ErpRadius.xs,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.assignment_ind_outlined,
                                            size: 16,
                                            color: ErpColors.warning,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Academics & Allotment',
                                          style: ErpTypography.labelMedium,
                                        ),
                                      ],
                                    );

                                    Widget assignButton = ErpButton(
                                      label: 'Manage Allotments',
                                      icon: Icons.arrow_forward_rounded,
                                      type: ErpButtonType.secondary,
                                      fullWidth: isSmall,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    TeacherAssignmentManagementScreen(
                                                      teacher: t,
                                                    ),
                                          ),
                                        );
                                      },
                                    );

                                    if (isSmall) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          assignmentLabel,
                                          const SizedBox(height: 12),
                                          assignButton,
                                        ],
                                      );
                                    }

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [assignmentLabel, assignButton],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title:
            _selectedDepartment == null
                ? 'Manage Faculty'
                : '$_selectedDepartment Faculty',
        subtitle:
            _selectedDepartment == null
                ? '${_allTeachers.length} faculty members'
                : '${_filteredTeachers.length} members',
        showBack: true,
        onBack:
            (_selectedDepartment != null && widget.lockedDepartment == null)
                ? () {
                  setState(() {
                    _selectedDepartment = null;
                    _searchController.clear();
                  });
                }
                : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: Text(
          'Add Faculty',
          style: ErpTypography.button.copyWith(color: Colors.white),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchTeachers)
              : _selectedDepartment == null
              ? _buildDepartmentsGrid()
              : _buildTeacherList(),
    );
  }
}

// ── Teacher Form Dialog ────────────────────────────────────────
class _TeacherFormDialog extends StatefulWidget {
  final Teacher? teacher;
  final Function(Map<String, dynamic> data, String? password) onSave;
  const _TeacherFormDialog({this.teacher, required this.onSave});

  @override
  State<_TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<_TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  late final _empId = TextEditingController(
    text: widget.teacher?.employeeId ?? '',
  );
  late final _name = TextEditingController(text: widget.teacher?.name ?? '');
  late final _gender = TextEditingController(
    text: widget.teacher?.gender ?? '',
  );
  late final _dob = TextEditingController(text: widget.teacher?.dob ?? '');
  late final _dept = TextEditingController(
    text: widget.teacher?.department ?? '',
  );
  late final _desig = TextEditingController(
    text: widget.teacher?.designation ?? '',
  );
  late final _qual = TextEditingController(
    text: widget.teacher?.qualification ?? '',
  );
  late final _exp = TextEditingController(
    text: widget.teacher?.experienceYears?.toString() ?? '0',
  );
  late final _phone = TextEditingController(text: widget.teacher?.phone ?? '');
  late final _email = TextEditingController(text: widget.teacher?.email ?? '');
  late final _address = TextEditingController(
    text: widget.teacher?.address ?? '',
  );
  late final _joining = TextEditingController(
    text: widget.teacher?.joiningDate ?? '',
  );
  late final _status = TextEditingController(
    text: widget.teacher?.status ?? 'ACTIVE',
  );
  late final _emName = TextEditingController(
    text: widget.teacher?.emergencyContactName ?? '',
  );
  late final _emPhone = TextEditingController(
    text: widget.teacher?.emergencyContactNumber ?? '',
  );
  final _password = TextEditingController();
  final _currentPassword = TextEditingController(text: "Loading...");

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _fetchCurrentPassword(widget.teacher!.id!);
    }
  }

  Future<void> _fetchCurrentPassword(int id) async {
    try {
      final AdminApiService apiService = AdminApiService();
      String pwd = await apiService.getTeacherPassword(id);
      if (mounted) {
        setState(() {
          _currentPassword.text = pwd.isEmpty ? "No password" : pwd;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPassword.text = "Error loading";
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _empId,
      _name,
      _gender,
      _dob,
      _dept,
      _desig,
      _qual,
      _exp,
      _phone,
      _email,
      _address,
      _joining,
      _status,
      _emName,
      _emPhone,
      _password,
      _currentPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.teacher != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
      backgroundColor: ErpColors.bgWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Faculty Profile' : 'Register Teacher',
              style: ErpTypography.headlineMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(
                        _empId,
                        'Employee ID',
                        icon: Icons.badge_outlined,
                        enabled: !isEdit,
                        required: true,
                      ),
                      _field(
                        _name,
                        'Full Name',
                        icon: Icons.person_pin_outlined,
                        required: true,
                      ),
                      if (isEdit) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _currentPassword,
                            readOnly: true,
                            style: ErpTypography.bodyLarge.copyWith(
                              color: ErpColors.textSecondary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: ErpColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                      _passwordField(isEdit),
                      _field(
                        _email,
                        'Email',
                        icon: Icons.email_outlined,
                        required: true,
                      ),
                      _field(_phone, 'Phone', icon: Icons.phone_outlined),
                      Row(
                        children: [
                          Expanded(
                            child: _field(_dept, 'Department', hint: 'CSE'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              _desig,
                              'Designation',
                              hint: 'Asst. Prof',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _gender,
                              'Gender',
                              hint: 'Male/Female',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(_dob, 'DOB', hint: 'YYYY-MM-DD'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(_qual, 'Qualification', hint: 'PhD'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              _exp,
                              'Experience (yrs)',
                              type: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _joining,
                              'Joining Date',
                              hint: 'YYYY-MM-DD',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(_status, 'Status', hint: 'ACTIVE'),
                          ),
                        ],
                      ),
                      _field(_emName, 'Emergency Contact'),
                      _field(_emPhone, 'Emergency Phone'),
                      _field(_address, 'Address', lines: 2),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ErpButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ErpButton(
                    label: isEdit ? 'Update' : 'Register',
                    fullWidth: true,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(
                          {
                            'employeeId': _empId.text.trim(),
                            'name': _name.text.trim(),
                            'gender': _gender.text.trim(),
                            'dob':
                                _dob.text.trim().isEmpty
                                    ? null
                                    : _dob.text.trim(),
                            'department': _dept.text.trim().toUpperCase(),
                            'designation': _desig.text.trim(),
                            'qualification': _qual.text.trim(),
                            'experienceYears':
                                int.tryParse(_exp.text.trim()) ?? 0,
                            'phone': _phone.text.trim(),
                            'email': _email.text.trim(),
                            'address': _address.text.trim(),
                            'joiningDate':
                                _joining.text.trim().isEmpty
                                    ? null
                                    : _joining.text.trim(),
                            'status': _status.text.trim(),
                            'emergencyContactName': _emName.text.trim(),
                            'emergencyContactNumber': _emPhone.text.trim(),
                          },
                          _password.text.trim().isEmpty
                              ? null
                              : _password.text.trim(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(bool isEdit) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _password,
      obscureText: _obscure,
      style: ErpTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: isEdit ? 'New Password (Optional)' : 'Initial Password',
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
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator:
          (v) =>
              (!isEdit && (v == null || v.trim().isEmpty))
                  ? 'Password is required'
                  : null,
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    IconData? icon,
    bool required = false,
    bool enabled = true,
    int lines = 1,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: lines,
      enabled: enabled,
      keyboardType: type,
      style: ErpTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            icon != null
                ? Icon(icon, size: 18, color: ErpColors.textMuted)
                : null,
      ),
      validator:
          required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
    ),
  );
}
