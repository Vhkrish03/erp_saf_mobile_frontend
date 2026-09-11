import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../theme/teacher_theme.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onReview;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final isExpired = assignment.dueDate.isBefore(now);

    final dueSoon =
        !isExpired &&
            assignment.dueDate.difference(now).inDays <= 2;

    final progress = assignment.totalStudents == 0
        ? 0.0
        : assignment.submissionCount / assignment.totalStudents;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onReview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //-------------------------------------------------------
            // Header
            //-------------------------------------------------------

            Row(
              children: [

                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: TeacherColors.navy.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: TeacherColors.navy,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                        assignment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "${assignment.year} ${assignment.department} ${assignment.section}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                _StatusChip(
                  isPublished: assignment.isPublished,
                ),
              ],
            ),

            const SizedBox(height: 18),

            //-------------------------------------------------------
            // Description
            //-------------------------------------------------------

            Text(
              assignment.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                height: 1.45,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 18),

            //-------------------------------------------------------
            // Info Row
            //-------------------------------------------------------

            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [

                _InfoTile(
                  Icons.calendar_today_rounded,
                  _formatDate(assignment.dueDate),
                ),

                _InfoTile(
                  Icons.people_alt_outlined,
                  "${assignment.submissionCount}/${assignment.totalStudents}",
                ),

                if (assignment.attachmentFileName != null)
                  _InfoTile(
                    Icons.picture_as_pdf_rounded,
                    "PDF",
                  ),
              ],
            ),

            const SizedBox(height: 18),

            //-------------------------------------------------------
            // Progress
            //-------------------------------------------------------

            Row(
              children: [

                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(30),
                    child: LinearProgressIndicator(
                      minHeight: 9,
                      value: progress,
                      color: TeacherColors.navy,
                      backgroundColor:
                      Colors.grey.shade200,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            //-------------------------------------------------------
            // Footer
            //-------------------------------------------------------

            Row(
              children: [

                Icon(
                  Icons.circle,
                  size: 10,
                  color: isExpired
                      ? Colors.red
                      : dueSoon
                      ? Colors.orange
                      : Colors.green,
                ),

                const SizedBox(width: 6),

                Text(
                  isExpired
                      ? "Deadline Passed"
                      : dueSoon
                      ? "Due Soon"
                      : "Active",
                  style: TextStyle(
                    color: isExpired
                        ? Colors.red
                        : dueSoon
                        ? Colors.orange
                        : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 110,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onReview,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text(
                      "Review",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];

    return "${date.day} ${months[date.month - 1]}";
  }
}

class _InfoTile extends StatelessWidget {

  final IconData icon;
  final String text;

  const _InfoTile(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            icon,
            size: 16,
            color: TeacherColors.navy,
          ),

          const SizedBox(width: 6),

          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {

  final bool isPublished;

  const _StatusChip({
    required this.isPublished,
  });

  @override
  Widget build(BuildContext context) {

    final color =
    isPublished
        ? Colors.green
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isPublished
            ? "Published"
            : "Draft",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}