import 'package:flutter/material.dart';
import '../theme/teacher_theme.dart';

/// A single premium statistic card used in the Dashboard's stats row.
class TeacherStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const TeacherStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = TeacherColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(16),
      decoration: TeacherDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: TeacherTextStyles.statValue),
          const SizedBox(height: 4),
          Text(
            label,
            style: TeacherTextStyles.bodyMuted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
