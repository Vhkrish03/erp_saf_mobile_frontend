import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/semester_results_service.dart';
import '../theme/teacher_theme.dart';
import '../services/teacher_service.dart';
import '../../screens/semester_result_detail_screen.dart';

class TeacherSemesterResultScreen extends StatefulWidget {
  final String employeeId;
  const TeacherSemesterResultScreen({super.key, required this.employeeId});

  @override
  State<TeacherSemesterResultScreen> createState() =>
      _TeacherSemesterResultScreenState();
}

class _TeacherSemesterResultScreenState
    extends State<TeacherSemesterResultScreen> {
  final SemesterResultsService _resultsService = SemesterResultsService();
  final TeacherService _teacherService = TeacherService();

  String _dept = 'CSE';
  String _year = '3';
  String _semester = 'I';
  String _section = 'A';
  String _academicYear = '2026-27';
  bool _isLoadingProfile = true;
  bool _isLoadingResults = false;
  String? _error;

  final _years = ['1', '2', '3', '4'];
  final _semesters = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
  final _sections = ['A', 'B', 'C'];
  List<Map<String, dynamic>> _studentsResults = [];

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
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final profile = await _teacherService.getTeacherProfile(
        widget.employeeId,
      );
      setState(() {
        _dept = profile.department.toUpperCase();
        _isLoadingProfile = false;
      });
      _fetchResults();
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _error = "Could not fetch teacher department: ${e.toString()}";
      });
    }
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoadingResults = true;
      _error = null;
    });

    try {
      final results = await _resultsService.getTeacherStudentsResults(
        teacherId: widget.employeeId,
        academicYear: _academicYear,
        year: _year,
        semester: _semester,
        department: _dept,
        section: _section,
      );
      setState(() {
        _studentsResults = results;
        _isLoadingResults = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResults = false;
        _error = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        backgroundColor: TeacherColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          'Semester Exam Results',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoadingProfile
              ? const Center(
                child: CircularProgressIndicator(color: TeacherColors.navy),
              )
              : SafeArea(
                child: Column(
                  children: [
                    _buildFilterPanel(),
                    Expanded(
                      child:
                          _isLoadingResults
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: TeacherColors.navy,
                                ),
                              )
                              : _error != null
                              ? _buildErrorView()
                              : _studentsResults.isEmpty
                              ? _buildEmptyView()
                              : _buildStudentsList(),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: TeacherDecorations.card(radius: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildLockedField('Department', _dept)),
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
                  backgroundColor: TeacherColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _fetchResults,
                icon: const Icon(Icons.search_rounded),
                label: Text(
                  'Search Results',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
          style: GoogleFonts.outfit(
            color: Colors.black54,
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
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            val,
            style: GoogleFonts.outfit(
              color: Colors.black87,
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
          style: GoogleFonts.outfit(
            color: Colors.black54,
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
            style: GoogleFonts.outfit(
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
                borderSide: const BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black12),
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
          style: GoogleFonts.outfit(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.outfit(
                color: Colors.black87,
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

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        final badgeColor =
            isPassed ? TeacherColors.success : TeacherColors.danger;
        final badgeText = isPassed ? "PASS" : "FAIL";

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
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
                        department: _dept,
                        cumulativeCgpa: 0.0,
                        teacherId: widget.employeeId,
                      ),
                ),
              );
            },
            title: Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: TeacherColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Roll: $roll',
                  style: GoogleFonts.outfit(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
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
                        style: GoogleFonts.outfit(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SGPA: ${sgpa.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: TeacherColors.navy,
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
                    style: GoogleFonts.outfit(
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
        return TeacherColors.success;
      case 'APPROVED':
        return TeacherColors.info;
      case 'VERIFIED':
        return TeacherColors.brass;
      default:
        return TeacherColors.warning;
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
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No student semester exam records found matching\nthese filter parameters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.black38),
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
              'Error Fetching Semester Results',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.black38),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.navy,
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchResults,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
