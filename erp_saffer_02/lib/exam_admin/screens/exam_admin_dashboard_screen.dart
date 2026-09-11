import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../models/exam_cell_model.dart';
import '../services/exam_cell_service.dart';
import 'semester_result_entry_screen.dart';
import '../../screens/login_screen.dart';

class BatchGroup {
  final String department;
  final String semesterName;
  final String academicYear;
  final String examSession;
  final List<ExamCellResultModel> results;

  BatchGroup({
    required this.department,
    required this.semesterName,
    required this.academicYear,
    required this.examSession,
    required this.results,
  });

  String get key =>
      '${department}_${semesterName}_${academicYear}_$examSession';
}

/// Exam Cell Admin Dashboard
///
/// Allows Exam Cell officers to:
///  1. View results by status (DRAFT / VERIFIED / APPROVED / PUBLISHED)
///  2. Navigate to entry screen for new/edit results
///  3. Trigger verify/approve/publish workflow actions
class ExamAdminDashboardScreen extends StatefulWidget {
  final String performedBy;
  final String role;
  const ExamAdminDashboardScreen({
    super.key,
    required this.performedBy,
    this.role = 'EXAM_CELL',
  });

  @override
  State<ExamAdminDashboardScreen> createState() =>
      _ExamAdminDashboardScreenState();
}

