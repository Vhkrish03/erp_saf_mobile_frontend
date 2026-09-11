import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../models/exam_cell_model.dart';
import '../services/exam_cell_service.dart';
import '../services/exam_admin_service.dart';

class BulkStudentRosterScreen extends StatefulWidget {
  final String department;
  final String academicYear;
  final String year;
  final String semester;
  final String examSession;
  final String performedBy;
  final String role;

  const BulkStudentRosterScreen({
    super.key,
    required this.department,
    required this.academicYear,
    required this.year,
    required this.semester,
    required this.examSession,
    required this.performedBy,
    required this.role,
  });

  @override
  State<BulkStudentRosterScreen> createState() =>
      _BulkStudentRosterScreenState();
}

class _RosterSkeleton extends StatelessWidget {
  const _RosterSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _BulkStudentRosterScreenState extends State<BulkStudentRosterScreen> {
  final ExamCellService _service = ExamCellService();
  final ExamAdminService _adminService = ExamAdminService();

  List<Map<String, dynamic>> _fetchedStudents = [];
  bool _isFetchingStudents = false;
  bool _isSaving = false;
  String? _bulkError;

  // Grade -> grade point mapping (Anna University scale)
  static const Map<String, double> _gradePoints = {
    'O': 10.0,
    'A+': 9.0,
    'A': 8.0,
    'B+': 7.0,
    'B': 6.0,
    'C': 5.0,
    'U': 0.0,
    'RA': 0.0,
    'UA': 0.0,
    'W': 0.0,
  };

  String getGradeFromMarks(double marks) {
    if (marks >= 90) return 'O';
    if (marks >= 80) return 'A+';
    if (marks >= 70) return 'A';
    if (marks >= 60) return 'B+';
    if (marks >= 50) return 'B';
    return 'U';
  }

  @override
  void initState() {
    super.initState();
    _fetchStudentsForBulk();
  }

  Future<void> _fetchStudentsForBulk() async {
    setState(() {
      _isFetchingStudents = true;
      _bulkError = null;
      _fetchedStudents.clear();
    });

    try {
      List<Map<String, dynamic>> defaultSubjects = [];
      try {
        defaultSubjects = await _adminService.fetchSubjectsForClass(
          department: widget.department,
          semester: widget.semester,
        );
      } catch (e) {
        debugPrint("Failed to fetch default subjects: $e");
      }

      final studentsList = await _service.getClassResultSummary(
        department: widget.department,
        semester: widget.semester,
        academicYear: widget.academicYear,
        year: widget.year,
      );

      List<Map<String, dynamic>> resolved = [];
      for (var s in studentsList) {
        final id = s['studentId'] as String;
        final name = s['studentName'] as String? ?? 'Student';
        final roll = s['rollNumber'] as String? ?? '';
        final resId = s['resultId'] as int?;

        List<Map<String, dynamic>> studentSubjects = [];

        if (resId != null) {
          try {
            final detail = await _service.getResultById(resId);
            for (var subDetail in detail.subjects) {
              studentSubjects.add({
                'codeCtrl': TextEditingController(text: subDetail.subjectCode),
                'nameCtrl': TextEditingController(text: subDetail.subjectName),
                'creditsCtrl': TextEditingController(
                  text: subDetail.credits.toString(),
                ),
                'marksCtrl': TextEditingController(
                  text: subDetail.marksObtained?.toString() ?? '',
                ),
                'attemptCtrl': TextEditingController(
                  text: subDetail.attemptNumber?.toString() ?? '1',
                ),
                'grade': subDetail.grade ?? 'U',
                'resultStatus': subDetail.resultStatus ?? 'FAIL',
              });
            }
          } catch (e) {
            debugPrint("Failed to fetch result detail: $e");
          }
        }

        if (studentSubjects.isEmpty) {
          for (var defSub in defaultSubjects) {
            studentSubjects.add({
              'codeCtrl': TextEditingController(text: defSub['code'] ?? ''),
              'nameCtrl': TextEditingController(text: defSub['name'] ?? ''),
              'creditsCtrl': TextEditingController(
                text: (defSub['credits'] ?? 3).toString(),
              ),
              'marksCtrl': TextEditingController(text: ''),
              'attemptCtrl': TextEditingController(text: '1'),
              'grade': 'U',
              'resultStatus': 'FAIL',
            });
          }
        }

        resolved.add({
          'studentId': id,
          'studentName': name,
          'rollNumber': roll,
          'resultId': resId,
          'subjects': studentSubjects,
        });
      }

      setState(() {
        _fetchedStudents = resolved;
        _isFetchingStudents = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _bulkError = "Failed to fetch student roster: $e";
          _isFetchingStudents = false;
        });
      }
    }
  }

