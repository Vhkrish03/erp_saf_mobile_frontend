import 'package:flutter/material.dart';
import '../theme/teacher_theme.dart';

/// Premium greeting header used at the top of the Dashboard screen.
class TeacherHeader extends StatelessWidget {
  final String teacherName;
  final String department;
  final String employeeId;
  final String photoUrl;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final bool hasUnreadNotifications;

  const TeacherHeader({
    super.key,
    required this.teacherName,
    required this.department,
    required this.employeeId,
    required this.onNotificationTap,
    required this.onProfileTap,
    this.photoUrl = '',
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: TeacherDecorations.navyCard(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Text(
                  teacherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  department,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TeacherColors.brass.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeacherColors.brass.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Employee ID : $employeeId',
                    style: const TextStyle(
                      color: TeacherColors.brassLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _NotificationButton(
                onTap: onNotificationTap,
                hasUnread: hasUnreadNotifications,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: TeacherColors.brass,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          _initials(teacherName),
                          style: const TextStyle(
                            color: TeacherColors.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty && p != 'Dr.' && p != 'Mr.' && p != 'Mrs.');
    if (letters.isEmpty) return 'T';
    if (letters.length == 1) return letters.first.substring(0, 1).toUpperCase();
    return (letters.first.substring(0, 1) + letters.last.substring(0, 1)).toUpperCase();
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasUnread;

  const _NotificationButton({required this.onTap, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
              if (hasUnread)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: TeacherColors.brass, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
