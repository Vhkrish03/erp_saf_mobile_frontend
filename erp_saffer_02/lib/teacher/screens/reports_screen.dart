import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../theme/teacher_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _service = ReportService();

  late Future<List<ReportDataPoint>> _attendanceFuture;
  late Future<List<ReportDataPoint>> _passPercentageFuture;
  late Future<List<SubjectPerformance>> _subjectPerformanceFuture;
  late Future<List<ReportDataPoint>> _cgpaDistributionFuture;
  late Future<List<TopPerformer>> _topPerformersFuture;
  late Future<List<DepartmentAnalytics>> _departmentAnalyticsFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _service.getAttendanceOverview();
    _passPercentageFuture = _service.getPassPercentage();
    _subjectPerformanceFuture = _service.getSubjectWisePerformance();
    _cgpaDistributionFuture = _service.getCgpaDistribution();
    _topPerformersFuture = _service.getTopPerformers();
    _departmentAnalyticsFuture = _service.getDepartmentAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _ReportSection(
              title: 'Average Attendance (This Week)',
              child: FutureBuilder<List<ReportDataPoint>>(
                future: _attendanceFuture,
                builder: (context, snapshot) => _BarChart(data: snapshot.data, suffix: '%'),
              ),
            ),
            _ReportSection(
              title: 'Pass Percentage by Section',
              child: FutureBuilder<List<ReportDataPoint>>(
                future: _passPercentageFuture,
                builder: (context, snapshot) => _BarChart(data: snapshot.data, suffix: '%', color: TeacherColors.brass),
              ),
            ),
            _ReportSection(
              title: 'Subject Wise Performance',
              child: FutureBuilder<List<SubjectPerformance>>(
                future: _subjectPerformanceFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const _ChartLoading();
                  return Column(
                    children: snapshot.data!
                        .map((s) => _SubjectRow(subject: s))
                        .toList(),
                  );
                },
              ),
            ),
            _ReportSection(
              title: 'CGPA Distribution',
              child: FutureBuilder<List<ReportDataPoint>>(
                future: _cgpaDistributionFuture,
                builder: (context, snapshot) => _BarChart(data: snapshot.data, color: TeacherColors.info),
              ),
            ),
            _ReportSection(
              title: 'Top Performers',
              child: FutureBuilder<List<TopPerformer>>(
                future: _topPerformersFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const _ChartLoading();
                  final performers = snapshot.data!;
                  return Column(
                    children: performers.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final p = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: rank == 1 ? TeacherColors.brass : TeacherColors.navy.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  color: rank == 1 ? Colors.white : TeacherColors.navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: TeacherTextStyles.heading3),
                                  Text(p.rollNumber, style: TeacherTextStyles.bodyMuted),
                                ],
                              ),
                            ),
                            Text('CGPA ${p.cgpa.toStringAsFixed(2)}', style: TeacherTextStyles.brassAccent),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            _ReportSection(
              title: 'Department Analytics',
              child: FutureBuilder<List<DepartmentAnalytics>>(
                future: _departmentAnalyticsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const _ChartLoading();
                  return Column(
                    children: snapshot.data!.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(width: 48, child: Text(d.department, style: TeacherTextStyles.heading3)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d.totalStudents} students · ${d.passPercentage.toStringAsFixed(0)}% pass',
                                    style: TeacherTextStyles.bodyMuted,
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: d.averageAttendance / 100,
                                      minHeight: 8,
                                      backgroundColor: TeacherColors.divider,
                                      color: TeacherColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: TeacherDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TeacherTextStyles.heading3),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: ErpSkeleton(height: 120, radius: 12),
    );
  }
}

/// A simple, dependency-free bar chart built with plain Flutter widgets.
class _BarChart extends StatelessWidget {
  final List<ReportDataPoint>? data;
  final Color color;
  final String suffix;

  const _BarChart({required this.data, this.color = TeacherColors.navy, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _ChartLoading();
    final maxValue = data!.map((d) => d.value).fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data!.map((point) {
          final heightFactor = maxValue == 0 ? 0.0 : point.value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${point.value.toStringAsFixed(0)}$suffix', style: TeacherTextStyles.bodyMuted),
                  const SizedBox(height: 6),
                  FractionallySizedBox(
                    heightFactor: heightFactor.clamp(0.02, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: TeacherColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectPerformance subject;
  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject.subject, style: TeacherTextStyles.heading3),
              Text(
                'Avg ${subject.averageScore.toStringAsFixed(0)} · Pass ${subject.passPercentage.toStringAsFixed(0)}%',
                style: TeacherTextStyles.bodyMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: subject.passPercentage / 100,
              minHeight: 8,
              backgroundColor: TeacherColors.divider,
              color: TeacherColors.brass,
            ),
          ),
        ],
      ),
    );
  }
}
