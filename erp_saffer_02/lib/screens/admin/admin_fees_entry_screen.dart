import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/student.dart';
import '../../models/fee_model.dart';
import '../../services/admin_api_service.dart';
import '../../services/fee_service.dart';

class AdminFeesEntryScreen extends StatefulWidget {
  final String? lockedDept;
  final String? lockedYear;
  final String? lockedSec;
  final String? academicYear;

  const AdminFeesEntryScreen({
    super.key,
    this.lockedDept,
    this.lockedYear,
    this.lockedSec,
    this.academicYear,
  });

  @override
  State<AdminFeesEntryScreen> createState() => _AdminFeesEntryScreenState();
}

class _AdminFeesEntryScreenState extends State<AdminFeesEntryScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  final FeeService _feeService = FeeService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  String _selectedDept = 'CSE';
  String _selectedAcademicYear = '2026-27';
  String _selectedYear = '3';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _departments = [
    'CSE',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
    'IT',
  ];
  final List<String> _academicYears = ['2024-25', '2025-26', '2026-27'];
  final List<String> _years = ['1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    if (widget.lockedDept != null) _selectedDept = widget.lockedDept!;
    if (widget.lockedYear != null) _selectedYear = widget.lockedYear!;
    if (widget.academicYear != null)
      _selectedAcademicYear = widget.academicYear!;
    _fetchStudents();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _adminApiService.getAllStudents();
      setState(() {
        _students = list;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load student list: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents =
          _students.where((s) {
            final matchDept =
                s.department.toUpperCase() == _selectedDept.toUpperCase();
            final matchYear = s.year.toString().trim() == _selectedYear.trim();
            final matchSec =
                widget.lockedSec == null ||
                s.section.toUpperCase() == widget.lockedSec!.toUpperCase();
            final matchSearch =
                q.isEmpty ||
                s.name.toLowerCase().contains(q) ||
                s.id.toLowerCase().contains(q) ||
                s.rollNumber.toLowerCase().contains(q);
            return matchDept && matchYear && matchSec && matchSearch;
          }).toList();
    });
  }

  void _showFeesDialog(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _FeeAllocationDialog(
            student: student,
            academicYear: _selectedAcademicYear,
            feeService: _feeService,
            onSaveSuccess: () {
              setState(() {});
              ErpSnackbar.show(
                context,
                message: 'Fees allocated for ${student.name}.',
                type: ErpBadgeType.success,
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Academic Fees Entry',
        subtitle: 'Configure fee structure per student',
      ),
      body: Column(
        children: [
          // ── Filter Panel ──────────────────────────────────────
          if (widget.lockedDept == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: ErpCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ErpDropdown(
                            label: 'Academic Year',
                            value: _selectedAcademicYear,
                            items: _academicYears,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedAcademicYear = v);
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ErpDropdown(
                            label: 'Department',
                            value: _selectedDept,
                            items: _departments,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedDept = v);
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ErpDropdown(
                      label: 'Year of Study',
                      value: _selectedYear,
                      items: _years,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedYear = v);
                          _applyFilters();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          // ── Search ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErpSearchBar(
              controller: _searchController,
              hint: 'Search by name, ID, roll number…',
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 10),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child:
                _isLoading
                    ? const _FeeEntrySkeleton()
                    : _errorMessage != null
                    ? ErpErrorState(
                      message: _errorMessage!,
                      onRetry: _fetchStudents,
                    )
                    : _filteredStudents.isEmpty
                    ? const ErpEmptyState(
                      message: 'No students match the selected filters',
                      icon: Icons.account_balance_wallet_outlined,
                    )
                    : RefreshIndicator(
                      color: ErpColors.primary,
                      onRefresh: _fetchStudents,
                      child: ListView.builder(
                        itemCount: _filteredStudents.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (ctx, i) {
                          final s = _filteredStudents[i];
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
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: ErpColors.feesSurface,
                                      borderRadius: BorderRadius.circular(
                                        ErpRadius.md,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      s.name.isNotEmpty
                                          ? s.name[0].toUpperCase()
                                          : 'S',
                                      style: ErpTypography.headlineSmall
                                          .copyWith(color: ErpColors.fees),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: ErpTypography.titleMedium,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'ID: ${s.id} · Roll: ${s.rollNumber.isEmpty ? 'N/A' : s.rollNumber}',
                                          style: ErpTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  FutureBuilder<List<Fee>>(
                                    future: _feeService.getFees(s.id),
                                    builder: (_, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: ErpColors.fees,
                                          ),
                                        );
                                      }
                                      final fees = snap.data ?? [];
                                      final configured = fees.any(
                                        (f) =>
                                            f.academicYear
                                                .toUpperCase()
                                                .trim() ==
                                            _selectedAcademicYear
                                                .toUpperCase()
                                                .trim(),
                                      );

                                      return configured
                                          ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const ErpStatusBadge(
                                                label: 'Set',
                                                type: ErpBadgeType.success,
                                                compact: true,
                                              ),
                                              const SizedBox(width: 8),
                                              _SmallBtn(
                                                label: 'Edit',
                                                icon: Icons.edit_outlined,
                                                color: ErpColors.warning,
                                                onTap: () => _showFeesDialog(s),
                                              ),
                                            ],
                                          )
                                          : _SmallBtn(
                                            label: 'Configure',
                                            icon:
                                                Icons
                                                    .add_circle_outline_rounded,
                                            color: ErpColors.primary,
                                            onTap: () => _showFeesDialog(s),
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
      ),
    );
  }
}

class _FeeEntrySkeleton extends StatelessWidget {
  const _FeeEntrySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

// ── Small Action Button ───────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ErpRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: ErpTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clean Dropdown ────────────────────────────────────────────
class _ErpDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _ErpDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ErpTypography.titleSmall),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          style: ErpTypography.bodyMedium.copyWith(
            color: ErpColors.textPrimary,
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items:
              items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
        ),
      ],
    );
  }
}

