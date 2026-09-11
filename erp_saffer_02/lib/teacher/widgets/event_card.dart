import 'package:flutter/material.dart';
import '../../screens/event_details_screen.dart';
import '../../teacher/theme/teacher_theme.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final String currentRole;
  final String currentEmployeeId;
  final VoidCallback onRefresh;
  final VoidCallback? onEdit;

  const EventCard({
    Key? key,
    required this.event,
    required this.currentRole,
    required this.currentEmployeeId,
    required this.onRefresh,
    this.onEdit,
  }) : super(key: key);

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${dt.day} ${months[dt.month - 1]}, ${dt.year}";
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return TeacherColors.textSecondary;
      case 'PENDING_APPROVAL':
        return TeacherColors.warning;
      case 'PUBLISHED':
      case 'APPROVED':
        return TeacherColors.success;
      case 'REJECTED':
        return TeacherColors.danger;
      case 'CANCELLED':
        return Colors.blueGrey;
      default:
        return TeacherColors.textMuted;
    }
  }

  void _submitForApproval(BuildContext context) async {
    try {
      await EventService().submitEvent(
        event.id!,
        currentEmployeeId,
        currentRole,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event submitted for approval successfully"),
        ),
      );
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting event: $e")));
    }
  }

  void _approveEvent(BuildContext context) async {
    try {
      await EventService().approveEvent(
        event.id!,
        currentEmployeeId,
        currentRole,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event approved and published")),
      );
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error approving event: $e")));
    }
  }

  void _rejectEvent(BuildContext context) async {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              "Reject Event Announcement",
              style: TextStyle(
                color: TeacherColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter the reason for rejection...",
                labelText: "Rejection Reason",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.danger,
                ),
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a reason")),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await EventService().rejectEvent(
                      event.id!,
                      reasonController.text.trim(),
                      currentEmployeeId,
                      currentRole,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Event rejected")),
                    );
                    onRefresh();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error rejecting event: $e")),
                    );
                  }
                },
                child: const Text("Reject"),
              ),
            ],
          ),
    );
  }

  void _cancelEvent(BuildContext context) async {
    try {
      await EventService().cancelEvent(
        event.id!,
        currentEmployeeId,
        currentRole,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event announcement cancelled")),
      );
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cancelling event: $e")));
    }
  }

  void _deleteEvent(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              "Delete Event Announcement",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Are you sure you want to delete this event draft permanently?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.danger,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await EventService().deleteEvent(
          event.id!,
          currentEmployeeId,
          currentRole,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event draft deleted")));
        onRefresh();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error deleting event: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHOD = currentRole.toUpperCase() == 'HOD';
    final showApprovalButtons = isHOD && event.status == 'PENDING_APPROVAL';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: TeacherColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(event: event),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Type Badge & Status Card Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          event.eventType == 'COLLEGE_EVENT'
                              ? TeacherColors.navy.withOpacity(0.08)
                              : TeacherColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.eventType == 'COLLEGE_EVENT'
                          ? 'College'
                          : 'External',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            event.eventType == 'COLLEGE_EVENT'
                                ? TeacherColors.navy
                                : TeacherColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(event.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TeacherColors.navy,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: TeacherColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Divider
              const Divider(height: 1, color: TeacherColors.divider),
              const SizedBox(height: 12),

              // Icons Meta Rows
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: TeacherColors.navyLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(event.eventDate),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: TeacherColors.navyLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.venue ?? 'TBA',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              if (event.status == 'REJECTED' &&
                  event.rejectionReason != null &&
                  event.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TeacherColors.danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: TeacherColors.danger.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: TeacherColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Rejection Reason: ${event.rejectionReason!}",
                          style: const TextStyle(
                            color: TeacherColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Role based actionable buttons
              if (showApprovalButtons) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TeacherColors.danger,
                        side: const BorderSide(color: TeacherColors.danger),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _rejectEvent(context),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        "Reject",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.success,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _approveEvent(context),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text(
                        "Approve",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (event.status == 'DRAFT') ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: TeacherColors.danger,
                        size: 20,
                      ),
                      onPressed: () => _deleteEvent(context),
                      tooltip: "Delete Draft",
                    ),
                    const Spacer(),
                    if (onEdit != null) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          "Edit",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _submitForApproval(context),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        "Submit",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (event.status == 'PUBLISHED' &&
                  currentRole.toUpperCase() != 'STUDENT') ...[
                // Allow cancellation of published events
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        side: const BorderSide(color: Colors.blueGrey),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _cancelEvent(context),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text(
                        "Cancel Event",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ] else if (event.status == 'REJECTED') ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: TeacherColors.danger,
                        size: 20,
                      ),
                      onPressed: () => _deleteEvent(context),
                      tooltip: "Delete",
                    ),
                    const Spacer(),
                    if (onEdit != null) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeacherColors.navy,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          "Edit & Resubmit",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
