import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../theme/app_theme.dart';
import '../../teacher/services/attendance_service.dart';

class HodAttendanceReportsScreen extends StatefulWidget {
  final String department;
  const HodAttendanceReportsScreen({Key? key, required this.department})
    : super(key: key);

  @override
  State<HodAttendanceReportsScreen> createState() =>
      _HodAttendanceReportsScreenState();
}

class _HodAttendanceReportsScreenState
    extends State<HodAttendanceReportsScreen> {
  final AttendanceService _service = AttendanceService();
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedYear = 'All';
  String _selectedSection = 'All';
  String _selectedSubject = 'All';

  final List<String> _years = [
    'All',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
  final List<String> _sections = ['All', 'A', 'B', 'C'];
  final List<String> _subjects = [
    'All',
    'Data Structures',
    'Database Management Systems',
    'Operating Systems',
    'Computer Networks',
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await _service.getReportsForHod(widget.department);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load reports: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic client-side filtering based on selected Year, Section, and Subject
    final filteredReports =
        _reports.where((r) {
          final String rYear = r['studentYear'] ?? '';
          final String rSection = r['section'] ?? '';
          final String rSubject = r['subject'] ?? '';

          final matchYear =
              _selectedYear == 'All' ||
              rYear.toLowerCase().trim() == _selectedYear.toLowerCase().trim();
          final matchSection =
              _selectedSection == 'All' ||
              rSection.toLowerCase().trim() ==
                  _selectedSection.toLowerCase().trim();
          final matchSubject =
              _selectedSubject == 'All' ||
              rSubject.toLowerCase().trim() ==
                  _selectedSubject.toLowerCase().trim();

          return matchYear && matchSection && matchSubject;
        }).toList();

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        elevation: 0,
        title: Text(
          "${widget.department} Attendance Audit",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadReports,
            tooltip: "Refresh Reports",
          ),
        ],
      ),
      body:
          _isLoading
              ? const _HodReportsSkeleton()
              : _errorMessage != null
              ? ErpErrorState(
                message: 'We could not retrieve attendance reports right now.',
                onRetry: _loadReports,
              )
              : Column(
                children: [
                  _buildFilterPanel(),
                  Expanded(
                    child:
                        filteredReports.isEmpty
                            ? ErpEmptyState(
                              message: _reports.isEmpty
                                  ? 'No attendance reports yet'
                                  : 'No reports match these filters',
                              subtitle: _reports.isEmpty
                                  ? 'Submitted departmental attendance reports will appear here.'
                                  : 'Try adjusting the selected year, section, or subject.',
                              icon: Icons.assignment_turned_in_outlined,
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredReports.length,
                              itemBuilder: (ctx, i) {
                                final r = filteredReports[i];
                                return _buildReportCard(r);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFilterPanel() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  color: AppColors.brass,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Filter Reports",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear = 'All';
                      _selectedSection = 'All';
                      _selectedSubject = 'All';
                    });
                  },
                  child: const Text(
                    "Reset All",
                    style: TextStyle(
                      color: AppColors.brass,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                          label: "Year",
                          value: _selectedYear,
                          items: _years,
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterDropdown(
                          label: "Section",
                          value: _selectedSection,
                          items: _sections,
                          onChanged:
                              (v) => setState(() => _selectedSection = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildFilterDropdown(
                          label: "Subject",
                          value: _selectedSubject,
                          items: _subjects,
                          onChanged:
                              (v) => setState(() => _selectedSubject = v!),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFilterDropdown(
                        label: "Year",
                        value: _selectedYear,
                        items: _years,
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(
                        label: "Section",
                        value: _selectedSection,
                        items: _sections,
                        onChanged: (v) => setState(() => _selectedSection = v!),
                      ),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(
                        label: "Subject",
                        value: _selectedSubject,
                        items: _subjects,
                        onChanged: (v) => setState(() => _selectedSubject = v!),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items:
                  items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.ink),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.brass),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final String subject = report['subject'] ?? 'Unknown Subject';
    final String section = report['section'] ?? '';
    final String year = report['studentYear'] ?? '';
    final String dateStr = report['date'] ?? '';
    final int present = report['presentCount'] ?? 0;
    final int absent = report['absentCount'] ?? 0;
    final int total = report['totalStudents'] ?? 0;
    final String submittedBy = report['submittedBy'] ?? 'Unknown Instructor';
    final String recordsJson = report['studentRecordsJson'] ?? '[]';

    return Card(
      color: AppColors.card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.brass,
        collapsedIconColor: AppColors.inkMuted,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$year - Sec $section",
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.person_outline,
                  size: 13,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "By: $submittedBy",
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _statusBadge(
                "Present: $present",
                AppColors.success,
                Colors.white,
              ),
              const SizedBox(width: 8),
              _statusBadge("Absent: $absent", AppColors.danger, Colors.white),
              const SizedBox(width: 8),
              _statusBadge("Total: $total", AppColors.navy, Colors.white),
            ],
          ),
        ),
        children: [const Divider(height: 1), _buildRosterList(recordsJson)],
      ),
    );
  }

  Widget _statusBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bg),
      ),
    );
  }

  Widget _buildRosterList(String recordsJson) {
    List<dynamic> list = [];
    try {
      list = jsonDecode(recordsJson) as List<dynamic>;
    } catch (_) {}

    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "No student details available.",
          style: TextStyle(
            color: AppColors.inkMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final item = list[idx];
          final String name = item['studentName'] ?? 'Student';
          final String roll = item['rollNumber'] ?? '';
          final bool present = item['isPresent'] ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor:
                      present ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      if (roll.isNotEmpty)
                        Text(
                          roll,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  present ? "PRESENT" : "ABSENT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: present ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HodReportsSkeleton extends StatelessWidget {
  const _HodReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 150, radius: 16),
        SizedBox(height: 16),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
