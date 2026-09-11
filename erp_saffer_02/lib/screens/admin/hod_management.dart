import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';

class HodManagementScreen extends StatefulWidget {
  const HodManagementScreen({super.key});

  @override
  State<HodManagementScreen> createState() => _HodManagementScreenState();
}

class _HodManagementScreenState extends State<HodManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<Map<String, dynamic>> _hods = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, List<Map<String, dynamic>>> _departmentMap = {};
  String? _selectedDepartment;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHods();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _apiService.getAllHods();
      _departmentMap.clear();

      const staticDepts = ['CSE', 'ECE', 'EEE', 'AIDS', 'CIVIL', 'MECH', 'S&H'];
      for (var d in staticDepts) {
        _departmentMap[d] = [];
      }

      for (var h in list) {
        final deptStr = h['department']?.toString() ?? '';
        final dept = deptStr.isNotEmpty ? deptStr.toUpperCase() : 'OTHER';
        if (!_departmentMap.containsKey(dept)) {
          _departmentMap[dept] = [];
        }
        _departmentMap[dept]!.add(h);
      }

      setState(() {
        _hods = list;
        if (_selectedDepartment != null) {
          _filtered = _departmentMap[_selectedDepartment!] ?? [];
          _onSearch();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load HODs: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    final sourceList =
        _selectedDepartment != null
            ? (_departmentMap[_selectedDepartment!] ?? [])
            : _hods;
    setState(() {
      _filtered =
          sourceList
              .where(
                (h) =>
                    (h['name'] ?? '').toString().toLowerCase().contains(q) ||
                    (h['employeeId'] ?? '').toString().toLowerCase().contains(
                      q,
                    ) ||
                    (h['department'] ?? '').toString().toLowerCase().contains(
                      q,
                    ),
              )
              .toList();
    });
  }

  Future<void> _delete(int? id, String empId, String name) async {
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
            title: Text('Delete HOD', style: ErpTypography.headlineSmall),
            content: Text(
              'Are you sure you want to delete $name ($empId)? All credentials and records will be removed.',
              style: ErpTypography.bodyMedium,
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
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteHod(id);
        ErpSnackbar.show(
          context,
          message: 'HOD deleted successfully.',
          type: ErpBadgeType.success,
        );
        await _fetchHods();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error deleting HOD: $e',
          type: ErpBadgeType.danger,
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _openForm({Map<String, dynamic>? hod}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _HodFormDialog(
            hod: hod,
            onSave: (data, password) async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                if (hod == null) {
                  await _apiService.createHod(data, password!);
                  ErpSnackbar.show(
                    context,
                    message: 'HOD registered successfully.',
                    type: ErpBadgeType.success,
                  );
                } else {
                  await _apiService.updateHod(
                    hod['id'] as int,
                    data,
                    password: password,
                  );
                  ErpSnackbar.show(
                    context,
                    message: 'HOD updated successfully.',
                    type: ErpBadgeType.success,
                  );
                }
                await _fetchHods();
              } catch (e) {
                ErpSnackbar.show(
                  context,
                  message: 'Error saving HOD: $e',
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
        message: 'No departments found',
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
            subtitle: 'Tap a department to view HODs',
          ),
          Expanded(
            child: RefreshIndicator(
              color: ErpColors.primary,
              onRefresh: _fetchHods,
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
                        _filtered = _departmentMap[_selectedDepartment!] ?? [];
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
                          '$count HOD(s)',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title:
            _selectedDepartment != null
                ? 'HODs - $_selectedDepartment'
                : 'Manage HODs',
        subtitle:
            _selectedDepartment != null
                ? '${_filtered.length} executives'
                : 'Select a department',
        onBack:
            _selectedDepartment != null
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
          'Add HOD',
          style: ErpTypography.button.copyWith(color: Colors.white),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchHods)
              : Column(
                children: [
                  if (_selectedDepartment != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: ErpSearchBar(
                        controller: _searchController,
                        onChanged: (_) {},
                        hint: 'Search by name, ID, or department...',
                      ),
                    ),
                  Expanded(
                    child:
                        _selectedDepartment == null
                            ? _buildDepartmentsGrid()
                            : _filtered.isEmpty
                            ? const ErpEmptyState(
                              message: 'No HOD profiles found',
                              subtitle: 'Add a new HOD using the button below.',
                              icon: Icons.supervisor_account_outlined,
                            )
                            : RefreshIndicator(
                              color: ErpColors.primary,
                              onRefresh: _fetchHods,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                padding: const EdgeInsets.all(16),
                                itemBuilder: (ctx, i) {
                                  final h = _filtered[i];
                                  final name =
                                      h['name'] ?? 'Head of Department';
                                  final initial =
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'H';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ErpCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: ErpColors.resultsSurface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    ErpRadius.md,
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              initial,
                                              style: ErpTypography
                                                  .headlineMedium
                                                  .copyWith(
                                                    color: ErpColors.results,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style:
                                                      ErpTypography.titleMedium,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${h['employeeId'] ?? ''} · ${h['department'] ?? 'N/A'}',
                                                  style:
                                                      ErpTypography.bodySmall,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  h['email'] ?? '',
                                                  style: ErpTypography.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: ErpColors.textMuted,
                                            ),
                                            onPressed: () => _openForm(hod: h),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: ErpColors.danger,
                                            ),
                                            onPressed:
                                                () => _delete(
                                                  h['id'] as int?,
                                                  h['employeeId'] ?? '',
                                                  name,
                                                ),
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
              ),
    );
  }
}

// ── HOD Form Dialog ────────────────────────────────────────────
class _HodFormDialog extends StatefulWidget {
  final Map<String, dynamic>? hod;
  final Function(Map<String, dynamic> data, String? password) onSave;
  const _HodFormDialog({this.hod, required this.onSave});

  @override
  State<_HodFormDialog> createState() => _HodFormDialogState();
}

class _HodFormDialogState extends State<_HodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  late final _empId = TextEditingController(
    text: widget.hod?['employeeId'] ?? '',
  );
  late final _name = TextEditingController(text: widget.hod?['name'] ?? '');
  late final _gender = TextEditingController(text: widget.hod?['gender'] ?? '');
  late final _dob = TextEditingController(text: widget.hod?['dob'] ?? '');
  late final _dept = TextEditingController(
    text: widget.hod?['department'] ?? '',
  );
  late final _desig = TextEditingController(
    text: widget.hod?['designation'] ?? 'HOD',
  );
  late final _phone = TextEditingController(text: widget.hod?['phone'] ?? '');
  late final _email = TextEditingController(text: widget.hod?['email'] ?? '');
  late final _address = TextEditingController(
    text: widget.hod?['address'] ?? '',
  );
  final _password = TextEditingController();
  final _currentPassword = TextEditingController(text: "Loading...");

  @override
  void initState() {
    super.initState();
    if (widget.hod != null) {
      _fetchCurrentPassword(widget.hod!['id'] as int);
    }
  }

  Future<void> _fetchCurrentPassword(int id) async {
    try {
      final AdminApiService apiService = AdminApiService();
      String pwd = await apiService.getHodPassword(id);
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
      _phone,
      _email,
      _address,
      _password,
      _currentPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.hod != null;
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
              isEdit ? 'Edit HOD Profile' : 'Register HOD',
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
                        'Employee ID (e.g. HOD301)',
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          style: ErpTypography.bodyLarge,
                          decoration: InputDecoration(
                            labelText:
                                isEdit
                                    ? 'New Password (Optional)'
                                    : 'Initial Password',
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
                          validator:
                              (v) =>
                                  (!isEdit && (v == null || v.trim().isEmpty))
                                      ? 'Password is required'
                                      : null,
                        ),
                      ),
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
                            child: _field(_dept, 'Department', hint: 'MECH'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(_desig, 'Designation', hint: 'HOD'),
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
                            'phone': _phone.text.trim(),
                            'email': _email.text.trim(),
                            'address': _address.text.trim(),
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

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    IconData? icon,
    bool required = false,
    bool enabled = true,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: lines,
      enabled: enabled,
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
