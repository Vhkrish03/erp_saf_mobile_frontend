import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/student.dart';
import '../models/assessment_model.dart';
import '../services/assessment_service.dart';

class MarkEntryScreen extends StatefulWidget {
  final AssessmentModel assessment;
  final AssessmentComponentModel component;
  final String employeeId;

  const MarkEntryScreen({
    super.key,
    required this.assessment,
    required this.component,
    required this.employeeId,
  });

  @override
  State<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends State<MarkEntryScreen> {
  final AssessmentService _api = AssessmentService();

  List<Student> _students = [];
  bool _loading = true;
  bool _saving = false;
  String _error = '';

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        _api.getStudentsForAssessment(widget.assessment.id),
        _api.getMarksForAssessment(widget.assessment.id),
      ]);
      final roster = futures[0] as List<Student>;
      final marks = futures[1] as List<AssessmentMarkModel>;

      _controllers.clear();
      for (var stu in roster) {
        final match = marks.firstWhere(
          (m) => m.student.id == stu.id && m.componentId == widget.component.id,
          orElse:
              () => AssessmentMarkModel(
                student: stu,
                marksObtained: 0,
                enteredBy: widget.employeeId,
                componentId: widget.component.id,
              ),
        );
        _controllers[stu.id] = TextEditingController(
          text: match.marksObtained > 0 ? match.marksObtained.toString() : '',
        );
      }
      setState(() {
        _students = roster;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load class list: $e';
          _loading = false;
        });
      }
    }
  }

  bool _validateMarks() {
    for (var stu in _students) {
      final raw = _controllers[stu.id]?.text ?? '';
      final val = double.tryParse(raw) ?? 0.0;
      if (val < 0 || val > widget.component.maxMarks) {
        ErpSnackbar.show(
          context,
          message:
              'Invalid mark for ${stu.name}. Must be 0–${widget.component.maxMarks.toStringAsFixed(0)}',
          type: ErpBadgeType.danger,
        );
        return false;
      }
    }
    return true;
  }

  List<AssessmentMarkModel> _buildMarksList() =>
      _students.map((stu) {
        final val = double.tryParse(_controllers[stu.id]?.text ?? '') ?? 0.0;
        return AssessmentMarkModel(
          student: stu,
          marksObtained: val,
          enteredBy: widget.employeeId,
        );
      }).toList();

  Future<void> _saveDraft() async {
    if (!_validateMarks()) return;
    setState(() => _saving = true);
    try {
      final success = await _api.saveMarks(
        assessmentId: widget.assessment.id,
        componentId: widget.component.id,
        marks: _buildMarksList(),
        facultyId: widget.employeeId,
      );
      if (mounted) {
        ErpSnackbar.show(
          context,
          message:
              success
                  ? 'Draft marks saved successfully.'
                  : 'Failed to save marks.',
          type: success ? ErpBadgeType.success : ErpBadgeType.danger,
        );
        if (success) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ErpSnackbar.show(
          context,
          message: 'Error saving marks.',
          type: ErpBadgeType.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitOfficially() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
            title: Text(
              'Submit Officially',
              style: ErpTypography.headlineSmall,
            ),
            content: Text(
              'Submit these marks to the Class Incharge? Once submitted, they will be frozen for you.',
              style: ErpTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    if (!_validateMarks()) return;
    setState(() => _saving = true);
    try {
      final success = await _api.saveMarks(
        assessmentId: widget.assessment.id,
        componentId: widget.component.id,
        marks: _buildMarksList(),
        facultyId: widget.employeeId,
      );
      if (!success) throw Exception('Server failed to save marks');

      bool submitted = false;
      if (widget.assessment.type.toUpperCase() == 'WEEKLY') {
        await _api.submitAssessment(
          assessmentId: widget.assessment.id,
          facultyId: widget.employeeId,
        );
        submitted = true;
      }

      if (mounted) {
        ErpSnackbar.show(
          context,
          message:
              submitted
                  ? 'Marks submitted to Class Incharge.'
                  : 'Component marks saved successfully.',
          type: ErpBadgeType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ErpSnackbar.show(
          context,
          message: 'Error submitting marks.',
          type: ErpBadgeType.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Grades Submission',
        subtitle: widget.assessment.name,
      ),
      body: SafeArea(
        child:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: ErpColors.primary),
                )
                : _error.isNotEmpty
                ? ErpErrorState(message: _error, onRetry: _loadData)
                : Column(
                  children: [
                    // ── Header Info Card ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: ErpCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.assessment.name,
                              style: ErpTypography.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ErpColors.primarySurface,
                                    borderRadius: BorderRadius.circular(
                                      ErpRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.component.componentType}',
                                    style: ErpTypography.caption.copyWith(
                                      color: ErpColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Max: ${widget.component.maxMarks.toStringAsFixed(0)} marks',
                                  style: ErpTypography.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Class: ${widget.assessment.semester} A  ·  Dept: ${widget.assessment.department}',
                              style: ErpTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Students Table ────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ErpCard(
                          padding: EdgeInsets.zero,
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 24,
                                    headingRowHeight: 44,
                                    dataRowMinHeight: 50,
                                    dataRowMaxHeight: 56,
                                    headingRowColor: WidgetStateProperty.all(
                                      ErpColors.bgSubtle,
                                    ),
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Roll No',
                                          style: ErpTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Student Name',
                                          style: ErpTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Marks (Max ${widget.component.maxMarks.toStringAsFixed(0)})',
                                          style: ErpTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        _students
                                            .map(
                                              (stu) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      stu.rollNumber,
                                                      style:
                                                          ErpTypography
                                                              .bodySmall,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      stu.name,
                                                      style:
                                                          ErpTypography
                                                              .titleMedium,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      height: 38,
                                                      width: 90,
                                                      child: TextField(
                                                        controller:
                                                            _controllers[stu
                                                                .id],
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        style: ErpTypography
                                                            .bodyLarge
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                        decoration: InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          hintText: '0.0',
                                                          isDense: true,
                                                          filled: true,
                                                          fillColor:
                                                              ErpColors
                                                                  .bgSubtle,
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  ErpRadius.sm,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color:
                                                                      ErpColors
                                                                          .border,
                                                                ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  ErpRadius.sm,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color:
                                                                      ErpColors
                                                                          .border,
                                                                ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  ErpRadius.sm,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color:
                                                                      ErpColors
                                                                          .primary,
                                                                  width: 1.5,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Action Buttons ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ErpButton(
                              label: 'Save Draft',
                              fullWidth: true,
                              type: ErpButtonType.secondary,
                              loading: _saving,
                              onPressed: _saving ? null : _saveDraft,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ErpButton(
                              label: 'Submit Officially',
                              fullWidth: true,
                              loading: _saving,
                              onPressed: _saving ? null : _submitOfficially,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
