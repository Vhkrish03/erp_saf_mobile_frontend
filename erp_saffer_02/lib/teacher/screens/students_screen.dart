import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/student_summary.dart';
import '../services/attendance_service.dart';
import '../theme/teacher_theme.dart';
import '../widgets/student_card.dart';
import '../services/teacher_service.dart';

class StudentsScreen extends StatefulWidget {
  final String employeeId;
  const StudentsScreen({super.key, required this.employeeId});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  // Reusing AttendanceService's roster fetch as the students data source
  // (both draw from the same student-roster backend resource).
  final AttendanceService _service = AttendanceService();
  final TeacherService _teacherService = TeacherService();

  late Future<List<StudentSummary>> _studentsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _department = 'CSE';
  String _year = 'All';
  String _section = 'All';
  String _searchQuery = '';

  bool _isLoadingDept = true;

  List<String> _departments = ['CSE'];
  final _years = ['All', '1', '2', '3', '4'];
  final _sections = ['All', 'A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    _fetchTeacherAndLoad();
  }

  Future<void> _fetchTeacherAndLoad() async {
    try {
      final teacher = await _teacherService.getTeacherProfile(
        widget.employeeId,
      );
      if (mounted) {
        setState(() {
          _department = teacher.department.toUpperCase();
          _departments = [_department];
          _isLoadingDept = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDept = false;
        });
      }
    }
    _loadStudents();
  }

  void _loadStudents() {
    setState(() {
      _studentsFuture = _service.getStudentsForAttendance(
        department: _department == "All" ? "" : _department,
        year: _year == "All" ? "" : _year,
        section: _section == "All" ? "" : _section,
        date: DateTime.now(),
      );
    });
  }

  List<StudentSummary> _applyFilters(List<StudentSummary> students) {
    return students.where((s) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      // Department, Year, and Section are already handled by the service during load
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(title: const Text('Students')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or roll number',
                      prefixIcon: Icon(
                        Icons.search,
                        color: TeacherColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isLoadingDept)
                    Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Department',
                            value: _department,
                            items: _departments,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _department = v;
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Year',
                            value: _year,
                            items: _years,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _year = v;
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Section',
                            value: _section,
                            items: _sections,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _section = v;
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoadingDept
                      ? const _StudentsSkeleton()
                      : FutureBuilder<List<StudentSummary>>(
                        future: _studentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _StudentsSkeleton();
                          }
                          if (snapshot.hasError) {
                            return ErpErrorState(
                              message: 'We could not retrieve students right now.',
                              onRetry: _loadStudents,
                            );
                          }
                          final filtered = _applyFilters(snapshot.data ?? []);
                          if (filtered.isEmpty) {
                            return const ErpEmptyState(
                              message: 'No students found',
                              subtitle: 'Try adjusting the search or selected filters.',
                              icon: Icons.groups_outlined,
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final student = filtered[i];
                              return StudentCard(
                                student: student,
                                onViewProfile:
                                    () => _showStudentProfile(context, student),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentProfile(BuildContext context, StudentSummary student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: TeacherTextStyles.heading1),
              const SizedBox(height: 4),
              Text(student.rollNumber, style: TeacherTextStyles.bodyMuted),
              const Divider(height: 32),
              _ProfileRow(label: 'Department', value: student.department),
              _ProfileRow(label: 'Semester', value: student.semester),
              _ProfileRow(label: 'Section', value: student.section),
              _ProfileRow(
                label: 'Attendance',
                value: '${student.attendancePercentage.toStringAsFixed(1)}%',
              ),
              _ProfileRow(
                label: 'CGPA',
                value: student.cgpa.toStringAsFixed(2),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentsSkeleton extends StatelessWidget {
  const _StudentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TeacherTextStyles.bodyMuted),
          Text(value, style: TeacherTextStyles.heading3),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeacherColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            fontSize: 12.5,
            color: TeacherColors.textPrimary,
          ),
          items:
              items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
