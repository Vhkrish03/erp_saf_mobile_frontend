import 'package:flutter/material.dart';
import '../../models/Timetable_model.dart';
import '../theme/teacher_theme.dart';

/// Card representing a single scheduled class (dashboard "Today's Schedule"
/// and the Timetable screen).
class TeacherScheduleCard extends StatelessWidget {
  final TimetableModel slot;

  const TeacherScheduleCard({
    super.key,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(.05),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [

          /// Left Time
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: TeacherColors.navy.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [

                const Icon(
                  Icons.schedule,
                  color: TeacherColors.navy,
                ),

                const SizedBox(height: 8),

                Text(
                  slot.time,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TeacherColors.navy,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          /// Right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  slot.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    const Icon(Icons.groups,size:16),

                    const SizedBox(width:6),

                    Text(slot.section),

                    const Spacer(),

                    const Icon(Icons.meeting_room,size:16),

                    const SizedBox(width:6),

                    Text(slot.room),

                  ],
                ),

                const SizedBox(height:8),

                Row(
                  children: [

                    const Icon(Icons.school,size:16),

                    const SizedBox(width:6),

                    Text("${slot.department} • ${slot.year}"),

                  ],
                ),

                const SizedBox(height:8),

                Row(
                  children: [

                    const Icon(Icons.person,size:16),

                    const SizedBox(width:6),

                    Expanded(
                      child: Text(slot.faculty),
                    ),

                  ],
                ),

              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TeacherColors.navy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TeacherColors.navy),
      ),
    );
  }
}
