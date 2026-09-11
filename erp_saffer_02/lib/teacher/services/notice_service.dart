import '../models/notice.dart';

/// Dedicated service for the Notices screen (create + history).
/// Mirrors the notice-related methods on [TeacherService] but scoped
/// specifically for this screen's needs, matching the real backend's
/// `/notices` resource.
class NoticeService {
  static final List<Notice> _mockHistory = [
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
    Notice(
      id: 'N004',
      title: 'Lab Maintenance',
      description: 'Systems Lab 2 will be closed for maintenance this Saturday.',
      priority: NoticePriority.low,
      publishedAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  /// GET /notices?teacherId=
  Future<List<Notice>> getNoticeHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockHistory;
  }

  /// POST /notices
  Future<Notice> publishNotice({
    required String title,
    required String description,
    required NoticePriority priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final notice = Notice(
      id: 'N${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      priority: priority,
      publishedAt: DateTime.now(),
    );
    _mockHistory.insert(0, notice);
    return notice;
  }
}
