import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../exam_admin/services/exam_cell_service.dart';
import '../theme/teacher_theme.dart';

class SemesterResultBatchScreen extends StatefulWidget {
  final String employeeId;
  final String role; // 'CLASS_INCHARGE', 'HOD', 'DEAN'
  final String? department; // HOD and Incharge need department

  const SemesterResultBatchScreen({
    super.key,
    required this.employeeId,
    required this.role,
    this.department,
  });

  @override
  State<SemesterResultBatchScreen> createState() =>
      _SemesterResultBatchScreenState();
}

class _SemesterResultBatchScreenState extends State<SemesterResultBatchScreen> {
  final ExamCellService _cellService = ExamCellService();
  bool _loading = false;
  List<dynamic> _batches = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Find batches that match the role's current actional state
      String? targetStatus;
      if (widget.role == 'CLASS_INCHARGE')
        targetStatus = 'SUBMITTED';
      else if (widget.role == 'HOD')
        targetStatus = 'CLASS_INCHARGE_VERIFIED';
      else if (widget.role == 'DEAN')
        targetStatus = 'HOD_VERIFIED';

      final batches = await _cellService.getAllBatches(
        department: widget.department,
        status: targetStatus,
      );

      setState(() {
        _batches = batches;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _actionBatch(int batchId, bool approve) async {
    String remarks = approve ? 'Looks good' : 'Returned for correction';
    try {
      if (approve) {
        if (widget.role == 'CLASS_INCHARGE') {
          await _cellService.verifyBatchIncharge(
            batchId,
            widget.employeeId,
            remarks: remarks,
          );
        } else if (widget.role == 'HOD') {
          await _cellService.verifyBatchHod(
            batchId,
            widget.employeeId,
            remarks: remarks,
          );
        } else if (widget.role == 'DEAN') {
          await _cellService.approveBatchDean(
            batchId,
            widget.employeeId,
            remarks: remarks,
          );
        }
      } else {
        // Return to DRAFT or prev state
        await _cellService.rejectBatch(
          batchId,
          'DRAFT',
          widget.employeeId,
          widget.role,
          remarks,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Batch Approved!' : 'Batch Rejected!'),
            backgroundColor:
                approve ? TeacherColors.success : TeacherColors.danger,
          ),
        );
        _loadBatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: TeacherColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "Semester Results Verification";
    if (widget.role == 'CLASS_INCHARGE') title = "Incharge Result Verification";
    if (widget.role == 'HOD') title = "HOD Result Verification";
    if (widget.role == 'DEAN') title = "Dean Final Approval";

    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: TeacherColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadBatches, icon: const Icon(Icons.refresh)),
        ],
      ),
      body:
          _loading
              ? const _ResultBatchSkeleton()
              : _error != null
              ? ErpErrorState(
                message: 'We could not retrieve result batches right now.',
                onRetry: _loadBatches,
              )
              : _batches.isEmpty
              ? const ErpEmptyState(
                message: 'No pending result batches',
                subtitle: 'Batches requiring your review will appear here.',
                icon: Icons.fact_check_outlined,
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _batches.length,
                itemBuilder: (context, index) {
                  final batch = _batches[index];
                  return _buildBatchCard(batch);
                },
              ),
    );
  }

  Widget _buildBatchCard(dynamic batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${batch['department']} - Sem ${batch['semesterName']} (${batch['academicYear']})",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TeacherColors.navy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    batch['status'] ?? 'UNKNOWN',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: TeacherColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Session: ${batch['examSession']} | Submitted By: ${batch['submittedBy'] ?? 'Exam Cell'}",
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _actionBatch(batch['id'], false),
                  icon: const Icon(
                    Icons.close,
                    color: TeacherColors.danger,
                    size: 18,
                  ),
                  label: const Text(
                    "Reject",
                    style: TextStyle(color: TeacherColors.danger),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _actionBatch(batch['id'], true),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    widget.role == 'DEAN'
                        ? "Approve & Publish"
                        : "Verify & Forward",
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

class _ResultBatchSkeleton extends StatelessWidget {
  const _ResultBatchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
