import 'package:flutter/material.dart';
import '../models/LibraryBookModel.dart';
import '../services/LibraryBookService.dart';
import '../core/design_system.dart';

class LibraryScreen extends StatefulWidget {
  final String? studentId;
  const LibraryScreen({super.key, this.studentId});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

final LibraryService libraryService = LibraryService();

List<LibraryBook> issuedBooks = [];

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    if (widget.studentId == null || widget.studentId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      issuedBooks = await libraryService.getBooks(widget.studentId!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: ErpAppBar(title: 'Library'),
        body: _LibrarySkeleton(),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: const ErpAppBar(title: 'Library'),
        body: ErpErrorState(
          message: 'We could not retrieve your library record right now.',
          onRetry: loadBooks,
        ),
      );
    }

    return Scaffold(
      appBar: const ErpAppBar(title: 'Library'),
      body: RefreshIndicator(
        color: ErpColors.primary,
        onRefresh: loadBooks,
        child: ListView(
          padding: ErpSpacing.pagePadding,
          children: [
            ErpSectionHeader(
              title: 'Issued books',
              subtitle: issuedBooks.isEmpty
                  ? 'Your current loans will appear here.'
                  : '${issuedBooks.length} book${issuedBooks.length == 1 ? '' : 's'} on loan',
            ),
            if (issuedBooks.isEmpty)
              const ErpEmptyState(
                message: 'No books currently issued',
                subtitle: 'You do not have any active library loans.',
                icon: Icons.menu_book_outlined,
              )
            else
              ...issuedBooks.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: ErpSpacing.md),
                  child: ErpCard(
                    border: Border.all(
                      color: b.isOverdue
                          ? ErpColors.danger.withValues(alpha: 0.4)
                          : ErpColors.border,
                      ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 58,
                          decoration: BoxDecoration(
                            color: ErpColors.librarySurface,
                            borderRadius: ErpRadius.cardSm,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.menu_book_outlined,
                            color: ErpColors.library,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.title, style: ErpTypography.titleMedium),
                              const SizedBox(height: 2),
                              Text(b.author, style: ErpTypography.bodySmall),
                              const SizedBox(height: 6),
                              Text(
                                b.isOverdue
                                    ? 'Overdue since ${b.dueDate}'
                                    : 'Due on ${b.dueDate}',
                                style: ErpTypography.labelSmall.copyWith(
                                  color: b.isOverdue
                                      ? ErpColors.danger
                                      : ErpColors.textMuted,
                                  fontWeight: b.isOverdue
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (b.isOverdue)
                          const ErpStatusBadge(
                            label: 'Overdue',
                            type: ErpBadgeType.danger,
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: ErpSpacing.lg),
            const ErpSectionHeader(
              title: 'Search catalog',
              subtitle: 'Find books by title, author, or ISBN.',
            ),
            ErpTextField(
              hint: 'Search by title, author, or ISBN',
              prefixIcon: Icons.search,
              suffixIcon: IconButton(
                tooltip: 'Scan ISBN',
                icon: const Icon(Icons.qr_code_scanner_outlined),
                onPressed: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: [
        const ErpSkeleton(width: 140, height: 22),
        const SizedBox(height: 8),
        const ErpSkeleton(width: 220, height: 13),
        const SizedBox(height: ErpSpacing.lg),
        ...List.generate(3, (_) => const ErpSkeletonListItem()),
        const SizedBox(height: ErpSpacing.md),
        const ErpSkeleton(width: 150, height: 22),
        const SizedBox(height: 12),
        const ErpSkeleton(height: 52, radius: 12),
      ],
    );
  }
}
