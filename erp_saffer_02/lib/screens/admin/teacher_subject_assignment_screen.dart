import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';
import '../../teacher/models/teacher.dart';

class TeacherAssignmentManagementScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherAssignmentManagementScreen({super.key, required this.teacher});

  @override
  State<TeacherAssignmentManagementScreen> createState() =>
      _TeacherAssignmentManagementScreenState();
}

class _TeacherAssignmentManagementScreenState
    extends State<TeacherAssignmentManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _assignments = [];
  Map<String, dynamic>? _classIncharge;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sub = await _apiService.getTeacherAssignments(
        widget.teacher.employeeId,
      );
      final inc = await _apiService.getClassInchargeAssignmentForTeacher(
        widget.teacher.employeeId,
      );
      setState(() {
        _assignments = sub;
        _classIncharge = inc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAssignment(int id, String subjectName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
            title: Text(
              'Remove Assignment',
              style: ErpTypography.headlineSmall,
            ),
            content: Text(
              "Remove subject assignment for '$subjectName'?",
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
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        await _apiService.deleteSubjectAssignment(id);
        ErpSnackbar.show(
          context,
          message: 'Assignment removed.',
          type: ErpBadgeType.success,
        );
        _fetchAll();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error: $e',
          type: ErpBadgeType.danger,
        );
      }
    }
  }

  Future<void> _removeClassIncharge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
            title: Text(
              'Remove Class In-Charge',
              style: ErpTypography.headlineSmall,
            ),
            content: Text(
              'Remove this teacher from Class In-Charge role?',
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
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        await _apiService.removeClassIncharge(widget.teacher.employeeId);
        ErpSnackbar.show(
          context,
          message: 'Removed successfully.',
          type: ErpBadgeType.success,
        );
        _fetchAll();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error: $e',
          type: ErpBadgeType.danger,
        );
      }
    }
  }

  Future<void> _openAddAssignmentDialog() async {
    setState(() => _isLoading = true);
    late List<dynamic> academicYears;
    try {
      academicYears = await _apiService.getAllAcademicYears();
    } catch (e) {
      ErpSnackbar.show(
        context,
        message: 'Failed to load options: $e',
        type: ErpBadgeType.danger,
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = false);
    if (academicYears.isEmpty) {
      ErpSnackbar.show(
        context,
        message: 'Please define academic years first.',
        type: ErpBadgeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _AddAssignmentFormDialog(
            academicYears: academicYears,
            employeeId: widget.teacher.employeeId,
            teacherDepartment: widget.teacher.department,
            onSave: (data) async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _apiService.createSubjectAssignment(data);
                ErpSnackbar.show(
                  context,
                  message: 'Subject assigned successfully.',
                  type: ErpBadgeType.success,
                );
                _fetchAll();
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

  Future<void> _openAddClassInchargeDialog() async {
    setState(() => _isLoading = true);
    late List<dynamic> academicYears;
    try {
      academicYears = await _apiService.getAllAcademicYears();
    } catch (e) {
      ErpSnackbar.show(
        context,
        message: 'Failed to load options: $e',
        type: ErpBadgeType.danger,
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = false);
    if (academicYears.isEmpty) {
      ErpSnackbar.show(
        context,
        message: 'Please define academic years first.',
        type: ErpBadgeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _AddClassInchargeFormDialog(
            academicYears: academicYears,
            employeeId: widget.teacher.employeeId,
            teacherName: widget.teacher.name,
            teacherDepartment: widget.teacher.department,
            apiService: _apiService,
            onSave: (data) async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _apiService.assignClassIncharge(data);
                ErpSnackbar.show(
                  context,
                  message: 'Class In-Charge assigned.',
                  type: ErpBadgeType.success,
                );
                _fetchAll();
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
    final t = widget.teacher;
    final initials =
        t.name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Assignment Management',
        subtitle: t.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAll,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchAll)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Teacher Banner ───────────────────────────────
                    ErpCard(
                      color: ErpColors.primary,
                      shadow: [],
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(ErpRadius.md),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: ErpTypography.headlineMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: ErpTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${t.employeeId} · ${t.department}',
                                  style: ErpTypography.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.manage_accounts_rounded,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Class In-Charge ──────────────────────────────
                    ErpSectionHeader(
                      title: 'Class In-Charge',
                      trailing:
                          _classIncharge != null
                              ? IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: ErpColors.textMuted,
                                ),
                                onPressed: _openAddClassInchargeDialog,
                                tooltip: 'Change In-Charge',
                              )
                              : TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: ErpColors.primary,
                                ),
                                onPressed: _openAddClassInchargeDialog,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text(
                                  'Assign',
                                  style: ErpTypography.labelMedium.copyWith(
                                    color: ErpColors.primary,
                                  ),
                                ),
                              ),
                    ),
                    if (_classIncharge != null)
                      ErpCard(
                        padding: const EdgeInsets.all(16),
                        border: Border.all(
                          color: ErpColors.accent.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ErpColors.warningSurface,
                                borderRadius: BorderRadius.circular(
                                  ErpRadius.sm,
                                ),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: ErpColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Year ${_classIncharge!['year']} ${_classIncharge!['department']} — Section ${_classIncharge!['section']}',
                                    style: ErpTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Academic Year: ${_classIncharge!['academicYear']}',
                                    style: ErpTypography.caption,
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
                              onPressed: _removeClassIncharge,
                              tooltip: 'Remove In-Charge',
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No active Class In-Charge assignment.',
                          style: ErpTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Subject Assignments ──────────────────────────
                    ErpSectionHeader(
                      title: 'Subject Assignments',
                      trailing: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: ErpColors.primary,
                        ),
                        onPressed: _openAddAssignmentDialog,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          'Assign',
                          style: ErpTypography.labelMedium.copyWith(
                            color: ErpColors.primary,
                          ),
                        ),
                      ),
                    ),
                    if (_assignments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No subjects assigned yet.',
                          style: ErpTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assignments.length,
                        itemBuilder: (ctx, i) {
                          final a = _assignments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ErpCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: ErpColors.primarySurface,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      ErpRadius.sm,
                                                    ),
                                              ),
                                              child: Text(
                                                a['subjectCode'] ?? '',
                                                style: ErpTypography.caption
                                                    .copyWith(
                                                      color: ErpColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Sem ${a['semester']} · Sec ${a['section']}',
                                              style: ErpTypography.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          a['subjectName'] ?? '',
                                          style: ErpTypography.titleMedium,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Dept: ${a['department']} · ${a['academicYear']}',
                                          style: ErpTypography.caption,
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
                                        () => _deleteAssignment(
                                          a['id'],
                                          a['subjectName'] ?? '',
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Assign Subject Dialog
// ════════════════════════════════════════════════════════════════
class _AddAssignmentFormDialog extends StatefulWidget {
  final List<dynamic> academicYears;
  final String employeeId;
  final String teacherDepartment;
  final Function(Map<String, dynamic>) onSave;
  const _AddAssignmentFormDialog({
    required this.academicYears,
    required this.employeeId,
    required this.teacherDepartment,
    required this.onSave,
  });

  @override
  State<_AddAssignmentFormDialog> createState() =>
      _AddAssignmentFormDialogState();
}

class _AddAssignmentFormDialogState extends State<_AddAssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  int? _selectedSubjectId;
  String? _selectedAcademicYear;
  String _year = '1', _semester = 'I', _section = 'A';
  late final String _department = widget.teacherDepartment;
  List<dynamic> _filteredSubjects = [];
  bool _isLoadingSubjects = false;
  String? _subjectFetchError;

  static const _semesters = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
  static const _sections = ['A', 'B', 'C', 'D'];
  static const _years = ['1', '2', '3', '4'];

  List<String> _availableSems(String year) {
    if (year == '1') return ['I', 'II'];
    if (year == '2') return ['III', 'IV'];
    if (year == '3') return ['V', 'VI'];
    return ['VII', 'VIII'];
  }

  @override
  void initState() {
    super.initState();
    final active = widget.academicYears.firstWhere(
      (yr) => yr['isActive'] == true,
      orElse: () => null,
    );
    _selectedAcademicYear =
        active != null
            ? active['yearName']
            : (widget.academicYears.isNotEmpty
                ? widget.academicYears.first['yearName']
                : null);
    _semester = _availableSems(_year).first;
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
      _filteredSubjects = [];
      _selectedSubjectId = null;
      _subjectFetchError = null;
    });
    try {
      final semInt = _semesters.indexOf(_semester) + 1;
      final subs = await _apiService.getFilteredSubjects(
        _department,
        _year,
        semInt,
      );
      setState(() {
        _filteredSubjects = subs;
        if (subs.isNotEmpty) _selectedSubjectId = subs.first['id'];
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        _subjectFetchError = 'Failed to load subjects: $e';
        _isLoadingSubjects = false;
      });
    }
  }

  Widget _dd<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: ErpTypography.caption),
      const SizedBox(height: 4),
      DropdownButtonFormField<T>(
        value: value,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items:
            items
                .map(
                  (v) => DropdownMenuItem<T>(
                    value: v,
                    child: Text(display(v), style: ErpTypography.bodyMedium),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
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
            Text('Assign New Subject', style: ErpTypography.headlineMedium),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dd(
                        label: 'Academic Year Session',
                        value: _selectedAcademicYear,
                        items:
                            widget.academicYears
                                .map((yr) => yr['yearName'] as String)
                                .toList(),
                        display:
                            (v) =>
                                '${v!} ${widget.academicYears.firstWhere((yr) => yr['yearName'] == v, orElse: () => {})['isActive'] == true ? '(Active)' : ''}',
                        onChanged:
                            (v) => setState(() => _selectedAcademicYear = v),
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Department', style: ErpTypography.caption),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: _department,
                            enabled: false,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            style: ErpTypography.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              label: 'Year',
                              value: _year,
                              items: _years,
                              display: (v) => 'Year $v',
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _year = v;
                                    _semester = _availableSems(v).first;
                                  });
                                  _fetchSubjects();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              label: 'Semester',
                              value: _semester,
                              items: _availableSems(_year),
                              display: (v) => v,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _semester = v);
                                  _fetchSubjects();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _dd(
                        label: 'Section',
                        value: _section,
                        items: _sections,
                        display: (v) => 'Section $v',
                        onChanged: (v) => setState(() => _section = v!),
                      ),
                      const SizedBox(height: 14),
                      Text('Select Subject', style: ErpTypography.caption),
                      const SizedBox(height: 4),
                      if (_isLoadingSubjects)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ErpColors.primary,
                              ),
                            ),
                          ),
                        )
                      else if (_subjectFetchError != null)
                        Text(
                          _subjectFetchError!,
                          style: ErpTypography.bodySmall.copyWith(
                            color: ErpColors.danger,
                          ),
                        )
                      else if (_filteredSubjects.isEmpty)
                        Text(
                          'No matching subjects found.',
                          style: ErpTypography.bodySmall.copyWith(
                            color: ErpColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedSubjectId,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              _filteredSubjects
                                  .map(
                                    (s) => DropdownMenuItem<int>(
                                      value: s['id'],
                                      child: Text(
                                        '[${s['code']}] ${s['name']}',
                                        style: ErpTypography.bodyMedium,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedSubjectId = v),
                        ),
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
                    label: 'Assign',
                    fullWidth: true,
                    onPressed:
                        (_selectedSubjectId == null ||
                                _selectedAcademicYear == null)
                            ? null
                            : () {
                              if (_formKey.currentState!.validate()) {
                                widget.onSave({
                                  'subjectId': _selectedSubjectId,
                                  'academicYear': _selectedAcademicYear,
                                  'employeeId': widget.employeeId,
                                  'department': _department,
                                  'year': _year,
                                  'semester': _semester,
                                  'section': _section,
                                });
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

// ════════════════════════════════════════════════════════════════
// Assign Class In-Charge Dialog
// ════════════════════════════════════════════════════════════════
class _AddClassInchargeFormDialog extends StatefulWidget {
  final List<dynamic> academicYears;
  final String employeeId, teacherName, teacherDepartment;
  final AdminApiService apiService;
  final Function(Map<String, dynamic>) onSave;
  const _AddClassInchargeFormDialog({
    required this.academicYears,
    required this.employeeId,
    required this.teacherName,
    required this.teacherDepartment,
    required this.apiService,
    required this.onSave,
  });

  @override
  State<_AddClassInchargeFormDialog> createState() =>
      _AddClassInchargeFormDialogState();
}

class _AddClassInchargeFormDialogState
    extends State<_AddClassInchargeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAcademicYear;
  String _year = '1', _section = 'A';
  late final String _department = widget.teacherDepartment;
  Map<String, dynamic>? _existingIncharge;
  bool _isChecking = false;

  static const _sections = ['A', 'B', 'C', 'D'];
  static const _years = ['1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    final active = widget.academicYears.firstWhere(
      (yr) => yr['isActive'] == true,
      orElse: () => null,
    );
    _selectedAcademicYear =
        active != null
            ? active['yearName']
            : (widget.academicYears.isNotEmpty
                ? widget.academicYears.first['yearName']
                : null);
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    if (_selectedAcademicYear == null) return;
    setState(() {
      _isChecking = true;
      _existingIncharge = null;
    });
    try {
      final e = await widget.apiService.getClassInchargeAssignmentForClass(
        department: _department,
        year: _year,
        section: _section,
        academicYear: _selectedAcademicYear!,
      );
      if (mounted) setState(() => _existingIncharge = e);
    } catch (_) {
      // not found = no existing incharge, safe to ignore
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Widget _dd<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    items:
        items
            .map(
              (v) => DropdownMenuItem<T>(
                value: v,
                child: Text(display(v), style: ErpTypography.bodyMedium),
              ),
            )
            .toList(),
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final isSelf =
        _existingIncharge != null &&
        _existingIncharge!['employeeId'] == widget.employeeId;
    final isOther =
        _existingIncharge != null &&
        _existingIncharge!['employeeId'] != widget.employeeId;
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
            Text('Assign Class In-Charge', style: ErpTypography.headlineMedium),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _dd(
                        label: 'Academic Year',
                        value: _selectedAcademicYear,
                        items:
                            widget.academicYears
                                .map((yr) => yr['yearName'] as String)
                                .toList(),
                        display: (v) => v!,
                        onChanged: (v) {
                          setState(() => _selectedAcademicYear = v);
                          _checkExisting();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _department,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: ErpTypography.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              label: 'Year',
                              value: _year,
                              items: _years,
                              display: (v) => 'Year $v',
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _year = v);
                                  _checkExisting();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              label: 'Section',
                              value: _section,
                              items: _sections,
                              display: (v) => 'Section $v',
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _section = v);
                                  _checkExisting();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isChecking)
                        const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ErpColors.primary,
                            ),
                          ),
                        )
                      else if (isOther)
                        ErpCard(
                          color: ErpColors.warningSurface,
                          border: Border.all(
                            color: ErpColors.warning.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: ErpColors.warning,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Already Assigned',
                                    style: ErpTypography.titleMedium.copyWith(
                                      color: ErpColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Currently assigned to:\n${_existingIncharge!['teacherName']} (${_existingIncharge!['employeeId']})\n\nContinuing will replace the existing Class In-Charge.',
                                style: ErpTypography.bodySmall.copyWith(
                                  color: ErpColors.warning,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isSelf)
                        ErpCard(
                          color: ErpColors.successSurface,
                          border: Border.all(
                            color: ErpColors.success.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'This teacher is already the In-Charge for this class.',
                            style: ErpTypography.bodySmall.copyWith(
                              color: ErpColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                    label: isOther ? 'Replace Assignment' : 'Assign',
                    fullWidth: true,
                    onPressed:
                        (_selectedAcademicYear == null || isSelf)
                            ? null
                            : () {
                              if (_formKey.currentState!.validate()) {
                                widget.onSave({
                                  'employeeId': widget.employeeId,
                                  'department': _department,
                                  'year': _year,
                                  'section': _section,
                                  'academicYear': _selectedAcademicYear,
                                });
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
