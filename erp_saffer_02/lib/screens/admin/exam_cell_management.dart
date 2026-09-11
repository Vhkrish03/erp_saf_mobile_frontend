import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';

class ExamCellManagementScreen extends StatefulWidget {
  const ExamCellManagementScreen({super.key});

  @override
  State<ExamCellManagementScreen> createState() =>
      _ExamCellManagementScreenState();
}

class _ExamCellManagementScreenState extends State<ExamCellManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _apiService.getAllExamCellAdmins();
      setState(() {
        _admins = list;
        _filtered = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load Exam Cell officers: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered =
          _admins
              .where(
                (a) =>
                    (a['name'] ?? '').toString().toLowerCase().contains(q) ||
                    (a['employeeId'] ?? '').toString().toLowerCase().contains(
                      q,
                    ) ||
                    (a['designation'] ?? '').toString().toLowerCase().contains(
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
            title: Text('Delete Officer', style: ErpTypography.headlineSmall),
            content: Text(
              'Delete Exam Cell officer $name ($empId)? All records will be removed.',
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
        await _apiService.deleteExamCellAdmin(id);
        ErpSnackbar.show(
          context,
          message: 'Officer deleted successfully.',
          type: ErpBadgeType.success,
        );
        _fetch();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error: $e',
          type: ErpBadgeType.danger,
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _openForm({Map<String, dynamic>? admin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _ExamCellFormDialog(
            admin: admin,
            onSave: (data, password) async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                if (admin == null) {
                  await _apiService.createExamCellAdmin(data, password!);
                  ErpSnackbar.show(
                    context,
                    message: 'Exam Cell officer registered.',
                    type: ErpBadgeType.success,
                  );
                } else {
                  await _apiService.updateExamCellAdmin(
                    admin['id'] as int,
                    data,
                    password: password,
                  );
                  ErpSnackbar.show(
                    context,
                    message: 'Officer details updated.',
                    type: ErpBadgeType.success,
                  );
                }
                _fetch();
              } catch (e) {
                ErpSnackbar.show(
                  context,
                  message: 'Error: $e',
                  type: ErpBadgeType.danger,
                );
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Exam Cell Officers',
        subtitle: '${_admins.length} officers registered',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: Text(
          'Add Officer',
          style: ErpTypography.button.copyWith(color: Colors.white),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetch)
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: ErpSearchBar(
                      controller: _searchController,
                      onChanged: (_) {},
                      hint: 'Search by name, ID, or designation…',
                    ),
                  ),
                  Expanded(
                    child:
                        _filtered.isEmpty
                            ? const ErpEmptyState(
                              message: 'No Exam Cell officers found',
                              icon: Icons.analytics_outlined,
                            )
                            : RefreshIndicator(
                              color: ErpColors.primary,
                              onRefresh: _fetch,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                padding: const EdgeInsets.all(16),
                                itemBuilder: (ctx, i) {
                                  final a = _filtered[i];
                                  final name = a['name'] ?? 'Exam Cell Officer';
                                  final initial =
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'E';
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
                                              color:
                                                  ErpColors.assessmentSurface,
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
                                                    color: ErpColors.assessment,
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
                                                  '${a['employeeId'] ?? ''} · ${a['designation'] ?? 'Exam Cell'}',
                                                  style:
                                                      ErpTypography.bodySmall,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  a['email'] ?? '',
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
                                            onPressed:
                                                () => _openForm(admin: a),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: ErpColors.danger,
                                            ),
                                            onPressed:
                                                () => _delete(
                                                  a['id'] as int?,
                                                  a['employeeId'] ?? '',
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

class _ExamCellFormDialog extends StatefulWidget {
  final Map<String, dynamic>? admin;
  final Function(Map<String, dynamic> data, String? password) onSave;
  const _ExamCellFormDialog({this.admin, required this.onSave});

  @override
  State<_ExamCellFormDialog> createState() => _ExamCellFormDialogState();
}

class _ExamCellFormDialogState extends State<_ExamCellFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  late final _empId = TextEditingController(
    text: widget.admin?['employeeId'] ?? '',
  );
  late final _name = TextEditingController(text: widget.admin?['name'] ?? '');
  late final _gender = TextEditingController(
    text: widget.admin?['gender'] ?? '',
  );
  late final _dob = TextEditingController(text: widget.admin?['dob'] ?? '');
  late final _desig = TextEditingController(
    text: widget.admin?['designation'] ?? 'Exam Cell Officer',
  );
  late final _phone = TextEditingController(text: widget.admin?['phone'] ?? '');
  late final _email = TextEditingController(text: widget.admin?['email'] ?? '');
  late final _address = TextEditingController(
    text: widget.admin?['address'] ?? '',
  );
  final _password = TextEditingController();
  final _currentPassword = TextEditingController(text: "Loading...");

  @override
  void initState() {
    super.initState();
    if (widget.admin != null) {
      _fetchCurrentPassword(widget.admin!['id'] as int);
    }
  }

  Future<void> _fetchCurrentPassword(int id) async {
    try {
      final AdminApiService apiService = AdminApiService();
      String pwd = await apiService.getExamCellPassword(id);
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

  Widget _field(
    TextEditingController c,
    String label, {
    IconData? icon,
    bool required = false,
    bool enabled = true,
    String? hint,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      enabled: enabled,
      maxLines: lines,
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.admin != null;
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
              isEdit ? 'Edit Officer' : 'Register Exam Cell Officer',
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
                        'Employee ID (e.g. EXM001)',
                        icon: Icons.badge_outlined,
                        required: true,
                        enabled: !isEdit,
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
                      _field(
                        _desig,
                        'Designation',
                        hint: 'Exam Cell Officer / Dean of Exams',
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
                    fullWidth: true,
                    onPressed: () => Navigator.pop(context),
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
}
