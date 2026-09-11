import '../models/report.dart';

/// Supplies chart/analytics data for the Reports screen.
///
/// Mock data phase: static series. Later, replace bodies with real
/// `http` GET calls against reporting endpoints.
class ReportService {
  /// GET /reports/attendance-overview
  Future<List<ReportDataPoint>> getAttendanceOverview() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      ReportDataPoint(label: 'Mon', value: 88),
      ReportDataPoint(label: 'Tue', value: 91),
      ReportDataPoint(label: 'Wed', value: 84),
      ReportDataPoint(label: 'Thu', value: 89),
      ReportDataPoint(label: 'Fri', value: 93),
      ReportDataPoint(label: 'Sat', value: 79),
    ];
  }

  /// GET /reports/pass-percentage
  Future<List<ReportDataPoint>> getPassPercentage() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      ReportDataPoint(label: 'III CSE A', value: 92),
      ReportDataPoint(label: 'III CSE B', value: 87),
      ReportDataPoint(label: 'III CSE C', value: 95),
    ];
  }

  /// GET /reports/subject-wise-performance
  Future<List<SubjectPerformance>> getSubjectWisePerformance() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      SubjectPerformance(subject: 'Data Structures', averageScore: 78, passPercentage: 94),
      SubjectPerformance(subject: 'DBMS', averageScore: 74, passPercentage: 89),
      SubjectPerformance(subject: 'Operating Systems', averageScore: 71, passPercentage: 86),
      SubjectPerformance(subject: 'Computer Networks', averageScore: 76, passPercentage: 91),
    ];
  }

  /// GET /reports/cgpa-distribution
  Future<List<ReportDataPoint>> getCgpaDistribution() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      ReportDataPoint(label: '9-10', value: 12),
      ReportDataPoint(label: '8-9', value: 28),
      ReportDataPoint(label: '7-8', value: 41),
      ReportDataPoint(label: '6-7', value: 33),
      ReportDataPoint(label: '<6', value: 14),
    ];
  }

  /// GET /reports/top-performers
  Future<List<TopPerformer>> getTopPerformers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      TopPerformer(name: 'Divya Sri', rollNumber: '21CSE002', cgpa: 9.6),
      TopPerformer(name: 'Karthik Raja', rollNumber: '21CSE003', cgpa: 9.4),
      TopPerformer(name: 'Priya Dharshini', rollNumber: '21CSE004', cgpa: 9.3),
      TopPerformer(name: 'Vignesh S', rollNumber: '21CSE005', cgpa: 9.1),
    ];
  }

  /// GET /reports/department-analytics
  Future<List<DepartmentAnalytics>> getDepartmentAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      DepartmentAnalytics(department: 'CSE', averageAttendance: 88, passPercentage: 92, totalStudents: 320),
      DepartmentAnalytics(department: 'ECE', averageAttendance: 85, passPercentage: 89, totalStudents: 280),
      DepartmentAnalytics(department: 'IT', averageAttendance: 90, passPercentage: 94, totalStudents: 210),
    ];
  }
}
