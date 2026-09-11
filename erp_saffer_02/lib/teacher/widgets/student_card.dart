import 'package:flutter/material.dart';
import '../models/student_summary.dart';
import '../theme/teacher_theme.dart';

/// Card representing a single student on the Students screen.
class StudentCard extends StatelessWidget {
  final StudentSummary student;
  final VoidCallback onViewProfile;

  const StudentCard({super.key, required this.student, required this.onViewProfile});

  Color _attendanceColor(double pct) {
    if (pct >= 85) return TeacherColors.success;
    if (pct >= 75) return TeacherColors.warning;
    return TeacherColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: TeacherDecorations.card(radius: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: TeacherColors.navy.withOpacity(0.1),
            backgroundImage: student.photoUrl.isNotEmpty ? NetworkImage(student.photoUrl) : null,
            child: student.photoUrl.isEmpty
                ? Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: TeacherColors.navy, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: TeacherTextStyles.heading3),
                const SizedBox(height: 2),
                Text(student.rollNumber, style: TeacherTextStyles.bodyMuted),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_available_outlined, size: 14, color: _attendanceColor(student.attendancePercentage)),
                    const SizedBox(width: 4),
                    Text(
                      '${student.attendancePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _attendanceColor(student.attendancePercentage),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.workspace_premium_outlined, size: 14, color: TeacherColors.brass),
                    const SizedBox(width: 4),
                    Text(
                      'CGPA ${student.cgpa.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: TeacherColors.navy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onViewProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
