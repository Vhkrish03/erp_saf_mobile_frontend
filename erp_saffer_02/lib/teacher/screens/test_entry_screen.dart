import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_constants.dart';
import '../models/teacher.dart';
import '../services/teacher_service.dart';
import '../models/assessment_model.dart';
import '../services/assessment_service.dart';
import '../theme/teacher_theme.dart';
import 'mark_entry_screen.dart';
import 'incharge_dashboard_screen.dart';
import 'hod_verification_screen.dart';
import 'dean_submission_screen.dart';

class TestEntryScreen extends StatefulWidget {
  final String employeeId;
  const TestEntryScreen({super.key, required this.employeeId});

  @override
  State<TestEntryScreen> createState() => _TestEntryScreenState();
}

class _TestEntrySkeleton extends StatelessWidget {
  const _TestEntrySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 120, radius: 16),
        SizedBox(height: 16),
        ErpSkeleton(height: 48, radius: 10),
        SizedBox(height: 16),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _TestEntryScreenState extends State<TestEntryScreen> {
  final AssessmentService _api = AssessmentService();
  final TeacherService _profileService = TeacherService();

  Teacher? _teacherProfile;
  List<AssessmentModel> _allAssessments = [];
  List<AssessmentModel> _weeklyAssessments = [];
  List<AssessmentModel> _iatAssessments = [];
  List<AssessmentModel> _modelAssessments = [];
  bool _loading = true;
  String _error = '';

  List<dynamic> _assignments = [];
  bool _hasFetchedAssignments = false;

  String _selectedDept = 'CSE';
  String _selectedSemester = 'VII';
  String _selectedSection = 'A';

  int _activeSubTab = 0; // 0 = Weekly, 1 = IATs

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      // 1. Fetch Teacher Profile with local mock fallback
      if (_teacherProfile == null) {
        try {
          _teacherProfile = await _profileService
              .getTeacherProfile(widget.employeeId)
              .timeout(const Duration(seconds: 30));
        } catch (_) {
          // Fallback profile
          _teacherProfile = Teacher(
            employeeId: widget.employeeId,
            name:
                (widget.employeeId == 'EMP006' || widget.employeeId == 'FAC001')
                    ? 'Vinitha Mam'
                    : 'Dr. Meera Krishnan',
            department: 'CSE',
            designation:
                widget.employeeId == 'DEAN001' ? 'Dean' : 'Assistant Professor',
            qualification: 'M.Tech, Ph.D',
            experience: '10 Years',
            phone: '+91 99999 88888',
            email: 'faculty@college.edu',
            address: 'Chennai',
          );
        }
      }

      // 2. Fetch assignments from database for the logged-in teacher
      if (!_hasFetchedAssignments) {
        final url =
            "${ApiConstants.baseUrl}/api/faculty-subjects/teacher/${widget.employeeId}";
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 30));
        if (res.statusCode == 200) {
          _assignments = jsonDecode(res.body);
          _hasFetchedAssignments = true;
          if (_assignments.isNotEmpty) {
            final first = _assignments.first;
            _selectedDept = first["department"] ?? 'CSE';
            _selectedSemester = first["semester"] ?? 'VII';
            _selectedSection = first["section"] ?? 'A';
          } else {
            setState(() {
              _error = "ACCESS_RESTRICTED";
              _loading = false;
            });
            return;
          }
        } else {
          throw Exception(
            "Failed to load subject assignments (Status Code: ${res.statusCode})",
          );
        }
      }

      // Get current selected assignment subject code
      final currentAsn = _assignments.firstWhere(
        (asn) =>
            asn["department"] == _selectedDept &&
            asn["semester"] == _selectedSemester &&
            asn["section"] == _selectedSection,
        orElse: () => null,
      );
      final currentCode = currentAsn != null ? currentAsn["subjectCode"] : null;

      // 3. Fetch Assessments with Timeout concurrently
      final futures = await Future.wait([
        _api
            .getWeeklyAssessments(
              department: _selectedDept,
              semester: _selectedSemester,
              section: _selectedSection,
            )
            .timeout(const Duration(seconds: 30)),
        _api
            .getIatAssessments(
              department: _selectedDept,
              semester: _selectedSemester,
              section: _selectedSection,
            )
            .timeout(const Duration(seconds: 30)),
        _api
            .getModelAssessments(
              department: _selectedDept,
              semester: _selectedSemester,
              section: _selectedSection,
            )
            .timeout(const Duration(seconds: 30)),
      ]);

      final weekly = futures[0];
      final iats = futures[1];
      final models = futures[2];

      if (mounted) {
        setState(() {
          _allAssessments = [...weekly, ...iats, ...models];
          // Filter assessments taught by the logged-in teacher and matching the assigned subject
          _weeklyAssessments =
              weekly.where((asm) {
                final matchFaculty = asm.facultyId == widget.employeeId;
                final matchSubject =
                    currentCode == null || asm.subject?.code == currentCode;
                return matchFaculty && matchSubject;
              }).toList();

          _iatAssessments =
              iats.where((asm) {
                final matchFaculty = asm.facultyId == widget.employeeId;
                final matchSubject =
                    currentCode == null || asm.subject?.code == currentCode;
                return matchFaculty && matchSubject;
              }).toList();

          _modelAssessments =
              models.where((asm) {
                final matchFaculty = asm.facultyId == widget.employeeId;
                final matchSubject =
                    currentCode == null || asm.subject?.code == currentCode;
                return matchFaculty && matchSubject;
              }).toList();

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection Error: $e\n(Check database/network logs)';
          _loading = false;
        });
      }
    }
  }

  Future<void> _seedDatabaseSample() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch dynamic faculty subject assignments
      final response = await http
          .get(
            Uri.parse(
              "${ApiConstants.baseUrl}/api/faculty-subjects/teacher/${widget.employeeId}",
            ),
          )
          .timeout(const Duration(seconds: 15));

      List<dynamic> teacherAsns = [];
      if (response.statusCode == 200) {
        teacherAsns = jsonDecode(response.body);
      }

      // Filter assignment matching current selections
      final matchingAsn = teacherAsns.firstWhere(
        (asn) =>
            asn["department"].toString().trim().toLowerCase() ==
                _selectedDept.trim().toLowerCase() &&
            asn["semester"].toString().trim().toLowerCase() ==
                _selectedSemester.trim().toLowerCase() &&
            asn["section"].toString().trim().toLowerCase() ==
                _selectedSection.trim().toLowerCase(),
        orElse: () => null,
      );

      int subjectId = 1;
      String subjectCode = "CS8701";
      String subjectName = "Computer Networks";

      if (matchingAsn != null) {
        subjectId = matchingAsn["subjectId"];
        subjectCode = matchingAsn["subjectCode"];
        subjectName = matchingAsn["subjectName"];
      } else {
        // Fallback or alert if no assignment matching the selected class is found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No subject assigned to you for $_selectedDept Sem $_selectedSemester Section $_selectedSection in the admin panel. Seeding default mock subject.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // 2. Seed Class Subject assessments for logged in teacher (2 IATs, Daily Tests should be added via Conduct Test)
      for (int j = 1; j <= 2; j++) {
        await _api
            .createAssessment({
              "type": "IAT",
              "name": "IAT $j",
              "academicYear": "2025-26",
              "department": _selectedDept,
              "year": 4,
              "semester": _selectedSemester,
              "section": _selectedSection,
              "facultyId": widget.employeeId,
              "date": "2026-09-${10 + j * 5}",
              "maxMarks": 80.0,
              "status": "DRAFT",
              "subject": {
                "id": subjectId,
                "code": subjectCode,
                "name": subjectName,
                "faculty": _teacherProfile?.name ?? "Faculty Member",
              },
            })
            .timeout(const Duration(seconds: 15));
      }

      // 3. Seed Class Subject assessments for another teacher (FAC002: Eshwar Sir) (2 IATs, Daily Tests should be added via Conduct Test)

      for (int j = 1; j <= 2; j++) {
        await _api
            .createAssessment({
              "type": "IAT",
              "name": "IAT $j",
              "academicYear": "2025-26",
              "department": _selectedDept,
              "year": 4,
              "semester": _selectedSemester,
              "section": _selectedSection,
              "facultyId": "FAC002",
              "date": "2026-09-${10 + j * 5}",
              "maxMarks": 80.0,
              "status": "DRAFT",
              "subject": {
                "id": 2,
                "code": "CS8702",
                "name": "Web Technologies",
                "faculty": "Eshwar Sir",
              },
            })
            .timeout(const Duration(seconds: 15));
      }

      _loadAssessments();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error seeding database records over the network: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _showAddTestDialog() async {
    // 1. Get the current selected assignment details
    final currentAsn = _assignments.firstWhere(
      (asn) =>
          asn["department"] == _selectedDept &&
          asn["semester"] == _selectedSemester &&
          asn["section"] == _selectedSection,
      orElse: () => null,
    );

    if (currentAsn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No subject assignment selected."),
          backgroundColor: TeacherColors.danger,
        ),
      );
      return;
    }

    final subjectId = currentAsn["subjectId"];
    final subjectCode = currentAsn["subjectCode"];
    final subjectName = currentAsn["subjectName"];

    final isModel = _activeSubTab == 2;
    // Filter available options
    final existingNames =
        (isModel ? _modelAssessments : _weeklyAssessments)
            .map((a) => a.name.trim())
            .toList();
    List<String> options = [];
    if (isModel) {
      for (int i = 1; i <= 2; i++) {
        if (!existingNames.contains('Model Exam $i')) {
          options.add('Model Exam $i');
        }
      }
    } else {
      for (int i = 1; i <= 6; i++) {
        if (!existingNames.contains('Daily Test $i')) {
          options.add('Daily Test $i');
        }
      }
    }

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isModel
                ? "All eligible Model Exam options (Model Exam 1 to 2) have already been conducted/added."
                : "All eligible test options (Daily Test 1 to 6) have already been conducted/added.",
          ),
          backgroundColor: TeacherColors.warning,
        ),
      );
      return;
    }

    String selectedTestName = options.first;
    DateTime selectedDate = DateTime.now();

    // Format helper
    String getFormattedDate(DateTime dt) {
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }

    final dateController = TextEditingController(
      text: getFormattedDate(selectedDate),
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: TeacherColors.parchment,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_task, color: ErpColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Conduct Daily Test',
                    style: TextStyle(
                      color: ErpColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subject Details (ReadOnly)
                      const Text(
                        "Subject Code",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TeacherColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: TeacherColors.divider),
                        ),
                        child: Text(
                          subjectCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TeacherColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Subject Name",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TeacherColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: TeacherColors.divider),
                        ),
                        child: Text(
                          subjectName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TeacherColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Test Name Select (Dropdown)
                      const Text(
                        "Test Name",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TeacherColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: ErpColors.textPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: TeacherColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTestName,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: TeacherColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            items:
                                options.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt,
                                    child: Text(opt),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedTestName = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date selector
                      const Text(
                        "Date Conducted",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TeacherColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: "YYYY-MM-DD",
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: ErpColors.accent,
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogCtx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                  dateController.text = getFormattedDate(
                                    picked,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: TeacherColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ErpColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      setState(() => _loading = true);
                      try {
                        await _api.createAssessment({
                          "type": isModel ? "MODEL" : "WEEKLY",
                          "name": selectedTestName,
                          "academicYear": "2025-26",
                          "department": _selectedDept,
                          "year": 4,
                          "semester": _selectedSemester,
                          "section": _selectedSection,
                          "facultyId": widget.employeeId,
                          "date": dateController.text,
                          "maxMarks": isModel ? 100.0 : 20.0,
                          "status": "DRAFT",
                          "subject": {
                            "id": subjectId,
                            "code": subjectCode,
                            "name": subjectName,
                            "faculty":
                                _teacherProfile?.name ?? "Faculty Member",
                          },
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "$selectedTestName added successfully!",
                              ),
                              backgroundColor: TeacherColors.success,
                            ),
                          );
                        }
                        _loadAssessments();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to add test: $e"),
                              backgroundColor: TeacherColors.danger,
                            ),
                          );
                        }
                        if (mounted) {
                          setState(() => _loading = false);
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Save Test',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = ErpColors.bgCard;
    Color fg = Colors.white;
    if (status == 'DRAFT') {
      bg = const Color(0xFF1A1A2E);
      fg = ErpColors.textMuted;
    } else if (status == 'SUBMITTED') {
      bg = ErpColors.primary.withOpacity(0.12);
      fg = ErpColors.primary;
    } else if (status.contains('VERIFIED')) {
      bg = ErpColors.primary.withOpacity(0.25);
      fg = ErpColors.primary;
    } else if (status.contains('APPROVED') || status == 'PUBLISHED') {
      bg = TeacherColors.success.withOpacity(0.12);
      fg = TeacherColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.outfit(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWeeklyTab(double screenWidth) {
    if (_weeklyAssessments.isEmpty) {
      return _buildNoDataPlaceholder();
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 16,
      ),
      itemCount: _weeklyAssessments.length,
      itemBuilder: (context, idx) {
        final asm = _weeklyAssessments[idx];
        final component =
            asm.components.isNotEmpty ? asm.components.first : null;
        final isLocked =
            asm.status != 'DRAFT'; // Faculty cannot modify once submitted

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: ErpColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.border, width: 0.5),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            iconColor: ErpColors.textSecondary,
            collapsedIconColor: ErpColors.textSecondary,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    asm.name,
                    style: GoogleFonts.outfit(
                      fontSize: screenWidth < 360 ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: ErpColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(asm.status),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Subject: ${asm.subject?.name ?? 'Assigned Course'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: ErpColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            children: [
              const Divider(color: ErpColors.border),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Class: ${asm.semester} Sem - ${asm.section}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Max Marks: ${asm.maxMarks}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Date Conducted: ${asm.date}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: ErpColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ErpColors.primary,
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    isLocked
                        ? null
                        : () async {
                          if (component == null) return;
                          final results = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => MarkEntryScreen(
                                    assessment: asm,
                                    component: component,
                                    employeeId: widget.employeeId,
                                  ),
                            ),
                          );
                          if (results == true) {
                            _loadAssessments();
                          }
                        },
                icon: Icon(
                  component?.isEntered == true
                      ? Icons.check_circle
                      : Icons.edit_note,
                  size: 16,
                ),
                label: Text(
                  isLocked
                      ? 'Submitted'
                      : (component?.isEntered == true
                          ? 'Saved - Edit Marks'
                          : 'Enter Marks'),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelTab(double screenWidth) {
    if (_modelAssessments.isEmpty) {
      return _buildNoDataPlaceholder();
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 16,
      ),
      itemCount: _modelAssessments.length,
      itemBuilder: (context, idx) {
        final asm = _modelAssessments[idx];
        final component =
            asm.components.isNotEmpty ? asm.components.first : null;
        final isLocked =
            asm.status != 'DRAFT'; // Faculty cannot modify once submitted

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: ErpColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.border, width: 0.5),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            iconColor: ErpColors.textSecondary,
            collapsedIconColor: ErpColors.textSecondary,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    asm.name,
                    style: GoogleFonts.outfit(
                      fontSize: screenWidth < 360 ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: ErpColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(asm.status),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Subject: ${asm.subject?.name ?? 'Assigned Course'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: ErpColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            children: [
              const Divider(color: ErpColors.border),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Class: ${asm.semester} Sem - ${asm.section}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Max Marks: ${asm.maxMarks}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Date Conducted: ${asm.date}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: ErpColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ErpColors.primary,
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    isLocked
                        ? null
                        : () async {
                          if (component == null) return;
                          final results = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => MarkEntryScreen(
                                    assessment: asm,
                                    component: component,
                                    employeeId: widget.employeeId,
                                  ),
                            ),
                          );
                          if (results == true) {
                            _loadAssessments();
                          }
                        },
                icon: Icon(
                  component?.isEntered == true
                      ? Icons.check_circle
                      : Icons.edit_note,
                  size: 16,
                ),
                label: Text(
                  isLocked
                      ? 'Submitted'
                      : (component?.isEntered == true
                          ? 'Saved - Edit Marks'
                          : 'Enter Marks'),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIatTab(double screenWidth) {
    if (_iatAssessments.isEmpty) {
      return _buildNoDataPlaceholder();
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 16,
      ),
      itemCount: _iatAssessments.length,
      itemBuilder: (context, idx) {
        final asm = _iatAssessments[idx];
        final isLocked =
            asm.status != 'DRAFT'; // Faculty cannot modify once submitted

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: ErpColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asm.name,
                            style: GoogleFonts.outfit(
                              fontSize: screenWidth < 360 ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: ErpColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Subject: ${asm.subject?.name ?? 'CS8791 - Cloud Computing'}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: ErpColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(asm.status),
                  ],
                ),
              ),
              const Divider(height: 1, color: ErpColors.border),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: asm.components.length,
                itemBuilder: (context, compIdx) {
                  final comp = asm.components[compIdx];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    title: Text(
                      comp.componentType,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Max Marks: ${comp.maxMarks}  •  Weight: ${(comp.weightage * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: ErpColors.textSecondary,
                      ),
                    ),
                    trailing:
                        isLocked
                            ? const Chip(
                              backgroundColor: Color(0xFF252540),
                              side: BorderSide.none,
                              label: Text(
                                'Submitted',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ErpColors.textSecondary,
                                ),
                              ),
                            )
                            : SizedBox(
                              height: 32,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor:
                                      comp.isEntered
                                          ? TeacherColors.success
                                          : ErpColors.primary,
                                ),
                                onPressed: () async {
                                  final results = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => MarkEntryScreen(
                                            assessment: asm,
                                            component: comp,
                                            employeeId: widget.employeeId,
                                          ),
                                    ),
                                  );
                                  if (results == true) {
                                    _loadAssessments();
                                  }
                                },
                                icon: Icon(
                                  comp.isEntered
                                      ? Icons.check_circle
                                      : Icons.edit,
                                  size: 14,
                                ),
                                label: Text(
                                  comp.isEntered ? 'Saved - Edit' : 'Enter',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                  );
                },
              ),
              if (asm.status == 'DRAFT') ...[
                const Divider(height: 1, color: ErpColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ErpColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              backgroundColor: ErpColors.bgCard,
                              title: Text(
                                "Submit ${asm.name} Officially?",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: ErpColors.textPrimary,
                                ),
                              ),
                              content: const Text(
                                "Are you sure you want to submit all components (Written, Assignment, Seminar, Quiz) for this IAT? Once submitted, marks will be locked and sent to the Class Incharge/HOD.",
                                style: TextStyle(
                                  color: ErpColors.textSecondary,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: ErpColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ErpColors.primary,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Submit Officially",
                                    style: TextStyle(
                                      color: ErpColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        try {
                          await _api.submitAssessment(
                            assessmentId: asm.id,
                            facultyId: widget.employeeId,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${asm.name} marks submitted successfully!",
                              ),
                              backgroundColor: TeacherColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error submitting IAT: $e"),
                              backgroundColor: TeacherColors.danger,
                            ),
                          );
                        }
                        _loadAssessments();
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: Text(
                      "Submit ${asm.name} Officially",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 54,
              color: ErpColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No Evaluation Entries Found',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: ErpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dynamic evaluations configuration seeding is required for your courses.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: ErpColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ErpColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _seedDatabaseSample,
              child: Text(
                'Initialize & Seed My Subjects',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isClassInchargeOfSelectedClass(
    String employeeId,
    String dept,
    String sem,
    String sec,
  ) {
    final designationVal = _teacherProfile?.designation.toUpperCase() ?? '';
    final isHodOrDean =
        designationVal.contains('HOD') ||
        designationVal.contains('DEAN') ||
        employeeId.toUpperCase().contains('HOD') ||
        employeeId.toUpperCase().contains('DEAN') ||
        employeeId == 'HOD001' ||
        employeeId == 'DEAN001';
    if (isHodOrDean) return true;

    final empUpper = employeeId.toUpperCase();
    final deptUpper = dept.toUpperCase();
    final semUpper = sem.toUpperCase();
    final secUpper = sec.toUpperCase();

    // Dynamically search loaded assessments for the selected class to see if we have CS8701
    // (Computer Networks) and extract its subject's employeeId.
    String? resolvedInchargeEmpId;
    for (var asm in _allAssessments) {
      if (asm.department.toUpperCase() == deptUpper &&
          asm.semester.toUpperCase() == semUpper &&
          asm.section.toUpperCase() == secUpper) {
        final sub = asm.subject;
        if (sub != null &&
            (sub.code.toUpperCase() == 'CS8701' ||
                sub.name.toLowerCase().contains('network'))) {
          resolvedInchargeEmpId = sub.employeeId;
          break;
        }
      }
    }

    if (resolvedInchargeEmpId != null && resolvedInchargeEmpId.isNotEmpty) {
      return empUpper == resolvedInchargeEmpId.toUpperCase();
    }

    // Specific rule: CSE, VII, A and B belongs to EMP006 / EMPLOYEE006 (fallback)
    if (deptUpper == 'CSE' &&
        (semUpper == 'VII' || semUpper == 'VIII') &&
        (secUpper == 'A' || secUpper == 'B')) {
      return empUpper == 'EMP006' ||
          empUpper == 'EMPLOYEE006' ||
          empUpper == 'FAC001';
    }

    // Default fallbacks to allow testing other classes for typical faculty IDs
    return empUpper == 'FAC001' ||
        empUpper == 'EMP001' ||
        empUpper == 'EMP006' ||
        empUpper == 'EMPLOYEE006';
  }

  Widget _buildRestrictedPortalView(String roleName, String requiredEntity) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ErpColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ErpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your account does not have $roleName authorization for the selected class:\n$requiredEntity.\n\nOnly the assigned Class Incharge, HOD, or Dean is authorized to audit and consolidate marks.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: ErpColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelectorCard() {
    if (_assignments.isEmpty) {
      return const SizedBox.shrink();
    }

    final String valKey =
        "${_selectedDept}_${_selectedSemester}_${_selectedSection}";

    // Check if current class values exist in the loaded assignments list
    bool exists = _assignments.any(
      (asn) =>
          asn["department"] == _selectedDept &&
          asn["semester"] == _selectedSemester &&
          asn["section"] == _selectedSection,
    );

    final String selectedVal =
        exists
            ? valKey
            : "${_assignments.first["department"]}_${_assignments.first["semester"]}_${_assignments.first["section"]}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: ErpColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_outlined,
                color: ErpColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Active Course Assignment',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ErpColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: ErpColors.bgWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ErpColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedVal,
                isExpanded: true,
                dropdownColor: ErpColors.bgWhite,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: ErpColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                items:
                    _assignments.map((asn) {
                      final dept = asn["department"] ?? "";
                      final sem = asn["semester"] ?? "";
                      final sec = asn["section"] ?? "";
                      final code = asn["subjectCode"] ?? "";
                      final name = asn["subjectName"] ?? "";
                      return DropdownMenuItem<String>(
                        value: "${dept}_${sem}_${sec}",
                        child: Text(
                          "$dept • Sem $sem • Sec $sec ($code: $name)",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final parts = val.split("_");
                    setState(() {
                      _selectedDept = parts[0];
                      _selectedSemester = parts[1];
                      _selectedSection = parts[2];
                    });
                    _loadAssessments();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInchargeChecklist() {
    if (_allAssessments.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ErpColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ErpColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF6C63FF),
                size: 36,
              ),
              const SizedBox(height: 10),
              const Text(
                'No subjects or test records are registered for this class section yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ErpColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _seedDatabaseSample,
                child: const Text(
                  'Seed Sample Class Data',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<AssessmentModel>> subjectsGrouped = {};
    for (var asm in _allAssessments) {
      final code = asm.subject?.code ?? 'SUBJECT';
      if (!subjectsGrouped.containsKey(code)) {
        subjectsGrouped[code] = [];
      }
      subjectsGrouped[code]!.add(asm);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Class Subjects Checklist (${subjectsGrouped.keys.length} Registered)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ErpColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_selectedDept - Sem $_selectedSemester - $_selectedSection',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: ErpColors.primary,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: subjectsGrouped.keys.length,
          itemBuilder: (context, idx) {
            final code = subjectsGrouped.keys.elementAt(idx);
            final asms = subjectsGrouped[code]!;
            final firstAsm = asms.first;
            final subjectName = firstAsm.subject?.name ?? firstAsm.name;
            final facultyName = firstAsm.subject?.faculty ?? 'Faculty';

            final weeklyTests =
                asms.where((a) => a.type.toUpperCase() == 'WEEKLY').toList();
            final iats =
                asms.where((a) => a.type.toUpperCase() == 'IAT').toList();

            final weeklySubmitted =
                weeklyTests
                    .where((a) => a.status.toUpperCase() != 'DRAFT')
                    .length;
            final iatsSubmitted =
                iats.where((a) => a.status.toUpperCase() != 'DRAFT').length;

            final isAllDone = weeklySubmitted >= 6 && iatsSubmitted >= 2;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ErpColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ErpColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subjectName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: ErpColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Instructor: $facultyName',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ErpColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Daily Test: $weeklySubmitted/6 submitted',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    weeklySubmitted >= 6
                                        ? Colors.greenAccent
                                        : ErpColors.textMuted,
                              ),
                            ),
                            Text(
                              'IAT: $iatsSubmitted/2 submitted',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    iatsSubmitted >= 2
                                        ? Colors.greenAccent
                                        : ErpColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Icon(
                        isAllDone ? Icons.check_circle : Icons.pending_actions,
                        color:
                            isAllDone
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAllDone ? 'READY' : 'PENDING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color:
                              isAllDone
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHodPortalTab() {
    final bool isInchargeSignedOff =
        _allAssessments.isNotEmpty &&
        _allAssessments.every(
          (a) =>
              a.status == 'CLASS_INCHARGE_VERIFIED' ||
              a.status == 'HOD_VERIFIED' ||
              a.status == 'DEAN_APPROVED',
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildClassSelectorCard(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ErpColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ErpColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.thumbs_up_down,
                    color: Color(0xFF6C63FF),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_selectedDept Dept. HOD Approvals board',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Audit consolidated evaluations signed off by class advisors before sending them to the Dean office.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: ErpColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const Divider(height: 24, color: ErpColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advisor Sign-off status:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isInchargeSignedOff
                                  ? Colors.greenAccent.withOpacity(0.08)
                                  : Colors.orangeAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isInchargeSignedOff
                              ? 'VERIFIED BY INCHARGE'
                              : 'PENDING ADVISOR SIGN-OFF',
                          style: TextStyle(
                            color:
                                isInchargeSignedOff
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => HodVerificationScreen(
                                  department: _selectedDept,
                                  semester: _selectedSemester,
                                  section: _selectedSection,
                                ),
                          ),
                        ).then((_) => _loadAssessments());
                      },
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text(
                        'Open HOD Approvals board',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeanPortalTab() {
    final bool isHodApproved =
        _allAssessments.isNotEmpty &&
        _allAssessments.every(
          (a) => a.status == 'HOD_VERIFIED' || a.status == 'DEAN_APPROVED',
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildClassSelectorCard(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ErpColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ErpColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.security,
                    color: Colors.greenAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dean Official Locking Console',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure and commit reviewed internal marks registries to the permanent archives.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: ErpColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const Divider(height: 24, color: ErpColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HOD Sign-off status:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isHodApproved
                                  ? Colors.greenAccent.withOpacity(0.08)
                                  : Colors.orangeAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isHodApproved
                              ? 'APPROVED BY HOD'
                              : 'PENDING HOD AUDIT',
                          style: TextStyle(
                            color:
                                isHodApproved
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DeanSubmissionScreen(
                                  department: _selectedDept,
                                  semester: _selectedSemester,
                                  section: _selectedSection,
                                ),
                          ),
                        ).then((_) => _loadAssessments());
                      },
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text(
                        'Open Dean Official Lock Panel',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    // Check teacher administrative profile clearances
    final designationVal = _teacherProfile?.designation.toUpperCase() ?? '';

    final showInchargePortal = _isClassInchargeOfSelectedClass(
      widget.employeeId,
      _selectedDept,
      _selectedSemester,
      _selectedSection,
    );

    final isHod =
        designationVal.contains('HOD') ||
        widget.employeeId.toUpperCase().contains('HOD') ||
        widget.employeeId == 'HOD001';
    final isDean =
        designationVal.contains('DEAN') ||
        widget.employeeId.toUpperCase().contains('DEAN') ||
        widget.employeeId == 'DEAN001';

    final tabs = [
      const Tab(text: 'Subject Entry', icon: Icon(Icons.assignment, size: 16)),
      const Tab(
        text: 'Class Incharge Portal',
        icon: Icon(Icons.admin_panel_settings, size: 16),
      ),
      if (isHod)
        const Tab(
          text: 'HOD Portal',
          icon: Icon(Icons.thumbs_up_down, size: 16),
        ),
      if (isDean)
        const Tab(text: 'Dean Portal', icon: Icon(Icons.lock, size: 16)),
    ];

    return DefaultTabController(
      key: ValueKey('${isHod}_${isDean}'),
      length: tabs.length,
      child: Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: AppBar(
          backgroundColor: ErpColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'Test Entry & Assessments',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _loadAssessments,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
          bottom: TabBar(
            isScrollable: tabs.length > 2,
            labelColor: ErpColors.accent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: ErpColors.accent,
            labelStyle: ErpTypography.labelLarge,
            unselectedLabelStyle: ErpTypography.labelLarge,
            tabs: tabs,
          ),
        ),
        body: SafeArea(
          child:
              _loading
                  ? const _TestEntrySkeleton()
                  : _error == "ACCESS_RESTRICTED"
                  ? _buildRestrictedAccessScreen()
                  : _error.isNotEmpty
                  ? _buildErrorScreen()
                  : TabBarView(
                    children: [
                      // Tab 1: Subject Entry Taught By Faculty
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildClassSelectorCard(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setState(() => _activeSubTab = 0),
                                    child: Container(
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            _activeSubTab == 0
                                                ? ErpColors.primary
                                                : ErpColors.bgWhite,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _activeSubTab == 0
                                                  ? ErpColors.primary
                                                  : ErpColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        'Daily Tests',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _activeSubTab == 0
                                                  ? Colors.white
                                                  : ErpColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setState(() => _activeSubTab = 1),
                                    child: Container(
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            _activeSubTab == 1
                                                ? ErpColors.primary
                                                : ErpColors.bgCard,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _activeSubTab == 1
                                                  ? ErpColors.primary
                                                  : ErpColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        'IAT Evaluation',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _activeSubTab == 1
                                                  ? Colors.white
                                                  : ErpColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setState(() => _activeSubTab = 2),
                                    child: Container(
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            _activeSubTab == 2
                                                ? ErpColors.primary
                                                : ErpColors.bgCard,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _activeSubTab == 2
                                                  ? ErpColors.primary
                                                  : ErpColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        'Model Exams',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _activeSubTab == 2
                                                  ? Colors.white
                                                  : ErpColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_activeSubTab == 0 || _activeSubTab == 2)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _activeSubTab == 0
                                        ? "Daily Test Conduct & Entry"
                                        : "Model Exam Conduct & Entry",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ErpColors.primary,
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: ErpColors.accent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      backgroundColor: ErpColors.accent
                                          .withOpacity(0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _showAddTestDialog,
                                    icon: const Icon(Icons.add, size: 14),
                                    label: Text(
                                      _activeSubTab == 0
                                          ? "Conduct Test"
                                          : "Conduct Model",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child:
                                _activeSubTab == 0
                                    ? _buildWeeklyTab(width)
                                    : _activeSubTab == 1
                                    ? _buildIatTab(width)
                                    : _buildModelTab(width),
                          ),
                        ],
                      ),

                      // Tab 2: Class Incharge Portal
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildClassSelectorCard(),
                            const SizedBox(height: 6),
                            if (!showInchargePortal)
                              _buildRestrictedPortalView(
                                'Class Incharge',
                                '$_selectedDept - Sem $_selectedSemester - Sec $_selectedSection',
                              )
                            else ...[
                              _buildClassInchargeChecklist(),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: ErpColors.bgCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: ErpColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.dashboard_customize_outlined,
                                            size: 14,
                                            color: ErpColors.textPrimary,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Consolidated Roster Audit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: ErpColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Consolidated review compiles all marks into a dynamic student grid spreadsheet format.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ErpColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        InchargeDashboardScreen(
                                                          department:
                                                              _selectedDept,
                                                          semester:
                                                              _selectedSemester,
                                                          section:
                                                              _selectedSection,
                                                        ),
                                              ),
                                            ).then((_) => _loadAssessments());
                                          },
                                          icon: const Icon(
                                            Icons.analytics_outlined,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Open Consolidation & Audit Board',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                TeacherColors.danger,
                                            side: const BorderSide(
                                              color: TeacherColors.danger,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (ctx) => AlertDialog(
                                                    title: const Text(
                                                      "Reset All Class Data?",
                                                    ),
                                                    content: const Text(
                                                      "This will permanently delete ALL submitted assessments, daily tests, and marks for this class/section. This action CANNOT be undone. Are you sure you want to proceed and start fresh?",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  TeacherColors
                                                                      .danger,
                                                            ),
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              ctx,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          "Delete Everything",
                                                          style: TextStyle(
                                                            color:
                                                                ErpColors
                                                                    .textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (confirm == true) {
                                              setState(() {
                                                _loading = true;
                                              });
                                              try {
                                                final success = await _api
                                                    .clearClassAssessments(
                                                      department: _selectedDept,
                                                      semester:
                                                          _selectedSemester,
                                                      section: _selectedSection,
                                                    );
                                                if (!mounted) return;
                                                if (success) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "All class assessments cleared successfully.",
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Error clearing assessments: $e",
                                                    ),
                                                  ),
                                                );
                                              }
                                              _loadAssessments();
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_forever_outlined,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Reset & Clear All Class Assessments',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Tab 3: HOD
                      if (isHod) _buildHodPortalTab(),

                      // Tab 4: Dean
                      if (isDean) _buildDeanPortalTab(),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildRestrictedAccessScreen() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: TeacherColors.divider),
        ),
        color: ErpColors.textPrimary,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gpp_bad_outlined,
                color: TeacherColors.danger,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Access Restricted",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ErpColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You have not been assigned to any subjects or sections for the current academic session. Please contact the administrator to set up your teaching assignments.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: TeacherColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _hasFetchedAssignments = false; // Reset to force refetch
                  _loadAssessments();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  "Retry Connection",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: TeacherColors.danger,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadAssessments,
              child: const Text(
                'Retry Connection',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
