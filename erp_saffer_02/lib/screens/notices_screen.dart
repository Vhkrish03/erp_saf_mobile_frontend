import 'package:erp_saf/services/notice_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/design_system.dart';
import '../models/notice.dart';

class NoticesScreen extends StatefulWidget {
  final bool embedded;
  final String studentId;

  const NoticesScreen({
    super.key,
    this.embedded = false,
    this.studentId = "STU25",
  });

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  NoticeCategory? _filter;
  final NoticeService noticeService = NoticeService();

  List<Notice> notices = [];
  bool _noticesLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadNotices();
  }

  Future<void> loadNotices() async {
    setState(() {
      _noticesLoading = true;
      _error = null;
    });
    try {
      notices = await noticeService.getNotices(
        'STUDENT',
        'ALL',
      ); // Default to ALL or actual department if available
    } catch (e) {
      _error = 'We could not retrieve notices right now.';
      debugPrint("Error loading notices: $e");
    } finally {
      if (mounted) {
        setState(() {
          _noticesLoading = false;
        });
      }
    }
  }

  static const _labels = {
    NoticeCategory.academic: 'Academic',
    NoticeCategory.event: 'Events',
    NoticeCategory.exam: 'Exams',
    NoticeCategory.holiday: 'Holidays',
    NoticeCategory.general: 'General',
  };

  static const _icons = {
    NoticeCategory.academic: Icons.school_outlined,
    NoticeCategory.event: Icons.celebration_outlined,
    NoticeCategory.exam: Icons.edit_note_outlined,
    NoticeCategory.holiday: Icons.beach_access_outlined,
    NoticeCategory.general: Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: ErpColors.primary,
      elevation: 0,
      leading:
          widget.embedded
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
      title: Text(
        'Campus Notices',
        style: ErpTypography.titleLarge.copyWith(color: ErpColors.accent),
      ),
    );

    final filteredNotices =
        _filter == null
            ? notices
            : notices.where((n) => n.category == _filter).toList();

    final noticesBody =
      _noticesLoading
        ? const _NoticesSkeleton()
        : _error != null
        ? ErpErrorState(message: _error!, onRetry: loadNotices)
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _chip(
                        'All',
                        _filter == null,
                        () => setState(() => _filter = null),
                      ),
                      const SizedBox(width: 8),
                      ..._labels.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _chip(
                            e.value,
                            _filter == e.key,
                            () => setState(() => _filter = e.key),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    color: ErpColors.primary,
                    onRefresh: loadNotices,
                    child:
                        filteredNotices.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 60),
                                ErpEmptyState(
                                  message: 'No notices found',
                                  subtitle: 'There are no notices matching this category.',
                                  icon: Icons.campaign_outlined,
                                ),
                              ],
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: filteredNotices.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder:
                                  (context, i) => _NoticeCard(
                                    notice: filteredNotices[i],
                                    icon: _icons[filteredNotices[i].category]!,
                                  ),
                            ),
                  ),
                ),
              ],
            );

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: appBar,
      body: noticesBody,
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final IconData icon;
  const _NoticeCard({required this.notice, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ErpColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.moduleNotices, size: 20),
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (notice.isImportant)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ErpColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Important',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notice.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  notice.date,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticesSkeleton extends StatelessWidget {
  const _NoticesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: const [
        ErpSkeleton(width: 180, height: 38, radius: 20),
        SizedBox(height: 18),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
