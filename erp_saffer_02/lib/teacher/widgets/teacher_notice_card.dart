import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../theme/teacher_theme.dart';

/// Card representing a single notice, used on the Dashboard's "Recent Notices"
/// list and the Notices screen history.
class TeacherNoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback? onTap;

  const TeacherNoticeCard({super.key, required this.notice, this.onTap});

  Color get _priorityColor {
    switch (notice.priority) {
      case NoticePriority.high:
        return TeacherColors.danger;
      case NoticePriority.low:
        return TeacherColors.success;
      case NoticePriority.normal:
        return TeacherColors.brass;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: TeacherDecorations.card(radius: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(notice.title, style: TeacherTextStyles.heading3)),
                        Text(_formatDate(notice.publishedAt), style: TeacherTextStyles.bodyMuted),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TeacherTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }
}
