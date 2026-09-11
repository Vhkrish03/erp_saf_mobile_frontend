import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../models/exam_cell_model.dart';
import '../exam_admin/services/exam_cell_service.dart';
import '../progress/screens/progress_card_screen.dart';
import 'semester_result_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String? studentId;

  const ResultsScreen({super.key, this.studentId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final StudentService _studentApi = StudentService();
  final ExamCellService _cellService = ExamCellService();

  Student? _student;
  List<ExamCellResultModel> _publishedResults = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studentId = widget.studentId ?? 'STU25';
      _student = await _studentApi.getStudent(studentId);
      _publishedResults = await _cellService.getPublishedResultsForStudent(studentId);
      _publishedResults.sort((a, b) => a.semesterName.compareTo(b.semesterName));
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'We could not retrieve your results right now.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: ErpAppBar(title: 'Academic Results'),
        body: _ResultsSkeleton(),
      );
    }

    if (_error != null || _student == null) {
      return Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: const ErpAppBar(title: 'Academic Results'),
        body: ErpErrorState(
          message: _error ?? 'Your student profile is unavailable right now.',
          onRetry: _loadData,
        ),
      );
    }

    final student = _student!;
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(title: 'My Academic Results'),
      body: RefreshIndicator(
        color: ErpColors.primary,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ErpSpacing.pagePadding,
          children: [
            ErpCard(
              color: ErpColors.primary,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cumulative CGPA', style: ErpTypography.bodySmall.copyWith(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(student.cgpa.toStringAsFixed(2), style: ErpTypography.statNumber.copyWith(color: ErpColors.accent)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ErpColors.accent.withValues(alpha: 0.12),
                      borderRadius: ErpRadius.cardSm,
                    ),
                    child: const Icon(Icons.workspace_premium_outlined, color: ErpColors.accent, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ErpCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProgressCardScreen(studentId: student.id)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: ErpColors.primarySurface, borderRadius: ErpRadius.cardSm),
                    child: const Icon(Icons.analytics_outlined, color: ErpColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consolidated Progress Card', style: ErpTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text('Continuous internals and term exams', style: ErpTypography.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: ErpColors.textMuted, size: 14),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const ErpSectionHeader(
              title: 'Official semester results',
              subtitle: 'Published academic performance',
            ),
            if (_publishedResults.isEmpty)
              const ErpEmptyState(
                message: 'No results published yet',
                subtitle: 'Official semester results will appear here once released.',
                icon: Icons.school_outlined,
              )
            else
              ..._publishedResults.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ErpCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SemesterResultDetailScreen(
                          studentId: result.studentId,
                          semesterName: result.semesterName,
                          studentName: student.name,
                          rollNumber: student.rollNumber,
                          department: student.department,
                          cumulativeCgpa: student.cgpa,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Semester ${result.semesterName}', style: ErpTypography.titleMedium),
                              const SizedBox(height: 4),
                              Text('SGPA: ${result.sgpa.toStringAsFixed(2)}  |  ${result.examSession}', style: ErpTypography.bodySmall),
                            ],
                          ),
                        ),
                        const ErpStatusBadge(label: 'PUBLISHED', type: ErpBadgeType.success, compact: true),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, color: ErpColors.textMuted, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 112, radius: 16),
        SizedBox(height: 16),
        ErpSkeleton(height: 76, radius: 16),
        SizedBox(height: 28),
        ErpSkeleton(width: 190, height: 20),
        SizedBox(height: 14),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