// ── Fee Allocation Dialog ─────────────────────────────────────
class _FeeAllocationDialog extends StatefulWidget {
  final Student student;
  final String academicYear;
  final FeeService feeService;
  final VoidCallback onSaveSuccess;
  const _FeeAllocationDialog({
    required this.student,
    required this.academicYear,
    required this.feeService,
    required this.onSaveSuccess,
  });

  @override
  State<_FeeAllocationDialog> createState() => _FeeAllocationDialogState();
}

class _FeeAllocationDialogState extends State<_FeeAllocationDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _tuition = TextEditingController(text: '65000');
  late final _mess = TextEditingController(text: '22000');
  late final _training = TextEditingController(text: '20000');
  late final _other = TextEditingController(text: '1000');
  late final _transport = TextEditingController(text: '34000');
  late final _hostel = TextEditingController(text: '80000');

  String _selectedSem = 'Semester VII';
  final List<String> _semesters = [
    'Semester I',
    'Semester II',
    'Semester III',
    'Semester IV',
    'Semester V',
    'Semester VI',
    'Semester VII',
    'Semester VIII',
  ];

  bool _isDayscholar = true;
  bool _optedBus = false;
  bool _isSaving = false;
  bool _isLoadingExisting = true;

  List<Fee> _existingFees = [];
  Map<String, double> _categoryPaidAmounts = {};

  @override
  void initState() {
    super.initState();
    final y = int.tryParse(widget.student.year.toString()) ?? 1;
    _selectedSem =
        y == 1
            ? 'Semester I'
            : y == 2
            ? 'Semester III'
            : y == 3
            ? 'Semester V'
            : 'Semester VII';
    _loadExistingFees();
  }

  @override
  void dispose() {
    for (final c in [_tuition, _mess, _training, _other, _transport, _hostel]) {
      c.dispose();
    }
    super.dispose();
  }

  String _toRoman(String display) {
    const map = {
      'Semester I': 'I',
      'Semester II': 'II',
      'Semester III': 'III',
      'Semester IV': 'IV',
      'Semester V': 'V',
      'Semester VI': 'VI',
      'Semester VII': 'VII',
      'Semester VIII': 'VIII',
    };
    return map[display] ?? display;
  }

  Future<void> _loadExistingFees() async {
    setState(() => _isLoadingExisting = true);
    try {
      final list = await widget.feeService.getFees(widget.student.id);
      setState(() {
        _existingFees = list;
        _isLoadingExisting = false;
      });
      _updateFromExisting();
    } catch (_) {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  void _updateFromExisting() {
    final sem = _toRoman(_selectedSem).toUpperCase().trim();
    final ay = widget.academicYear.toUpperCase().trim();
    final current =
        _existingFees
            .where(
              (f) =>
                  f.academicYear.toUpperCase().trim() == ay &&
                  f.semester.toUpperCase().trim() == sem,
            )
            .toList();
    final Map<String, double> paid = {};
    for (var f in current) {
      paid[f.particular.toLowerCase()] = f.amountPaid;
    }
    setState(() => _categoryPaidAmounts = paid);
    if (current.isNotEmpty) {
      double t = 0, m = 0, tr = 0, o = 0, trans = 0, h = 0;
      for (var f in current) {
        final k = f.particular.toLowerCase();
        if (k.contains('tuition') || k.contains('tution')) {
          t = f.amount;
        } else if (k.contains('mess')) {
          m = f.amount;
        } else if (k.contains('training')) {
          tr = f.amount;
        } else if (k.contains('transport') || k.contains('bus')) {
          trans = f.amount;
        } else if (k.contains('hostel')) {
          h = f.amount;
        } else {
          o = f.amount;
        }
      }
      setState(() {
        _tuition.text = t.toStringAsFixed(0);
        _mess.text = m.toStringAsFixed(0);
        _training.text = tr.toStringAsFixed(0);
        _other.text = o.toStringAsFixed(0);
        _transport.text = trans > 0 ? trans.toStringAsFixed(0) : '34000';
        _hostel.text = h > 0 ? h.toStringAsFixed(0) : '80000';
        _optedBus = trans > 0;
        _isDayscholar = h == 0;
      });
    } else {
      setState(() {
        _tuition.text = '65000';
        _mess.text = '22000';
        _training.text = '20000';
        _other.text = '1000';
        _transport.text = '34000';
        _hostel.text = '80000';
        _optedBus = false;
        _isDayscholar = true;
      });
    }
  }

  double get _tuitionVal => double.tryParse(_tuition.text) ?? 0;
  double get _messVal => double.tryParse(_mess.text) ?? 0;
  double get _trainingVal => double.tryParse(_training.text) ?? 0;
  double get _otherVal => double.tryParse(_other.text) ?? 0;
  double get _transportVal =>
      _isDayscholar && _optedBus ? (double.tryParse(_transport.text) ?? 0) : 0;
  double get _hostelVal =>
      !_isDayscholar ? (double.tryParse(_hostel.text) ?? 0) : 0;
  double get _grandTotal =>
      _tuitionVal +
      _messVal +
      _trainingVal +
      _otherVal +
      _transportVal +
      _hostelVal;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.feeService.configureCustomFees(
        studentId: widget.student.id,
        academicYear: widget.academicYear,
        semester: _toRoman(_selectedSem),
        tuitionFee: _tuitionVal,
        messFee: _messVal,
        trainingFee: _trainingVal,
        otherFee: _otherVal,
        transportFee: _transportVal,
        hostelFee: _hostelVal,
      );
      if (mounted) Navigator.pop(context);
      widget.onSaveSuccess();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ErpSnackbar.show(
          context,
          message: 'Error: $e',
          type: ErpBadgeType.danger,
        );
      }
    }
  }

  Widget _feeField(
    String label,
    TextEditingController c,
    String key,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      style: ErpTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        prefixStyle: ErpTypography.bodyMedium.copyWith(color: ErpColors.fees),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = double.tryParse(v);
        if (n == null) return 'Enter valid number';
        if (n < 0) return 'Must be positive';
        final paid = _categoryPaidAmounts[key.toLowerCase()] ?? 0.0;
        if (n < paid) {
          return 'Cannot be below paid amount (₹${paid.toStringAsFixed(0)})';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _previousStatus() {
    final sem = _toRoman(_selectedSem).toUpperCase().trim();
    final ay = widget.academicYear.toUpperCase().trim();
    final legacy =
        _existingFees.where((f) {
          final isCurrent =
              f.academicYear.toUpperCase().trim() == ay &&
              f.semester.toUpperCase().trim() == sem;
          return !isCurrent;
        }).toList();
    if (legacy.isEmpty) return const SizedBox.shrink();
    final Map<String, List<Fee>> groups = {};
    for (var f in legacy) {
      groups
          .putIfAbsent('${f.academicYear} | Sem ${f.semester}', () => [])
          .add(f);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Fee Blocks',
          style: ErpTypography.titleSmall.copyWith(color: ErpColors.primary),
        ),
        const SizedBox(height: 8),
        ...groups.entries.map((e) {
          double total = 0, paid = 0;
          for (var f in e.value) {
            total += f.amount;
            paid += f.amountPaid;
          }
          final bal = total - paid;
          final type =
              bal <= 0
                  ? ErpBadgeType.success
                  : paid > 0
                  ? ErpBadgeType.warning
                  : ErpBadgeType.danger;
          final label =
              bal <= 0
                  ? 'Paid'
                  : paid > 0
                  ? 'Partial'
                  : 'Not Paid';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ErpColors.bgSubtle,
              borderRadius: BorderRadius.circular(ErpRadius.sm),
              border: Border.all(color: ErpColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: ErpTypography.labelMedium.copyWith(
                          color: ErpColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Total: ₹${total.toStringAsFixed(0)} · Paid: ₹${paid.toStringAsFixed(0)} · Due: ₹${bal.toStringAsFixed(0)}',
                        style: ErpTypography.caption,
                      ),
                    ],
                  ),
                ),
                ErpStatusBadge(label: label, type: type, compact: true),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
      backgroundColor: ErpColors.bgWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ErpColors.feesSurface,
                    borderRadius: BorderRadius.circular(ErpRadius.sm),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: ErpColors.fees,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allocate Fees', style: ErpTypography.headlineSmall),
                      Text(
                        '${widget.student.name} · AY ${widget.academicYear}',
                        style: ErpTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: ErpColors.textMuted,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            if (_isLoadingExisting)
              const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: ErpColors.primary),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Semester Selector
                        Text(
                          'Target Semester',
                          style: ErpTypography.titleSmall.copyWith(
                            color: ErpColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedSem,
                          isExpanded: true,
                          style: ErpTypography.bodyMedium.copyWith(
                            color: ErpColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items:
                              _semesters
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedSem = v);
                              _updateFromExisting();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        _previousStatus(),

                        // Base Fees
                        Text(
                          'Fee Components',
                          style: ErpTypography.titleSmall.copyWith(
                            color: ErpColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _feeField('Tuition Fee (₹)', _tuition, 'Tuition Fee'),
                        _feeField('Mess Fee (₹)', _mess, 'Mess Fee'),
                        _feeField(
                          'Training Fee (₹)',
                          _training,
                          'Training Fee',
                        ),
                        _feeField('Other Fee (₹)', _other, 'Other Fee'),

                        // Living Category
                        const SizedBox(height: 4),
                        Text(
                          'Student Residence',
                          style: ErpTypography.titleSmall.copyWith(
                            color: ErpColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _CategoryChip(
                                label: 'Dayscholar',
                                selected: _isDayscholar,
                                onTap:
                                    () => setState(() {
                                      _isDayscholar = true;
                                    }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CategoryChip(
                                label: 'Hosteller',
                                selected: !_isDayscholar,
                                onTap:
                                    () => setState(() {
                                      _isDayscholar = false;
                                      _optedBus = false;
                                    }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isDayscholar) ...[
                          Row(
                            children: [
                              Text(
                                'Opt-in College Bus?',
                                style: ErpTypography.bodyMedium,
                              ),
                              const Spacer(),
                              Switch(
                                value: _optedBus,
                                activeColor: ErpColors.accent,
                                onChanged: (v) => setState(() => _optedBus = v),
                              ),
                            ],
                          ),
                          if (_optedBus)
                            _feeField(
                              'Transport/Bus Fee (₹)',
                              _transport,
                              'Transport Fee',
                            ),
                        ] else
                          _feeField(
                            'Hostel Room & Board Fee (₹)',
                            _hostel,
                            'Hostel Fee',
                          ),

                        // Grand Total
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: ErpColors.feesSurface,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                            border: Border.all(
                              color: ErpColors.fees.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Allocated Total Plan',
                                style: ErpTypography.titleSmall.copyWith(
                                  color: ErpColors.fees,
                                ),
                              ),
                              Text(
                                '₹${_grandTotal.toStringAsFixed(0)}',
                                style: ErpTypography.headlineMedium.copyWith(
                                  color: ErpColors.fees,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ErpButton.secondary(
                    label: 'Cancel',
                    fullWidth: true,
                    onPressed:
                        (_isSaving || _isLoadingExisting)
                            ? null
                            : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ErpButton(
                    label: 'Submit',
                    fullWidth: true,
                    loading: _isSaving,
                    onPressed:
                        (_isSaving || _isLoadingExisting) ? null : _submit,
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ErpDuration.normal,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ErpColors.primary : ErpColors.bgWhite,
          borderRadius: BorderRadius.circular(ErpRadius.md),
          border: Border.all(
            color: selected ? ErpColors.primary : ErpColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: ErpTypography.titleSmall.copyWith(
            color: selected ? Colors.white : ErpColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