class _ExamAdminDashboardScreenState extends State<ExamAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ExamCellService _service = ExamCellService();
  late TabController _tabCtrl;

  final List<String> _statuses = ['DRAFT', 'PUBLISHED'];
  final Map<String, List<ExamCellResultModel>> _results = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};
  final Set<String> _expandedBatches = {};
  final Set<int> _expandedStudents = {};
  final Set<int> _selectedToPublish = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statuses.length, vsync: this);
    _tabCtrl.addListener(() {
      final status = _statuses[_tabCtrl.index];
      _selectedToPublish.clear();
      if (!_results.containsKey(status)) _loadResults(status);
    });
    _loadResults('DRAFT');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadResults(String status) async {
    setState(() {
      _loading[status] = true;
      _errors[status] = null;
    });
    try {
      final res = await _service.getResultsByStatus(status);
      setState(() {
        _results[status] = res;
        _loading[status] = false;
      });
    } catch (e) {
      setState(() {
        _loading[status] = false;
        _errors[status] = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Exam Cell Dashboard',
        subtitle: 'Results & Examination Management',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: ErpColors.textOnPrimary),
            onPressed: () {
              final st = _statuses[_tabCtrl.index];
              _results.clear();
              _loadResults(st);
            },
          ),
          IconButton(
            tooltip: 'Enter New Result',
            icon: const Icon(
              Icons.add_circle,
              color: ErpColors.textOnPrimary,
              size: 26,
            ),
            onPressed: _goToEntryScreen,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
              color: ErpColors.textOnPrimary,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: ErpColors.accent,
          labelColor: ErpColors.accent,
          unselectedLabelColor: ErpColors.textOnPrimary.withValues(alpha: 0.38),
          labelStyle: ErpTypography.labelMedium.copyWith(
            color: ErpColors.accent,
          ),
          tabs:
              _statuses
                  .map((s) => Tab(text: s == 'DRAFT' ? 'APPROVAL' : s))
                  .toList(),
        ),
      ),

      body: TabBarView(
        controller: _tabCtrl,
        children:
            _statuses.map((status) {
              final isLoading = _loading[status] == true;
              final error = _errors[status];
              final list = _results[status];

              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: ErpColors.primary),
                );
              }
              if (error != null) {
                return _errorView(error, status);
              }
              if (list == null) {
                // Tab not loaded yet
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _loadResults(status),
                );
                return const Center(
                  child: CircularProgressIndicator(color: ErpColors.primary),
                );
              }
              if (list.isEmpty) {
                return _emptyView(status);
              }
              return _buildList(list, status);
            }).toList(),
      ),
    );
  }

  // ─── List View ────────────────────────────────────────────────────────────

  List<BatchGroup> _getBatchGroups(List<ExamCellResultModel> results) {
    final Map<String, BatchGroup> groups = {};
    for (var r in results) {
      final key =
          '${r.department}_${r.semesterName}_${r.academicYear}_${r.examSession}';
      if (!groups.containsKey(key)) {
        groups[key] = BatchGroup(
          department: r.department,
          semesterName: r.semesterName,
          academicYear: r.academicYear,
          examSession: r.examSession,
          results: [],
        );
      }
      groups[key]!.results.add(r);
    }
    return groups.values.toList();
  }

  Widget _buildList(List<ExamCellResultModel> results, String status) {
    final batchGroups = _getBatchGroups(results);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: batchGroups.length,
      itemBuilder: (_, i) => _buildBatchCard(batchGroups[i], status),
    );
  }

  Widget _buildBatchCard(BatchGroup batch, String status) {
    Color statusColor = _statusColor(status);
    bool isExpanded = _expandedBatches.contains(batch.key);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ErpColors.bgWhite,
        borderRadius: ErpRadius.card,
        border: Border.all(color: ErpColors.border),
        boxShadow: ErpShadow.card,
      ),
      child: Column(
        children: [
          // Batch Header Row
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBatches.remove(batch.key);
                } else {
                  _expandedBatches.add(batch.key);
                }
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_copy_outlined,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${batch.department} — ${batch.semesterName}',
                          style: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Year: ${batch.academicYear}  |  Session: ${batch.examSession}',
                          style: GoogleFonts.outfit(
                            color: ErpColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ErpColors.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${batch.results.length} Stud.',
                      style: GoogleFonts.outfit(
                        color: ErpColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: ErpColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(color: ErpColors.divider, height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              color: ErpColors.bgSubtle,
              child: Column(
                children:
                    batch.results.map((result) {
                      return _buildStudentItemRow(result, status);
                    }).toList(),
              ),
            ),
            _buildBatchActionsFooter(batch, status),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentItemRow(ExamCellResultModel result, String status) {
    bool isExpanded = _expandedStudents.contains(result.id ?? -1);
    bool isSelected = _selectedToPublish.contains(result.id ?? -1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ErpColors.bgWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ErpColors.border),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedStudents.remove(result.id ?? -1);
            } else {
              _expandedStudents.add(result.id ?? -1);
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (status == 'DRAFT')
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedToPublish.add(result.id ?? -1);
                          } else {
                            _selectedToPublish.remove(result.id ?? -1);
                          }
                        });
                      },
                      activeColor: ErpColors.primary,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.studentName ?? result.studentId,
                          style: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${result.studentId}  |  Reg: ${result.registerNumber ?? "N/A"}',
                          style: GoogleFonts.outfit(
                            color: ErpColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'SGPA',
                        style: GoogleFonts.outfit(
                          color: ErpColors.textMuted,
                          fontSize: 8,
                        ),
                      ),
                      Text(
                        result.sgpa > 0
                            ? result.sgpa.toStringAsFixed(2)
                            : 'N/A',
                        style: GoogleFonts.outfit(
                          color: ErpColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, color: ErpColors.border),
                ),
                Text('Subject Marks:', style: ErpTypography.labelSmall),
                const SizedBox(height: 8),
                if (result.subjects.isNotEmpty)
                  ...result.subjects.map(
                    (sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sub.subjectName,
                              style: ErpTypography.bodySmall,
                            ),
                          ),
                          Text(
                            '${sub.marksObtained ?? 0} / ${sub.maxMarks ?? 100}  (${sub.grade ?? "U"})',
                            style: ErpTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  sub.resultStatus == 'PASS'
                                      ? ErpColors.success
                                      : ErpColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildIndividualActions(result, status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIndividualActions(
    ExamCellResultModel result,
    String status,
  ) {
    List<Widget> actions = [];

    if (status == 'DRAFT') {
      actions.add(
        _actionBtn(
          'Edit',
          Icons.edit_outlined,
          ErpColors.textMuted,
          () => _goToEditScreen(result),
        ),
      );
      actions.add(const SizedBox(width: 8));
      actions.add(
        _actionBtn(
          'Publish ✓',
          Icons.publish,
          ErpColors.success,
          () => _confirm(
            'Publish result for ${result.studentName}?',
            () => _doPublish(result.id!),
          ),
        ),
      );
    } else if (status == 'PUBLISHED') {
      actions.add(
        _actionBtn(
          'View Audit',
          Icons.history,
          ErpColors.textMuted,
          () => _showAuditTrail(result.id!),
        ),
      );
    }

    return actions;
  }

  Widget _buildBatchActionsFooter(BatchGroup batch, String status) {
    if (status == 'PUBLISHED') return const SizedBox.shrink();

    String btnLabel = '';
    Color btnColor = Colors.grey;
    IconData btnIcon = Icons.done;
    VoidCallback? action;

    if (status == 'DRAFT') {
      btnLabel =
          _selectedToPublish.isNotEmpty
              ? 'Publish Selected'
              : 'Publish All Batch';
      btnColor = ErpColors.success;
      btnIcon = Icons.publish;
      action =
          () => _confirm(
            'Publish ${_selectedToPublish.isNotEmpty ? 'selected' : 'all'} results in this batch?',
            () => _doPublishBatch(
              batch,
              publishSelected: _selectedToPublish.isNotEmpty,
            ),
          );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: ErpColors.bgSubtle,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (status == 'DRAFT')
            Row(
              children: [
                Checkbox(
                  value:
                      batch.results.isNotEmpty &&
                      batch.results.every(
                        (r) => _selectedToPublish.contains(r.id),
                      ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedToPublish.addAll(
                          batch.results.map((r) => r.id!),
                        );
                      } else {
                        _selectedToPublish.removeAll(
                          batch.results.map((r) => r.id!),
                        );
                      }
                    });
                  },
                  activeColor: ErpColors.primary,
                ),
                Text('Select All', style: ErpTypography.labelSmall),
              ],
            )
          else
            const SizedBox.shrink(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: ErpColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(120, 36),
            ),
            icon: Icon(btnIcon, size: 14),
            label: Text(
              btnLabel,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            onPressed: action,
          ),
        ],
      ),
    );
  }

  Future<void> _doVerifyBatch(BatchGroup batch) async {
    setState(() {
      _loading[_statuses[_tabCtrl.index]] = true;
    });
    try {
      for (var r in batch.results) {
        await _service.verifyResult(
          resultId: r.id!,
          performedBy: widget.performedBy,
          role: widget.role,
        );
      }
      _showSnack('Batch results verified successfully!', ErpColors.info);
    } catch (e) {
      _showSnack('Verify batch error: $e', Colors.redAccent);
    } finally {
      _refreshAll();
    }
  }

  Future<void> _doApproveBatch(BatchGroup batch) async {
    setState(() {
      _loading[_statuses[_tabCtrl.index]] = true;
    });
    try {
      for (var r in batch.results) {
        await _service.approveResult(
          resultId: r.id!,
          performedBy: widget.performedBy,
        );
      }
      _showSnack('Batch results approved successfully!', ErpColors.primary);
    } catch (e) {
      _showSnack('Approve batch error: $e', Colors.redAccent);
    } finally {
      _refreshAll();
    }
  }

  Future<void> _doPublishBatch(
    BatchGroup batch, {
    bool publishSelected = false,
  }) async {
    setState(() {
      _loading[_statuses[_tabCtrl.index]] = true;
    });
    try {
      for (var r in batch.results) {
        if (publishSelected && !_selectedToPublish.contains(r.id)) continue;
        await _service.publishResult(
          resultId: r.id!,
          performedBy: widget.performedBy,
          role: widget.role,
        );
      }
      _showSnack('Batch results published successfully!', ErpColors.success);
    } catch (e) {
      _showSnack('Publish batch error: $e', Colors.redAccent);
    } finally {
      _refreshAll();
    }
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Workflow Actions ─────────────────────────────────────────────────────

  Future<void> _doVerify(int id) async {
    try {
      await _service.verifyResult(
        resultId: id,
        performedBy: widget.performedBy,
        role: widget.role,
      );
      _refreshAll();
      _showSnack('Result verified!', ErpColors.info);
    } catch (e) {
      _showSnack(e.toString(), ErpColors.danger);
    }
  }

  Future<void> _doApprove(int id) async {
    try {
      await _service.approveResult(
        resultId: id,
        performedBy: widget.performedBy,
      );
      _refreshAll();
      _showSnack('Result approved!', ErpColors.primary);
    } catch (e) {
      _showSnack(e.toString(), ErpColors.danger);
    }
  }

  Future<void> _doPublish(int id) async {
    try {
      await _service.publishResult(
        resultId: id,
        performedBy: widget.performedBy,
        role: widget.role,
      );
      _refreshAll();
      _showSnack(
        'Result published! Students can now view it.',
        ErpColors.success,
      );
    } catch (e) {
      _showSnack(e.toString(), ErpColors.danger);
    }
  }

  Future<void> _doReturn(int id, String reason) async {
    try {
      await _service.returnForCorrection(
        resultId: id,
        performedBy: widget.performedBy,
        role: widget.role,
        reason: reason,
      );
      _refreshAll();
      _showSnack('Returned for correction.', ErpColors.warning);
    } catch (e) {
      _showSnack(e.toString(), ErpColors.danger);
    }
  }

  void _refreshAll() {
    _results.clear();
    _loadResults(_statuses[_tabCtrl.index]);
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _confirm(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            title: Text('Confirm', style: ErpTypography.titleLarge),
            content: Text(message, style: ErpTypography.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: ErpTypography.labelLarge.copyWith(
                    color: ErpColors.textMuted,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.primary,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text('Confirm', style: GoogleFonts.outfit()),
              ),
            ],
          ),
    );
  }

  void _confirmReturn(int id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            title: Text(
              'Return for Correction',
              style: ErpTypography.titleLarge,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the reason for returning:',
                  style: ErpTypography.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  style: ErpTypography.bodyLarge,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ErpColors.bgSubtle,
                    hintText: 'Reason...',
                    hintStyle: ErpTypography.bodyMedium.copyWith(
                      color: ErpColors.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: ErpTypography.labelLarge.copyWith(
                    color: ErpColors.textMuted,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.warning,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _doReturn(id, ctrl.text.trim());
                },
                child: Text(
                  'Return',
                  style: ErpTypography.button.copyWith(
                    color: ErpColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showAuditTrail(int id) async {
    try {
      final logs = await _service.getAuditTrail(id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: ErpColors.bgWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ErpRadius.xl),
          ),
        ),
        builder:
            (_) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ErpColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Audit Trail', style: ErpTypography.titleLarge),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      logs.isEmpty
                          ? Center(
                            child: Text(
                              'No audit records',
                              style: ErpTypography.bodyMedium,
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: logs.length,
                            itemBuilder: (_, i) {
                              final log = logs[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ErpColors.bgSubtle,
                                  borderRadius: BorderRadius.circular(
                                    ErpRadius.md,
                                  ),
                                  border: Border.all(color: ErpColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ErpColors.infoSurface,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            log.action,
                                            style: ErpTypography.labelSmall
                                                .copyWith(
                                                  color: ErpColors.info,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          log.performedAt.substring(0, 10),
                                          style: GoogleFonts.outfit(
                                            color: ErpColors.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${log.previousStatus ?? "—"} → ${log.newStatus ?? "—"}',
                                      style: ErpTypography.bodyMedium.copyWith(
                                        color: ErpColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'By: ${log.performedBy} (${log.performedByRole ?? ""})',
                                      style: ErpTypography.caption,
                                    ),
                                    if (log.comments != null)
                                      Text(
                                        'Note: ${log.comments}',
                                        style: ErpTypography.caption.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
      );
    } catch (e) {
      _showSnack('Failed to load audit: $e', ErpColors.danger);
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _goToEntryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SemesterResultEntryScreen(
              performedBy: widget.performedBy,
              role: widget.role,
            ),
      ),
    ).then((_) => _refreshAll());
  }

  void _goToEditScreen(ExamCellResultModel result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SemesterResultEntryScreen(
              performedBy: widget.performedBy,
              role: widget.role,
              existingResult: result,
            ),
      ),
    ).then((_) => _refreshAll());
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return ErpColors.textMuted;
      case 'VERIFIED':
        return ErpColors.info;
      case 'APPROVED':
        return ErpColors.primary;
      case 'PUBLISHED':
        return ErpColors.success;
      default:
        return ErpColors.border;
    }
  }

  Widget _emptyView(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: ErpColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No $status results', style: ErpTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _errorView(String error, String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: ErpColors.danger, size: 40),
          const SizedBox(height: 8),
          Text(
            error,
            style: ErpTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _loadResults(status),
            child: Text(
              'Retry',
              style: ErpTypography.labelLarge.copyWith(
                color: ErpColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
