import 'package:flutter/material.dart';
import '../models/fees_model.dart';
import '../models/teacher.dart';
import '../services/fee_service.dart';
import '../services/teacher_service.dart';
import '../theme/teacher_theme.dart';
import 'student_fee_detail_screen.dart';

/// Class Incharge Fees Dashboard
/// Shows summary stats + filterable student fee list for the assigned class.
class FeesDashboardScreen extends StatefulWidget {
  final String employeeId;
  final String department;
  final String semester;
  final String section;
  final String academicYear;

  const FeesDashboardScreen({
    super.key,
    required this.employeeId,
    required this.department,
    required this.semester,
    required this.section,
    required this.academicYear,
  });

  @override
  State<FeesDashboardScreen> createState() => _FeesDashboardScreenState();
}

class _FeesDashboardScreenState extends State<FeesDashboardScreen> {
  final FeeService _api = FeeService();
  final TeacherService _teacherApi = TeacherService();
  Teacher? _teacherProfile;

  FeeDashboardModel? _dashboard;
  List<ConsolidatedStudentFee> _allConsolidated = [];
  List<ConsolidatedStudentFee> _filtered = [];
  bool _loading = true;
  String _error = '';
  String _statusFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final _statuses = ['ALL', 'PAID', 'PARTIALLY_PAID', 'PENDING', 'OVERDUE'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ConsolidatedStudentFee> _consolidateFees(List<StudentFeeModel> rawList) {
    final Map<String, List<StudentFeeModel>> grouped = {};
    for (var item in rawList) {
      grouped.putIfAbsent(item.studentId, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final first = items.first;

      final total = items.fold<double>(0, (sum, item) => sum + item.totalFee);
      final paid = items.fold<double>(0, (sum, item) => sum + item.amountPaid);
      final balance = items.fold<double>(
        0,
        (sum, item) => sum + item.balanceAmount,
      );

      String status = 'PENDING';
      if (balance <= 0) {
        status = 'PAID';
      } else if (paid > 0) {
        status = 'PARTIALLY_PAID';
      } else {
        final hasOverdue = items.any((item) => item.paymentStatus == 'OVERDUE');
        if (hasOverdue) status = 'OVERDUE';
      }

      return ConsolidatedStudentFee(
        studentId: first.studentId,
        studentName: first.studentName,
        rollNumber: first.rollNumber,
        department: first.department,
        semester: first.semester,
        section: first.section,
        academicYear: first.academicYear,
        totalFee: total,
        amountPaid: paid,
        balanceAmount: balance,
        paymentStatus: status,
        items: items,
      );
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      if (_teacherProfile == null) {
        try {
          _teacherProfile = await _teacherApi.getTeacherProfile(
            widget.employeeId,
          );
        } catch (e) {
          _teacherProfile = Teacher(
            employeeId: widget.employeeId,
            name:
                (widget.employeeId == 'EMP006' || widget.employeeId == 'FAC001')
                    ? 'Vinitha Mam'
                    : 'Faculty Member',
            department: widget.department,
            designation:
                (widget.employeeId == 'EMP006' || widget.employeeId == 'FAC001')
                    ? 'Assistant Professor'
                    : 'Faculty',
            qualification: '',
            experience: '',
            phone: '',
            email: '',
            address: '',
          );
        }
      }

      if (!_isAuthorizedForClass()) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      final dashboard = await _api.getDashboard(
        department: widget.department,
        semester: widget.semester,
        section: widget.section,
        academicYear: widget.academicYear,
      );
      final fees = await _api.getFeesForClass(
        department: widget.department,
        semester: widget.semester,
        section: widget.section,
        academicYear: widget.academicYear,
      );
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _allConsolidated = _consolidateFees(fees);
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    _filtered =
        _allConsolidated.where((f) {
          final matchStatus =
              _statusFilter == 'ALL' || f.paymentStatus == _statusFilter;
          final q = _searchQuery.toLowerCase();
          final matchSearch =
              q.isEmpty ||
              f.studentName.toLowerCase().contains(q) ||
              f.rollNumber.toLowerCase().contains(q);
          return matchStatus && matchSearch;
        }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return TeacherColors.success;
      case 'PARTIALLY_PAID':
        return TeacherColors.warning;
      case 'OVERDUE':
        return TeacherColors.danger;
      default:
        return TeacherColors.info;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'PARTIALLY_PAID':
        return 'Partial';
      case 'OVERDUE':
        return 'Overdue';
      case 'WAIVED':
        return 'Waived';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fees Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${widget.department} · Sem ${widget.semester} · Sec ${widget.section} · ${widget.academicYear}',
              style: const TextStyle(
                fontSize: 11,
                color: TeacherColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: TeacherColors.navy),
            onPressed: _loadData,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: TeacherColors.navy),
              )
              : _error.isNotEmpty
              ? _buildError()
              : !_isAuthorizedForClass()
              ? _buildRestrictedPortalView()
              : RefreshIndicator(
                color: TeacherColors.navy,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_dashboard != null) _buildSummaryGrid(_dashboard!),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildStatusFilterChips(),
                    const SizedBox(height: 12),
                    Text(
                      'Students (${_filtered.length})',
                      style: TeacherTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    ..._filtered.map(
                      (f) => _StudentFeeCard(
                        fee: f,
                        statusColor: _statusColor(f.paymentStatus),
                        statusLabel: _statusLabel(f.paymentStatus),
                        onTap: () {
                          if (f.items.length == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => StudentFeeDetailScreen(
                                      fee: f.items.first,
                                      employeeId: widget.employeeId,
                                      onPaymentRecorded: _loadData,
                                    ),
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (sheetCtx) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${f.studentName} - Fee Status details',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: TeacherColors.navy,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Flexible(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: f.items.length,
                                          itemBuilder: (ctx, idx) {
                                            final item = f.items[idx];
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                item.feeCategory,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Total: ₹${item.totalFee.toStringAsFixed(0)} | Paid: ₹${item.amountPaid.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      TeacherColors.textMuted,
                                                ),
                                              ),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(
                                                    item.paymentStatus,
                                                  ).withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _statusLabel(
                                                    item.paymentStatus,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _statusColor(
                                                      item.paymentStatus,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(sheetCtx);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          _,
                                                        ) => StudentFeeDetailScreen(
                                                          fee: item,
                                                          employeeId:
                                                              widget.employeeId,
                                                          onPaymentRecorded:
                                                              _loadData,
                                                        ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                    if (_filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: TeacherColors.divider,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No students match the filter.',
                                style: TeacherTextStyles.bodyMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryGrid(FeeDashboardModel d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: TeacherTextStyles.heading3),
        const SizedBox(height: 10),
        // Amount row
        Container(
          decoration: TeacherDecorations.navyCard(radius: 16),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AmountStat(
                label: 'Total',
                amount: d.totalFeeAmount,
                color: Colors.white,
              ),
              _vDivider(),
              _AmountStat(
                label: 'Collected',
                amount: d.collectedAmount,
                color: const Color(0xFF7DF9C0),
              ),
              _vDivider(),
              _AmountStat(
                label: 'Outstanding',
                amount: d.outstandingAmount,
                color: const Color(0xFFFF8A8A),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Count row
        Row(
          children: [
            _StatTile(
              label: 'Total',
              value: '${d.totalStudents}',
              color: TeacherColors.navy,
            ),
            const SizedBox(width: 8),
            _StatTile(
              label: 'Paid',
              value: '${d.paidCount}',
              color: TeacherColors.success,
            ),
            const SizedBox(width: 8),
            _StatTile(
              label: 'Partial',
              value: '${d.partiallyPaidCount}',
              color: TeacherColors.warning,
            ),
            const SizedBox(width: 8),
            _StatTile(
              label: 'Pending',
              value: '${d.pendingCount}',
              color: TeacherColors.info,
            ),
            const SizedBox(width: 8),
            _StatTile(
              label: 'Overdue',
              value: '${d.overdueCount}',
              color: TeacherColors.danger,
            ),
          ],
        ),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white24);

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged:
          (v) => setState(() {
            _searchQuery = v;
            _applyFilter();
          }),
      decoration: const InputDecoration(
        hintText: 'Search name or roll number…',
        prefixIcon: Icon(
          Icons.search,
          color: TeacherColors.textSecondary,
          size: 20,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _statuses.map((s) {
              final sel = _statusFilter == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    s == 'ALL' ? 'All' : _statusLabel(s),
                    style: TextStyle(
                      fontSize: 12,
                      color: sel ? Colors.white : TeacherColors.textPrimary,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: sel,
                  selectedColor: TeacherColors.navy,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: TeacherColors.divider),
                  onSelected:
                      (_) => setState(() {
                        _statusFilter = s;
                        _applyFilter();
                      }),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: TeacherColors.danger,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TeacherTextStyles.bodyMuted,
            ),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  bool _isAuthorizedForClass() {
    final empId = widget.employeeId.toUpperCase();
    final dept = widget.department.toUpperCase();
    final sem = widget.semester.toUpperCase();
    final sec = widget.section.toUpperCase();

    // HOD and Dean bypass restriction
    final designationVal = _teacherProfile?.designation.toUpperCase() ?? '';
    final isHodOrDean =
        designationVal.contains('HOD') ||
        designationVal.contains('DEAN') ||
        empId.contains('HOD') ||
        empId.contains('DEAN') ||
        empId == 'HOD001' ||
        empId == 'DEAN001';
    if (isHodOrDean) return true;

    // Vinitha Mam (EMP006) is class incharge of 4th year CSE A and B
    if (empId == 'EMP006' || empId == 'EMPLOYEE006' || empId == 'FAC001') {
      final isCSE = dept == 'CSE';
      final is4thYear = sem == 'VII' || sem == 'VIII';
      final isSecAOrB = sec == 'A' || sec == 'B';
      return isCSE && is4thYear && isSecAOrB;
    }

    return false;
  }

  Widget _buildRestrictedPortalView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TeacherColors.danger.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              color: TeacherColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TeacherColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your faculty account does not have Class Incharge authorization for:\n${widget.department} · Sem ${widget.semester} · Sec ${widget.section}\n\nOnly the assigned Class Incharge, HOD, or Dean is authorized to view and audit student fees.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: TeacherColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: TeacherColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _AmountStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StudentFeeCard extends StatelessWidget {
  final ConsolidatedStudentFee fee;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _StudentFeeCard({
    required this.fee,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: TeacherDecorations.card(radius: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TeacherColors.navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  fee.studentName.isNotEmpty
                      ? fee.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: TeacherColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + roll
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fee.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fee.rollNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TeacherColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _feeChip(
                        '₹${fee.totalFee.toStringAsFixed(0)}',
                        TeacherColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      _feeChip(
                        'Paid ₹${fee.amountPaid.toStringAsFixed(0)}',
                        TeacherColors.success,
                      ),
                      const SizedBox(width: 6),
                      if (fee.balanceAmount > 0)
                        _feeChip(
                          'Due ₹${fee.balanceAmount.toStringAsFixed(0)}',
                          TeacherColors.danger,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeChip(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    );
  }
}

class ConsolidatedStudentFee {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String department;
  final String semester;
  final String section;
  final String academicYear;
  final double totalFee;
  final double amountPaid;
  final double balanceAmount;
  final String paymentStatus;
  final List<StudentFeeModel> items;

  ConsolidatedStudentFee({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.department,
    required this.semester,
    required this.section,
    required this.academicYear,
    required this.totalFee,
    required this.amountPaid,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.items,
  });
}
