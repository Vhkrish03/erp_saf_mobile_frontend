import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/student_summary.dart';
import '../services/attendance_service.dart';
import '../theme/teacher_theme.dart';

class AttendanceScreen extends StatefulWidget {
  final String employeeId;
  const AttendanceScreen({super.key, required this.employeeId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _service = AttendanceService();

  String? _department;
  String? _year;
  String? _section;
  DateTime _date = DateTime.now();

  List<AssignedClass> _assignedClasses = [];
  AssignedClass? _selectedClass;

  List<StudentSummary> _students = [];
  final Map<String, bool> _presence = {};
  bool _loading = true;
  bool _saving = false;
  bool _isAlreadySubmitted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignmentsAndRoster();
  }

  Future<void> _loadAssignmentsAndRoster() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final classes = await _service.getAssignedClasses(widget.employeeId);
      setState(() {
        _assignedClasses = classes;
        if (classes.isNotEmpty) {
          _selectedClass = classes.first;
          _department = _selectedClass!.department;
          _year = _selectedClass!.year;
          _section = _selectedClass!.section;
        }
      });

      if (_selectedClass != null) {
        await _loadRoster();
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'We could not retrieve your attendance assignments.';
        });
      }
    }
  }

  void _onClassChanged(AssignedClass? newClass) {
    if (newClass == null) return;
    setState(() {
      _selectedClass = newClass;
      _department = newClass.department;
      _year = newClass.year;
      _section = newClass.section;
    });
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    if (_department == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {

    final existingReport = await _service.checkAttendanceExists(
      department: _department!,
      year: _year!,
      section: _section!,
      date: _date,
    );

    final students = await _service.getStudentsForAttendance(
      department: _department!,
      year: _year!,
      section: _section!,
      date: _date,
    );

    print("Students count: ${students.length}");

    setState(() {
      _students = students;
      _presence.clear();

      if (existingReport != null) {
        _isAlreadySubmitted = true;
        List<dynamic> list = [];
        try {
          list =
              jsonDecode(existingReport['studentRecordsJson'] ?? '[]')
                  as List<dynamic>;
        } catch (_) {}

        final Map<String, bool> parsedPresence = {};
        for (var item in list) {
          final String sId = item['studentId'] ?? '';
          final bool isPres = item['isPresent'] ?? false;
          if (sId.isNotEmpty) {
            parsedPresence[sId] = isPres;
          }
        }
        for (var s in students) {
          _presence[s.id] = parsedPresence[s.id] ?? true;
        }
      } else {
        _isAlreadySubmitted = false;
        _presence.addEntries(students.map((s) => MapEntry(s.id, true)));
      }

      _loading = false;
    });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'We could not retrieve the attendance roster.';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _loadRoster();
    }
  }

  Future<void> _saveAttendance() async {
    if (_department == null) return;
    setState(() => _saving = true);
    final records =
        _presence.entries
            .map((e) => AttendanceRecord(studentId: e.key, isPresent: e.value))
            .toList();
    final success = await _service.saveAttendance(
      department: _department!,
      year: _year!,
      section: _section!,
      subject: "", // Removed subject
      date: _date,
      records: records,
      submittedBy: widget.employeeId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      _loadRoster();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Day attendance finalized and forwarded to HOD/Admin.'
              : 'Failed to submit attendance.',
        ),
        backgroundColor: success ? TeacherColors.success : TeacherColors.danger,
      ),
    );
  }

  int get _presentCount => _presence.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(title: const Text('Attendance')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: TeacherDecorations.card(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Class',
                                style: TeacherTextStyles.label,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: TeacherColors.divider,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<AssignedClass>(
                                    value: _selectedClass,
                                    isExpanded: true,
                                    items:
                                        _assignedClasses.map((ac) {
                                          return DropdownMenuItem<
                                            AssignedClass
                                          >(
                                            value: ac,
                                            child: Text(
                                              '${ac.department} - ${ac.year} - ${ac.section}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: _onClassChanged,
                                    hint: const Text('No active assignments'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: TeacherTextStyles.label),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  '${_date.day}/${_date.month}/${_date.year}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_assignedClasses.isEmpty && !_loading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'You are not currently assigned as Incharge for any class.',
                          style: TextStyle(
                            color: TeacherColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadRoster,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Load Attendance Roster'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Present: $_presentCount / ${_students.length}',
                      style: TeacherTextStyles.brassAccent,
                    ),
                    if (_isAlreadySubmitted)
                      const Text(
                        'SUBMITTED',
                        style: TextStyle(
                          color: TeacherColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            if (!_loading && _isAlreadySubmitted)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TeacherColors.brass.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: TeacherColors.brass.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_person_outlined,
                      color: TeacherColors.brass,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Day Attendance Submitted.\nData has been forwarded securely to the HOD and Admin. No further updates are permitted for this day.',
                        style: TextStyle(
                          color: TeacherColors.brass,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child:
                  _loading
                      ? const _TeacherAttendanceSkeleton()
                      : _errorMessage != null
                      ? ErpErrorState(
                        message: _errorMessage!,
                        onRetry: _loadAssignmentsAndRoster,
                      )
                      : _students.isEmpty
                      ? const ErpEmptyState(
                        message: 'No students in this roster',
                        subtitle: 'Choose another class or date to load students.',
                        icon: Icons.groups_outlined,
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                        itemCount: _students.length,
                        itemBuilder: (context, i) {
                          final s = _students[i];
                          final present = _presence[s.id] ?? true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: TeacherDecorations.card(radius: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: TeacherTextStyles.heading3,
                                      ),
                                      Text(
                                        s.rollNumber,
                                        style: TeacherTextStyles.bodyMuted,
                                      ),
                                    ],
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Present'),
                                  selected: present,
                                  selectedColor: TeacherColors.success
                                      .withOpacity(0.15),
                                  labelStyle: TextStyle(
                                    color:
                                        present
                                            ? TeacherColors.success
                                            : TeacherColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  onSelected:
                                      _isAlreadySubmitted
                                          ? null
                                          : (_) => setState(
                                            () => _presence[s.id] = true,
                                          ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Absent'),
                                  selected: !present,
                                  selectedColor: TeacherColors.danger
                                      .withOpacity(0.15),
                                  labelStyle: TextStyle(
                                    color:
                                        !present
                                            ? TeacherColors.danger
                                            : TeacherColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  onSelected:
                                      _isAlreadySubmitted
                                          ? null
                                          : (_) => setState(
                                            () => _presence[s.id] = false,
                                          ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            if (!_isAlreadySubmitted)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveAttendance,
                    icon:
                        _saving
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _saving ? 'Submitting...' : 'Submit to HOD & Admin',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.navy,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeacherAttendanceSkeleton extends StatelessWidget {
  const _TeacherAttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
