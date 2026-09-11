import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design_system.dart';
import '../models/notice.dart';
import '../services/notice_service.dart';

class NoticeManagementScreen extends StatefulWidget {
  final String role;
  final String department;

  const NoticeManagementScreen({
    super.key,
    required this.role,
    required this.department,
  });

  @override
  State<NoticeManagementScreen> createState() => _NoticeManagementScreenState();
}

class _NoticeManagementScreenState extends State<NoticeManagementScreen>
    with SingleTickerProviderStateMixin {
  final NoticeService _service = NoticeService();
  bool _isLoading = true;
  List<Notice> _notices = [];

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getNotices(widget.role, widget.department);

      // -- DEMONSTRATION UI MOCK --
      // Since the backend is running on Render with old code, we insert a fake pending notice here
      // so the user can interactively test the Tracker UI without needing to push to Render first!
      data.insert(
        0,
        Notice(
          id: 'mock-100',
          title: 'UI Demo: Upcoming Staff Guidelines',
          description:
              'This is a mocked demo notice to showcase the new interactive live tracking timeline system! Once your backend code is deployed to Render, real notices will automatically behave like this.',
          date: 'Today',
          category: NoticeCategory.general,
          isImportant: true,
          status: 'PENDING_HOD',
          uploaderRole: 'TEACHER',
          department: widget.department.isEmpty ? 'ALL' : widget.department,
        ),
      );

      if (mounted) {
        setState(() {
          _notices = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _CreateNoticeSheet(
            role: widget.role,
            department: widget.department,
            onNoticeCreated: _fetchNotices,
          ),
    );
  }

  void _showTrackerSheet(List<Notice> pending) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _PendingTrackerSheet(
            pendingNotices: pending,
            currentUserRole: widget.role,
            onApprove: (id) async {
              final success = await _service.approveNotice(
                id.toString(),
                widget.role,
              );
              if (success && mounted) {
                ErpSnackbar.show(
                  context,
                  message: 'Notice approved successfully.',
                  type: ErpBadgeType.success,
                );
                Navigator.pop(context);
                _fetchNotices();
              } else if (mounted) {
                ErpSnackbar.show(
                  context,
                  message: 'Failed to approve notice.',
                  type: ErpBadgeType.danger,
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: 'Notices & Announcements',
        subtitle: 'Manage institution communications',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _fetchNotices,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_notices.any((n) => n.status != 'APPROVED'))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                heroTag: 'tracker_fab',
                backgroundColor: ErpColors.warning,
                onPressed:
                    () => _showTrackerSheet(
                      _notices.where((n) => n.status != 'APPROVED').toList(),
                    ),
                icon: const Icon(Icons.timeline_rounded, color: Colors.black),
                label: Text(
                  'Live Tracker',
                  style: ErpTypography.button.copyWith(color: Colors.black),
                ),
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'publish_fab',
            backgroundColor: ErpColors.primary,
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.campaign_rounded, color: Colors.white),
            label: Text(
              'Publish Notice',
              style: ErpTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: 5,
                itemBuilder:
                    (context, i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ErpSkeletonListItem(),
                    ),
              )
              : _notices.isEmpty
              ? const ErpEmptyState(
                message: 'No notices found',
                subtitle: 'There are no active notices for your department.',
                icon: Icons.campaign_outlined,
              )
              : RefreshIndicator(
                color: ErpColors.primary,
                onRefresh: _fetchNotices,
                child: Builder(
                  builder: (context) {
                    final approvedNotices =
                        _notices.where((n) => n.status == 'APPROVED').toList();
                    if (approvedNotices.isEmpty) {
                      return const ErpEmptyState(
                        message: 'No published notices',
                        subtitle: 'There are no active approved notices.',
                        icon: Icons.campaign_outlined,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 150),
                      itemCount: approvedNotices.length,
                      itemBuilder: (context, i) {
                        final n = approvedNotices[i];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                            milliseconds: 300 + (100 * (i % 5)),
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InteractiveNoticeCard(
                              notice: n,
                              currentUserRole: widget.role,
                              onApprove: (id) async {
                                final success = await _service.approveNotice(
                                  id.toString(),
                                  widget.role,
                                );
                                if (success && mounted) {
                                  ErpSnackbar.show(
                                    context,
                                    message: 'Notice approved successfully.',
                                    type: ErpBadgeType.success,
                                  );
                                  _fetchNotices();
                                } else if (mounted) {
                                  ErpSnackbar.show(
                                    context,
                                    message: 'Failed to approve notice.',
                                    type: ErpBadgeType.danger,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
    );
  }
}

class _PendingTrackerSheet extends StatelessWidget {
  final List<Notice> pendingNotices;
  final String currentUserRole;
  final Function(String) onApprove;

  const _PendingTrackerSheet({
    required this.pendingNotices,
    required this.currentUserRole,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ErpColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Tracker', style: ErpTypography.headlineSmall),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ErpColors.textMuted,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: pendingNotices.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InteractiveNoticeCard(
                    notice: pendingNotices[i],
                    currentUserRole: currentUserRole,
                    onApprove: onApprove,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveNoticeCard extends StatelessWidget {
  final Notice notice;
  final String currentUserRole;
  final Function(String) onApprove;

  const _InteractiveNoticeCard({
    required this.notice,
    required this.currentUserRole,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon =
        notice.category == NoticeCategory.academic
            ? Icons.school_outlined
            : notice.category == NoticeCategory.event
            ? Icons.celebration_outlined
            : notice.category == NoticeCategory.exam
            ? Icons.edit_note_outlined
            : notice.category == NoticeCategory.holiday
            ? Icons.beach_access_outlined
            : Icons.info_outline;
    return ErpCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ErpColors.infoSurface,
              borderRadius: BorderRadius.circular(ErpRadius.md),
            ),
            child: Icon(icon, color: ErpColors.info, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: ErpTypography.titleSmall,
                      ),
                    ),
                    if (notice.isImportant)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ErpColors.warningSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ErpColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Important',
                          style: ErpTypography.caption.copyWith(
                            color: ErpColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (notice.department.isNotEmpty &&
                    notice.department != 'ALL') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${notice.department} • By: ${notice.uploaderRole}',
                    style: ErpTypography.caption.copyWith(
                      color: ErpColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  notice.description,
                  style: ErpTypography.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notice.purpose.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Purpose: ${notice.purpose}',
                    style: ErpTypography.caption.copyWith(
                      color: ErpColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notice.date,
                      style: ErpTypography.caption.copyWith(
                        color: ErpColors.textMuted,
                      ),
                    ),
                    if (notice.fileUrl != null && notice.fileUrl!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 14,
                            color: ErpColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View Attachment',
                            style: ErpTypography.caption.copyWith(
                              color: ErpColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (notice.status != 'APPROVED') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ErpColors.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ErpColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LiveTracker(status: notice.status),
                        if ((notice.status == 'PENDING_HOD' &&
                                currentUserRole.toUpperCase() == 'HOD') ||
                            (notice.status == 'PENDING_ADMIN' &&
                                [
                                  'ADMIN',
                                  'SUPER_ADMIN',
                                  'DEAN',
                                ].contains(currentUserRole.toUpperCase())))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ErpColors.success,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => onApprove(notice.id),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                'Approve Notice Now',
                                style: ErpTypography.titleSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTracker extends StatelessWidget {
  final String status;
  const _LiveTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (status == 'PENDING_HOD')
      currentStep = 1;
    else if (status == 'PENDING_ADMIN')
      currentStep = 2;
    else if (status == 'APPROVED')
      currentStep = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.timeline_rounded,
              size: 14,
              color: ErpColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Live Tracking',
              style: ErpTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: ErpColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TrackerStep(
              label: 'Submitted',
              isCompleted: currentStep > 0,
              isActive: currentStep == 1,
            ),
            _TrackerDivider(isCompleted: currentStep > 1),
            _TrackerStep(
              label: 'HOD',
              isCompleted: currentStep > 1,
              isActive: currentStep == 2,
            ),
            _TrackerDivider(isCompleted: currentStep > 2),
            _TrackerStep(
              label: 'Admin',
              isCompleted: currentStep > 2,
              isActive: currentStep == 3,
            ),
          ],
        ),
      ],
    );
  }
}

class _TrackerStep extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _TrackerStep({
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    var c =
        isCompleted || isActive
            ? ErpColors.primary
            : ErpColors.textMuted.withOpacity(0.4);
    if (isActive) c = ErpColors.warning;
    if (isCompleted) c = ErpColors.success;

    return Column(
      children: [
        Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : isActive
              ? Icons.pending_rounded
              : Icons.radio_button_unchecked_rounded,
          color: c,
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: ErpTypography.caption.copyWith(
            color:
                isActive || isCompleted
                    ? ErpColors.textPrimary
                    : ErpColors.textMuted,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _TrackerDivider extends StatelessWidget {
  final bool isCompleted;
  const _TrackerDivider({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 8, left: 4, right: 4),
        color:
            isCompleted
                ? ErpColors.success
                : ErpColors.textMuted.withOpacity(0.2),
      ),
    );
  }
}

class _CreateNoticeSheet extends StatefulWidget {
  final String role;
  final String department;
  final VoidCallback onNoticeCreated;

  const _CreateNoticeSheet({
    required this.role,
    required this.department,
    required this.onNoticeCreated,
  });

  @override
  State<_CreateNoticeSheet> createState() => _CreateNoticeSheetState();
}

class _CreateNoticeSheetState extends State<_CreateNoticeSheet> {
  final NoticeService _service = NoticeService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _purposeController = TextEditingController();

  NoticeCategory _category = NoticeCategory.general;
  bool _isImportant = false;
  File? _selectedFile;
  bool _isPublishing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ErpSnackbar.show(
        context,
        message: 'Title and Description are required',
        type: ErpBadgeType.warning,
      );
      return;
    }

    setState(() => _isPublishing = true);

    // Automatically determine visibility target based on role
    // Admins publish to ALL. HODs/Teachers publish to their department.
    String targetDept =
        widget.role.toUpperCase() == 'ADMIN' ||
                widget.role.toUpperCase() == 'DEAN'
            ? 'ALL'
            : widget.department;
    if (targetDept.isEmpty) targetDept = 'ALL';

    try {
      await _service.publishNotice(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        purpose: _purposeController.text.trim(),
        category: _category.name,
        department: targetDept,
        uploaderRole: widget.role.toUpperCase(),
        isImportant: _isImportant,
        filePath: _selectedFile?.path,
      );

      if (mounted) {
        Navigator.pop(context);
        ErpSnackbar.show(
          context,
          message: 'Notice published successfully!',
          type: ErpBadgeType.success,
        );
        widget.onNoticeCreated();
      }
    } catch (e) {
      if (mounted) {
        ErpSnackbar.show(
          context,
          message: 'Error: ${e.toString()}',
          type: ErpBadgeType.danger,
        );
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ErpColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Compose Notice', style: ErpTypography.headlineSmall),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ErpColors.textMuted,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildLabel('Header / Title'),
            TextField(
              controller: _titleController,
              style: ErpTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'e.g. End Semester Schedule',
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Purpose'),
            TextField(
              controller: _purposeController,
              style: ErpTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Brief objective of this notice',
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Details / Content'),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: ErpTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Detailed information...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: ErpColors.bgWhite,
                          borderRadius: BorderRadius.circular(ErpRadius.md),
                          border: Border.all(color: ErpColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<NoticeCategory>(
                            value: _category,
                            isExpanded: true,
                            items:
                                NoticeCategory.values
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c.name.toUpperCase(),
                                          style: ErpTypography.bodyMedium,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _category = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Mark Important'),
                      SwitchListTile(
                        value: _isImportant,
                        activeColor: ErpColors.warning,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'High Priority',
                          style: ErpTypography.bodyMedium,
                        ),
                        onChanged: (v) => setState(() => _isImportant = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Attachment (PDF, PNG, etc)'),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(ErpRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ErpColors.bgSubtle,
                  borderRadius: BorderRadius.circular(ErpRadius.md),
                  border: Border.all(color: ErpColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      color:
                          _selectedFile != null
                              ? ErpColors.success
                              : ErpColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFile != null
                            ? _selectedFile!.path
                                .split(Platform.pathSeparator)
                                .last
                            : 'Tap to attach a file',
                        style: ErpTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedFile != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: ErpColors.textMuted,
                        ),
                        onPressed: () => setState(() => _selectedFile = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ErpRadius.md),
                  ),
                ),
                child:
                    _isPublishing
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Publish Automatically',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: ErpTypography.titleSmall),
    );
  }
}
