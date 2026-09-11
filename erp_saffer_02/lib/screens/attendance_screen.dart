import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../services/SubjectService.dart';
import '../models/subject_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {

  final SubjectService _service = SubjectService();

  List<SubjectModel> subjects = [];

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    setState(() => isLoading = true);
    try {
      subjects = await _service.getSubjects();
    } catch (e) {
      error = 'We could not retrieve attendance right now.';
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: ErpAppBar(title: 'Attendance'),
        body: _AttendanceSkeleton(),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: const ErpAppBar(title: 'Attendance'),
        body: ErpErrorState(message: error!, onRetry: loadSubjects),
      );
    }

    final overall = subjects.isEmpty
        ? 0.0
        : subjects
        .map((s) => s.attendancePercent)
        .reduce((a, b) => a + b) /
        subjects.length;

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(title: 'Attendance'),
      body: RefreshIndicator(
        color: ErpColors.primary,
        onRefresh: loadSubjects,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ErpSpacing.pagePadding,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ErpColors.primary,
              borderRadius: ErpRadius.card,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  height: 74,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: overall / 100,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                          overall < 75 ? ErpColors.danger : ErpColors.accent,
                        ),
                      ),
                      Text('${overall.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overall attendance',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        overall < 75
                            ? 'Below the required 75% — attend classes regularly.'
                            : 'You are meeting the minimum attendance requirement.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Subject-wise breakdown', style: ErpTypography.headlineSmall),
          const SizedBox(height: 14),
          ...subjects.map((s) => _SubjectAttendanceTile(subject: s)),
        ],
        ),
      ),
    );
  }
}

class _SubjectAttendanceTile extends StatelessWidget {
  final SubjectModel subject;
  const _SubjectAttendanceTile({required this.subject});

  Color get _color {
    if (subject.attendancePercent < 75) return ErpColors.danger;
    if (subject.attendancePercent < 85) return ErpColors.warning;
    return ErpColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ErpCard(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('${subject.code} · ${subject.faculty}', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                '${subject.attendancePercent.toStringAsFixed(0)}%',
                style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: subject.attendancePercent / 100,
              minHeight: 7,
              backgroundColor: ErpColors.border,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${subject.classesAttended} / ${subject.classesHeld} classes attended',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      ),
    );
  }
}

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 116, radius: 16),
        SizedBox(height: 24),
        ErpSkeleton(width: 180, height: 20),
        SizedBox(height: 14),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