  double _calcStudentSgpa(List<Map<String, dynamic>> subjects) {
    double totalCredits = 0;
    double weightedSum = 0;
    for (var sub in subjects) {
      final credits =
          double.tryParse(
            (sub['creditsCtrl'] as TextEditingController).text.trim(),
          ) ??
          0.0;
      final grade = sub['grade'] as String? ?? 'U';
      final gp = _gradePoints[grade] ?? 0.0;
      totalCredits += credits;
      weightedSum += gp * credits;
    }
    return totalCredits > 0 ? weightedSum / totalCredits : 0.0;
  }

  bool get _isPublishEnabled {
    if (_fetchedStudents.isEmpty) return false;
    for (var s in _fetchedStudents) {
      final list = s['subjects'] as List<Map<String, dynamic>>;
      if (list.isEmpty) return false;
      int filled = 0;
      for (var sub in list) {
        final ctrl = sub['marksCtrl'] as TextEditingController;
        if (ctrl.text.trim().isNotEmpty) {
          filled++;
        }
      }
      if (filled != list.length) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveBulk() async {
    if (_fetchedStudents.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      List<ExamCellResultModel> resultsToSave = [];

      for (var s in _fetchedStudents) {
        final studentId = s['studentId'] as String;
        final studentName = s['studentName'] as String;
        final rollNo = s['rollNumber'] as String;
        final existingId = s['resultId'] as int?;
        final subjectsList = s['subjects'] as List<Map<String, dynamic>>;

        final sgpa = _calcStudentSgpa(subjectsList);

        List<ExamCellSubjectModel> subjects = [];
        for (var sub in subjectsList) {
          final subCode =
              (sub['codeCtrl'] as TextEditingController).text.trim();
          final subName =
              (sub['nameCtrl'] as TextEditingController).text.trim();
          final credits =
              int.tryParse(
                (sub['creditsCtrl'] as TextEditingController).text.trim(),
              ) ??
              3;
          final marksText =
              (sub['marksCtrl'] as TextEditingController).text.trim();
          final marksObt = double.tryParse(marksText);
          final grade = sub['grade'] as String? ?? 'U';
          final attempt =
              int.tryParse(
                (sub['attemptCtrl'] as TextEditingController).text.trim(),
              ) ??
              1;

          if (subCode.isEmpty) continue;

          subjects.add(
            ExamCellSubjectModel(
              subjectCode: subCode,
              subjectName: subName,
              credits: credits,
              grade: grade,
              gradePoint: _gradePoints[grade] ?? 0.0,
              resultStatus: sub['resultStatus'] ?? 'FAIL',
              marksObtained: marksObt,
              maxMarks: 100.0,
              attemptNumber: attempt,
            ),
          );
        }

        resultsToSave.add(
          ExamCellResultModel(
            id: existingId,
            studentId: studentId,
            registerNumber: rollNo,
            studentName: studentName,
            department: widget.department,
            semesterName: widget.semester,
            academicYear: widget.academicYear,
            examSession: widget.examSession,
            examination: 'End Semester Examination',
            status: 'DRAFT',
            sgpa: sgpa,
            subjects: subjects,
          ),
        );
      }

      await _service.saveResultBulk(
        results: resultsToSave,
        performedBy: widget.performedBy,
        role: widget.role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Results submitted for verification!'),
            backgroundColor: ErpColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: ErpColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showStudentMarksEntryDialog(Map<String, dynamic> student) {
    final name = student['studentName'] as String;
    final roll = student['rollNumber'] as String;
    final subjectsList = student['subjects'] as List<Map<String, dynamic>>;
    if (subjectsList.isEmpty) {
      subjectsList.add({
        'codeCtrl': TextEditingController(),
        'nameCtrl': TextEditingController(),
        'creditsCtrl': TextEditingController(text: '3'),
        'marksCtrl': TextEditingController(),
        'attemptCtrl': TextEditingController(text: '1'),
        'grade': 'U',
        'resultStatus': 'FAIL',
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double sgpaVal = _calcStudentSgpa(subjectsList);

            void updateRowCalculations(Map<String, dynamic> row) {
              final marks =
                  double.tryParse(
                    (row['marksCtrl'] as TextEditingController).text.trim(),
                  ) ??
                  0.0;
              final String valGrade = getGradeFromMarks(marks);
              row['grade'] = valGrade;
              row['resultStatus'] = valGrade == 'U' ? 'FAIL' : 'PASS';
            }

            InputDecoration getInputDecoration(String label) {
              return InputDecoration(
                labelText: label,
                labelStyle: ErpTypography.labelSmall.copyWith(
                  color: ErpColors.textMuted,
                ),
                filled: true,
                fillColor: ErpColors.bgSubtle,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: ErpRadius.input,
                  borderSide: const BorderSide(color: ErpColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: ErpRadius.input,
                  borderSide: const BorderSide(color: ErpColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: ErpRadius.input,
                  borderSide: const BorderSide(color: ErpColors.primary),
                ),
              );
            }

            return Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Color(0xFF6C63FF),
                  selectionColor: Colors.deepPurple,
                  selectionHandleColor: Color(0xFF6C63FF),
                ),
              ),
              child: AlertDialog(
                backgroundColor: ErpColors.bgWhite,
                shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
                titlePadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                title: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: ErpColors.bgSubtle,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ErpColors.infoSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: ErpColors.info,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: ErpTypography.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Roll: $roll', style: ErpTypography.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ErpColors.successSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'SGPA: ${sgpaVal.toStringAsFixed(2)}',
                          style: ErpTypography.labelSmall.copyWith(
                            color: ErpColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ErpColors.bgSubtle,
                          borderRadius: ErpRadius.cardSm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: ErpColors.textMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Grades & Status evaluate automatically as you enter marks (Pass >= 50)',
                                style: ErpTypography.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: subjectsList.length,
                          itemBuilder: (ctx, subIdx) {
                            final sub = subjectsList[subIdx];
                            final code =
                                sub['codeCtrl'] as TextEditingController;
                            final subName =
                                sub['nameCtrl'] as TextEditingController;
                            final crd =
                                sub['creditsCtrl'] as TextEditingController;
                            final marks =
                                sub['marksCtrl'] as TextEditingController;
                            final att =
                                sub['attemptCtrl'] as TextEditingController;

                            final isFail =
                                sub['resultStatus'] == 'FAIL' ||
                                sub['grade'] == 'U';
                            final currentGrade = sub['grade'] as String? ?? 'U';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ErpColors.bgWhite,
                                borderRadius: ErpRadius.cardSm,
                                border: Border.all(color: ErpColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: code,
                                          style: ErpTypography.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          decoration: getInputDecoration(
                                            'Subject Code',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: subName,
                                          style: ErpTypography.bodyLarge,
                                          decoration: getInputDecoration(
                                            'Subject Name',
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: ErpColors.danger,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            subjectsList.removeAt(subIdx);
                                            sgpaVal = _calcStudentSgpa(
                                              subjectsList,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: crd,
                                          keyboardType: TextInputType.number,
                                          style: ErpTypography.bodyLarge,
                                          decoration: getInputDecoration(
                                            'Credits',
                                          ),
                                          onChanged: (v) {
                                            setDialogState(() {
                                              sgpaVal = _calcStudentSgpa(
                                                subjectsList,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: marks,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: ErpTypography.bodyLarge
                                              .copyWith(
                                                color:
                                                    isFail
                                                        ? ErpColors.warning
                                                        : ErpColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          decoration: getInputDecoration(
                                            'Marks obtained',
                                          ),
                                          onChanged: (v) {
                                            setDialogState(() {
                                              updateRowCalculations(sub);
                                              sgpaVal = _calcStudentSgpa(
                                                subjectsList,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: att,
                                          keyboardType: TextInputType.number,
                                          style: ErpTypography.bodyLarge,
                                          decoration: getInputDecoration(
                                            'Attempt',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Grade: $currentGrade',
                                        style: ErpTypography.bodyMedium
                                            .copyWith(
                                              color:
                                                  isFail
                                                      ? ErpColors.danger
                                                      : ErpColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isFail
                                                  ? ErpColors.dangerSurface
                                                  : ErpColors.successSurface,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          sub['resultStatus'] as String? ??
                                              'FAIL',
                                          style: ErpTypography.labelSmall
                                              .copyWith(
                                                color:
                                                    isFail
                                                        ? ErpColors.danger
                                                        : ErpColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: ErpColors.info),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.add,
                                color: ErpColors.info,
                                size: 16,
                              ),
                              label: Text(
                                'Add Row',
                                style: ErpTypography.button.copyWith(
                                  color: ErpColors.info,
                                ),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  subjectsList.add({
                                    'codeCtrl': TextEditingController(),
                                    'nameCtrl': TextEditingController(),
                                    'creditsCtrl': TextEditingController(
                                      text: '3',
                                    ),
                                    'marksCtrl': TextEditingController(),
                                    'attemptCtrl': TextEditingController(
                                      text: '1',
                                    ),
                                    'grade': 'U',
                                    'resultStatus': 'FAIL',
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ErpColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Done / OK',
                                style: ErpTypography.button.copyWith(
                                  color: ErpColors.textOnPrimary,
                                ),
                              ),
                              onPressed: () {
                                int filled = 0;
                                for (var r in subjectsList) {
                                  final codeVal =
                                      (r['codeCtrl'] as TextEditingController)
                                          .text
                                          .trim();
                                  if (codeVal.isNotEmpty) filled++;
                                }
                                setState(() {
                                  student['hasBeenUpdated'] = (filled > 0);
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  Widget _buildStudentAvatar(String name, bool hasMarks) {
    final String initials =
        name
            .trim()
            .split(' ')
            .map((l) => l.isNotEmpty ? l[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color:
            hasMarks
                ? ErpColors.success.withValues(alpha: 0.12)
                : ErpColors.bgSubtle,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              hasMarks
                  ? ErpColors.success.withValues(alpha: 0.3)
                  : ErpColors.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'ST',
          style: ErpTypography.bodyMedium.copyWith(
            color: hasMarks ? ErpColors.success : ErpColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: ErpTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSgpaBadge(double sgpa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ErpColors.successSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ErpColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        "SGPA: ${sgpa.toStringAsFixed(2)}",
        style: ErpTypography.labelSmall.copyWith(
          color: ErpColors.success,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    Map<String, dynamic> student,
    bool hasMarks, {
    required bool isMobile,
  }) {
    if (!hasMarks) {
      return ElevatedButton.icon(
        onPressed: () => _showStudentMarksEntryDialog(student),
        style: ElevatedButton.styleFrom(
          backgroundColor: ErpColors.primary,
          foregroundColor: ErpColors.textOnPrimary,
          elevation: 0,
          minimumSize: const Size(80, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.add, size: 13),
        label: Text(
          'Entry',
          style: ErpTypography.button.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _showStudentMarksEntryDialog(student),
        style: OutlinedButton.styleFrom(
          foregroundColor: ErpColors.warning,
          side: const BorderSide(color: ErpColors.warning, width: 1.0),
          minimumSize: const Size(80, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.edit, size: 13),
        label: Text(
          'Edit',
          style: ErpTypography.button.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roster Result Entry',
              style: GoogleFonts.outfit(
                color: ErpColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${widget.department} · Sem ${widget.semester} · ${widget.academicYear}',
              style: ErpTypography.caption.copyWith(
                color: ErpColors.textOnPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isFetchingStudents
                    ? const _RosterSkeleton()
                    : _bulkError != null
                    ? ErpErrorState(
                      message:
                          'We could not retrieve the student roster right now.',
                      onRetry: _fetchStudentsForBulk,
                    )
                    : _fetchedStudents.isEmpty
                    ? const ErpEmptyState(
                      message: 'No student roster found',
                      subtitle:
                          'There are no students available for this result batch.',
                      icon: Icons.groups_outlined,
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _fetchedStudents.length,
                      itemBuilder: (context, sIdx) {
                        final student = _fetchedStudents[sIdx];
                        final name = student['studentName'] as String;
                        final roll = student['rollNumber'] as String;
                        final id = student['studentId'] as String;
                        final subjectsList =
                            student['subjects'] as List<Map<String, dynamic>>;

                        int filledCount = 0;
                        for (var sub in subjectsList) {
                          final ctrl =
                              sub['marksCtrl'] as TextEditingController;
                          if (ctrl.text.trim().isNotEmpty) {
                            filledCount++;
                          }
                        }

                        final bool hasMarks =
                            student['hasBeenUpdated'] == true ||
                            (student['resultId'] != null) ||
                            (filledCount > 0);

                        final Color statusColor =
                            hasMarks ? ErpColors.success : ErpColors.warning;
                        final String statusLabel =
                            hasMarks ? 'COMPLETED' : 'PENDING';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: ErpColors.bgWhite,
                            borderRadius: ErpRadius.cardSm,
                            border: Border.all(
                              color:
                                  hasMarks
                                      ? ErpColors.success.withValues(alpha: 0.2)
                                      : ErpColors.border,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap:
                                  () => _showStudentMarksEntryDialog(student),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child:
                                    isMobile
                                        ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _buildStudentAvatar(
                                                  name,
                                                  hasMarks,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: ErpTypography
                                                            .bodyLarge
                                                            .copyWith(
                                                              color:
                                                                  ErpColors
                                                                      .textPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        "Roll: $roll | ID: $id",
                                                        style: ErpTypography
                                                            .bodySmall
                                                            .copyWith(
                                                              color:
                                                                  ErpColors
                                                                      .textMuted,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _buildStatusBadge(
                                                  statusLabel,
                                                  statusColor,
                                                ),
                                                Row(
                                                  children: [
                                                    if (hasMarks) ...[
                                                      _buildSgpaBadge(
                                                        _calcStudentSgpa(
                                                          subjectsList,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    _buildActionButton(
                                                      student,
                                                      hasMarks,
                                                      isMobile: true,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                        : Row(
                                          children: [
                                            _buildStudentAvatar(name, hasMarks),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.outfit(
                                                      color:
                                                          ErpColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Roll Number: $roll   |   Student ID: $id",
                                                    style: GoogleFonts.outfit(
                                                      color:
                                                          ErpColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildStatusBadge(
                                              statusLabel,
                                              statusColor,
                                            ),
                                            const SizedBox(width: 16),
                                            if (hasMarks) ...[
                                              _buildSgpaBadge(
                                                _calcStudentSgpa(subjectsList),
                                              ),
                                              const SizedBox(width: 16),
                                            ],
                                            _buildActionButton(
                                              student,
                                              hasMarks,
                                              isMobile: false,
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (_fetchedStudents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ErpColors.bgWhite,
                border: Border(top: BorderSide(color: ErpColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isPublishEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orangeAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Publish disabled: Ensure all students have marks entered for all subjects.',
                              style: GoogleFonts.outfit(
                                color: Colors.orangeAccent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isPublishEnabled
                                ? ErpColors.primary
                                : ErpColors.border,
                        foregroundColor:
                            _isPublishEnabled
                                ? ErpColors.textOnPrimary
                                : ErpColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:
                          (_isSaving || !_isPublishEnabled)
                              ? null
                              : () => _saveBulk(),
                      icon:
                          _isSaving
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ErpColors.textOnPrimary,
                                ),
                              )
                              : const Icon(Icons.verified),
                      label: Text(
                        'Submit for Verification',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
