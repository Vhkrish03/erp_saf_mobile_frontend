import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/semester_results_service.dart';
import '../../theme/app_theme.dart';
import '../../screens/semester_result_detail_screen.dart';

class HodSemesterResultScreen extends StatefulWidget {
  final String hodId;
  final String department;

  const HodSemesterResultScreen({
    super.key,
    required this.hodId,
    required this.department,
  });

  @override
  State<HodSemesterResultScreen> createState() =>
      _HodSemesterResultScreenState();
}

class _HodSemesterResultScreenState extends State<HodSemesterResultScreen>
    with SingleTickerProviderStateMixin {
  final SemesterResultsService _resultsService = SemesterResultsService();

  late TabController _tabController;

  String _year = '3';
  String _semester = 'I';
  String _section = 'A';
  String _academicYear = '2026-27';
  bool _isLoading = false;
  String? _error;

  final _years = ['1', '2', '3', '4'];
  final _semesters = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
  final _sections = ['A', 'B', 'C'];

  List<Map<String, dynamic>> _studentsResults = [];
  Map<String, dynamic>? _statistics;

  String _getYearLabel(String val) {
    switch (val) {
      case '1':
        return '1st Year';
      case '2':
        return '2nd Year';
      case '3':
        return '3rd Year';
      case '4':
        return '4th Year';
      default:
        return 'Year $val';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHodData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHodData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _resultsService.getHodStudentsResults(
        hodId: widget.hodId,
        academicYear: _academicYear,
        year: _year,
        semester: _semester,
        department: widget.department,
        section: _section,
      );

      final stats = await _resultsService.getHodStatistics(
        hodId: widget.hodId,
        academicYear: _academicYear,
        year: _year,
        semester: _semester,
        department: widget.department,
        section: _section,
      );

      setState(() {
        _studentsResults = results;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          'Department Results Performance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterPanel(),
            Container(
              color: AppColors.navy,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.brass,
                labelColor: AppColors.brass,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Analytics', icon: Icon(Icons.analytics_outlined)),
                  Tab(
                    text: 'Students Results',
                    icon: Icon(Icons.groups_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brass,
                        ),
                      )
                      : _error != null
                      ? _buildErrorView()
                      : TabBarView(
                        controller: _tabController,
                        children: [_buildAnalyticsTab(), _buildStudentsTab()],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: AppColors.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildLockedField('Department', widget.department),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Year',
                      value: _year,
                      items: _years,
                      onChanged: (v) {
                        setState(() => _year = v!);
                      },
                      itemLabelBuilder: _getYearLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Semester',
                      value: _semester,
                      items: _semesters,
                      onChanged: (v) {
                        setState(() => _semester = v!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Section',
                      value: _section,
                      items: _sections,
                      onChanged: (v) {
                        setState(() => _section = v!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _fetchHodData,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(
                    'Load Analytics & results',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedField(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            val,
            style: GoogleFonts.poppins(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    ValueChanged<String> onChanged,
    String initialVal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextFormField(
            initialValue: initialVal,
            onChanged: onChanged,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? itemLabelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.poppins(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              items:
                  items
                      .map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            itemLabelBuilder != null ? itemLabelBuilder(i) : i,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    if (_statistics == null) {
      return const Center(child: Text("No analytic statistics loaded."));
    }

    final total = _statistics!['totalStudents'] ?? 0;
    final passed = _statistics!['passedStudents'] ?? 0;
    final failed = _statistics!['failedStudents'] ?? 0;
    final passPct = (_statistics!['passPercentage'] as num?)?.toDouble() ?? 0.0;
    final avgSgpa =
        (_statistics!['classAverageSgpa'] as num?)?.toDouble() ?? 0.0;

    final subWiseMap =
        _statistics!['subjectWiseStatistics'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of KPIs
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Pass Rate',
                  '${passPct.toStringAsFixed(1)}%',
                  Icons.percent_rounded,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  'Class Avg SGPA',
                  avgSgpa.toStringAsFixed(2),
                  Icons.stars_rounded,
                  AppColors.brass,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Students Registered',
                  '$total',
                  Icons.people_alt_outlined,
                  AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  'Passed / Failed',
                  '$passed / $failed',
                  Icons.rule_rounded,
                  failed > 0 ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Subject-Wise Performance Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),

          if (subWiseMap.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    "No subject-wise statistic profiles recorded.",
                    style: GoogleFonts.poppins(color: AppColors.inkMuted),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subWiseMap.length,
              itemBuilder: (context, idx) {
                final key = subWiseMap.keys.elementAt(idx);
                final subData = subWiseMap[key] as Map<String, dynamic>;
                final code = subData['subjectCode'] ?? key;
                final name = subData['subjectName'] ?? 'Unknown Course';
                final double subAvg =
                    (subData['averageGradePoint'] as num?)?.toDouble() ?? 0.0;
                final subPassed = subData['passedCount'] ?? 0;
                final subFailed = subData['failedCount'] ?? 0;
                final int subTotal = subPassed + subFailed;
                final double subPassPct =
                    subTotal > 0 ? (subPassed / subTotal) * 100 : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.navy.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                code,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMiniStat(
                              'Pass Rate',
                              '${subPassPct.toStringAsFixed(1)}%',
                            ),
                            const SizedBox(width: 20),
                            _buildMiniStat('Avg GP', subAvg.toStringAsFixed(2)),
                            const SizedBox(width: 20),
                            _buildMiniStat(
                              'Passed / Total',
                              '$subPassed / $subTotal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: subPassPct / 100,
                          backgroundColor: Colors.black12,
                          color:
                              subPassPct > 80
                                  ? AppColors.success
                                  : subPassPct > 50
                                  ? AppColors.brass
                                  : AppColors.danger,
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    if (_studentsResults.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _studentsResults.length,
      itemBuilder: (context, index) {
        final item = _studentsResults[index];
        final name = item['studentName']?.toString() ?? 'Unknown Student';
        final roll = item['rollNumber']?.toString() ?? 'N/A';
        final studentId = item['studentId']?.toString() ?? '';
        final double sgpa = (item['sgpa'] as num?)?.toDouble() ?? 0.0;
        final status = item['status']?.toString() ?? 'DRAFT';

        final hasFailed =
            item['subjects'] != null &&
            (item['subjects'] as List).any((s) {
              final res = s['resultStatus']?.toString().toUpperCase();
              final gr = s['grade']?.toString().toUpperCase();
              return res == 'FAIL' || gr == 'RA' || gr == 'U';
            });

        final bool isPassed = !hasFailed && sgpa > 0.0;
        final badgeColor = isPassed ? AppColors.success : AppColors.danger;
        final badgeText = isPassed ? "PASS" : "FAIL";

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              final studentSem = item['semester']?.toString() ?? 'V';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SemesterResultDetailScreen(
                        studentId: studentId,
                        semesterName: studentSem,
                        studentName: name,
                        rollNumber: roll,
                        department: widget.department,
                        cumulativeCgpa: 0.0,
                        hodId: widget.hodId,
                      ),
                ),
              );
            },
            title: Text(
              name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Roll: $roll',
                  style: GoogleFonts.poppins(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SGPA: ${sgpa.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return AppColors.success;
      case 'APPROVED':
        return AppColors.navyLight;
      case 'VERIFIED':
        return AppColors.brass;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No student semester exam records found matching\nthese filter parameters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              'Error Fetching Department Results',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchHodData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
