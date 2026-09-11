import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_constants.dart';
import '../models/teacher.dart';
import '../models/teacher_schedule.dart';
import '../models/notice.dart';

/// Handles teacher profile, dashboard stats, schedule, and notices.
///
/// NOTE (mock data phase): every method below returns static/mock data via
/// `Future.delayed` to simulate network latency. Method signatures already
/// match what the real Spring Boot REST integration will need, so wiring up
/// `http` calls later is a drop-in replacement — no UI changes required.
///
/// Real wiring later looks like:
/// ```dart
/// final response = await http.get(Uri.parse('$baseUrl/teachers/$employeeId'));
/// if (response.statusCode == 200) {
///   return Teacher.fromJson(jsonDecode(response.body));
/// }
/// throw Exception('Failed to load teacher profile');
/// ```
class TeacherService {
  // TODO: inject real base URL, e.g. static const baseUrl = 'https://api.college-erp.com/api';

  // static const _mockTeacher = Teacher(
  //   employeeId: 'EMP001',
  //   name: 'Dr. Meera Krishnan',
  //   department: 'Computer Science',
  //   designation: 'Associate Professor',
  //   qualification: 'Ph.D in Computer Science',
  //   experience: '12 Years',
  //   phone: '+91 98765 43210',
  //   email: 'meera.krishnan@college.edu',
  //   address: 'No. 24, Anna Nagar, Chennai, Tamil Nadu',
  // );




  Future<Teacher> getTeacherProfile(String employeeId) async {

    final response = await http.get(
      Uri.parse(
          "${ApiConstants.baseUrl}/api/teacher/$employeeId"
      ),
    );


    if(response.statusCode == 200){

      return Teacher.fromJson(
          jsonDecode(response.body)
      );

    }else{

      throw Exception("Failed to load teacher");

    }
  }

  /// PUT /teachers/{employeeId}
  Future<Teacher> updateProfile(Teacher teacher) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return teacher;
  }

  /// GET /teachers/{employeeId}/dashboard-stats
  Future<DashboardStats> getDashboardStats(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const DashboardStats(
      todaysClasses: 3,
      totalStudents: 142,
      pendingAttendance: 2,
      assignmentsToReview: 18,
      averageClassAttendance: 87.5,
    );
  }

  /// GET /teachers/{employeeId}/schedule/today
  Future<List<ScheduleSlot>> getTodaysSchedule(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      ScheduleSlot(time: '09:00 AM', subject: 'Data Structures', section: 'III CSE A', room: 'Room 402'),
      ScheduleSlot(time: '11:00 AM', subject: 'Database Management Systems', section: 'III CSE B', room: 'Room 305'),
      ScheduleSlot(time: '02:00 PM', subject: 'Operating Systems', section: 'III CSE A', room: 'Room 205'),
    ];
  }

  /// GET /teachers/{employeeId}/notices/recent
  Future<List<Notice>> getRecentNotices({int limit = 3}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final all = [
      Notice(
        id: 'N001',
        title: 'Exam Schedule',
        description: 'End semester examination timetable has been released for III CSE.',
        priority: NoticePriority.high,
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Notice(
        id: 'N002',
        title: 'Holiday Notice',
        description: 'College will remain closed on account of a regional festival.',
        priority: NoticePriority.normal,
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Notice(
        id: 'N003',
        title: 'Project Submission',
        description: 'Final year project submission deadline extended by one week.',
        priority: NoticePriority.normal,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    return all.take(limit).toList();
  }

  /// GET /teachers/{employeeId}/notices
  Future<List<Notice>> getAllNotices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return getRecentNotices(limit: 3);
  }

  /// POST /teachers/{employeeId}/notices
  Future<Notice> createNotice({
    required String title,
    required String description,
    required NoticePriority priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return Notice(
      id: 'N${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      priority: priority,
      publishedAt: DateTime.now(),
    );
  }
}
