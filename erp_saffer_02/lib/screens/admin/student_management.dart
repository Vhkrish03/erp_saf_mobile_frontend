import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../models/student.dart';
import '../../services/admin_api_service.dart';

class StudentManagementScreen extends StatefulWidget {
  final String? lockedDepartment;
  final String? lockedYear;
  final String? lockedSection;

  const StudentManagementScreen({
    Key? key,
    this.lockedDepartment,
    this.lockedYear,
    this.lockedSection,
  }) : super(key: key);

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  Set<String> _selectedStudentIds = {};

  bool _isProcessingBatch = false;
  int _batchTotal = 0;
  int _batchCurrent = 0;
  String _batchTitle = 'Processing...';
  String _batchSubtitle = 'processed';

  String _selectedDept = "ALL";
  String _selectedYear = "ALL";
  String _selectedSection = "ALL";

  String _normalizeDept(String dept) {
    String d = dept.toLowerCase().trim();
    if (d.contains('computer') || d == 'cs' || d == 'cse') return 'CSE';
    if (d.contains('electronics') || d.contains('communication') || d == 'ece')
      return 'ECE';
    if (d.contains('electrical') || d == 'eee') return 'EEE';
    if (d.contains('mechanical') || d == 'mech' || d == 'me') return 'MECH';
    if (d.contains('civil') || d == 'ce') return 'CIVIL';
    if (d.contains('information') || d == 'it') return 'IT';
    if (d.contains('artificial') ||
        d.contains('data') ||
        d == 'ai' ||
        d == 'aids' ||
        d.contains('ai&ds') ||
        d.contains('ai & ds'))
      return 'AI&DS';
    return dept.trim().toUpperCase();
  }

  String _normalizeYear(String yearStr) {
    String y = yearStr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (y.contains('1') || y.contains('first') || y == 'i') return '1';
    if (y.contains('2') || y.contains('second') || y == 'ii') return '2';
    if (y.contains('3') || y.contains('third') || y == 'iii') return '3';
    if (y.contains('4') || y.contains('fourth') || y == 'iv') return '4';
    return yearStr.trim();
  }

  List<String> get _departments {
    final depts =
        _students
            .map((s) => _normalizeDept(s.department))
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList();
    depts.sort();
    return ["ALL", ...depts];
  }

  List<String> get _years {
    final years =
        _students
            .map((s) => _normalizeYear(s.year))
            .where((y) => y.isNotEmpty)
            .toSet()
            .toList();
    years.sort();
    return ["ALL", ...years];
  }

  @override
  void initState() {
    super.initState();
    if (widget.lockedDepartment != null) {
      _selectedDept = _normalizeDept(widget.lockedDepartment!);
    }
    if (widget.lockedYear != null) {
      _selectedYear = _normalizeYear(widget.lockedYear!);
    }
    if (widget.lockedSection != null) {
      _selectedSection = widget.lockedSection!.toUpperCase().trim();
    }
    _fetchStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final list = await _apiService.getAllStudents();
      setState(() {
        _students = list;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load students: $e";
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents =
          _students.where((student) {
            final matchesSearch =
                student.name.toLowerCase().contains(query) ||
                student.id.toLowerCase().contains(query) ||
                student.rollNumber.toLowerCase().contains(query) ||
                student.department.toLowerCase().contains(query);

            final matchesDept =
                _selectedDept == "ALL" ||
                _normalizeDept(student.department) == _selectedDept;

            final matchesYear =
                _selectedYear == "ALL" ||
                _normalizeYear(student.year) == _selectedYear;

            final matchesSection =
                _selectedSection == "ALL" ||
                student.section.trim().toUpperCase() == _selectedSection;

            return matchesSearch &&
                matchesDept &&
                matchesYear &&
                matchesSection;
          }).toList();
    });
  }

  Future<void> _deleteStudent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Delete Student",
              style: GoogleFonts.outfit(
                color: ErpColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Are you sure you want to delete student $name ($id)? All corresponding courses and user login info will be removed.",
              style: GoogleFonts.outfit(color: ErpColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(color: ErpColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: ErpColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Delete",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteStudent(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Student deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchStudents();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting student: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Delete Selected (${_selectedStudentIds.length})",
              style: GoogleFonts.outfit(
                color: ErpColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Are you sure you want to delete the selected students?",
              style: GoogleFonts.outfit(color: ErpColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(color: ErpColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: ErpColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Delete",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _isProcessingBatch = true;
        _batchTitle = "Deleting Data...";
        _batchSubtitle = "students deleted";
        _batchTotal = _selectedStudentIds.length;
        _batchCurrent = 0;
      });

      int successCount = 0;
      for (var id in _selectedStudentIds.toList()) {
        try {
          await _apiService.deleteStudent(id);
          successCount++;
        } catch (e) {
          // Silently bypass single-row failures to allow batch to finish
        }
        if (mounted) {
          setState(() {
            _batchCurrent++;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isProcessingBatch = false;
          _isSelectionMode = false;
          _selectedStudentIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Completed: $successCount of $_batchTotal students deleted.",
            ),
            backgroundColor:
                successCount == _batchTotal ? Colors.green : Colors.orange,
          ),
        );
        _fetchStudents();
      }
    }
  }

  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        String? path = result.files.single.path;
        if (path == null) {
          setState(() => _isLoading = false);
          return;
        }

        var extension = path.split('.').last.toLowerCase();
        List<List<dynamic>> allRows = [];

        if (extension == 'csv') {
          final input = File(path).readAsStringSync();
          allRows = const CsvToListConverter().convert(input);
        } else {
          var bytes = File(path).readAsBytesSync();
          var excel = Excel.decodeBytes(bytes);
          for (var table in excel.tables.keys) {
            var rows = excel.tables[table]?.rows ?? [];
            for (var row in rows) {
              allRows.add(row.map((cell) => cell?.value).toList());
            }
          }
        }

        // Process unified rows (assume first row across all data is the header)
        bool skipFirst = true;
        List<Map<String, dynamic>> studentsToCreate = [];

        String getCellValue(List<dynamic> rowItem, int index) {
          if (index < 0 || index >= rowItem.length || rowItem[index] == null)
            return '';
          String val = rowItem[index].toString().trim();
          if (val.endsWith('.0')) {
            val = val.substring(0, val.length - 2);
          }
          return val;
        }

        var rows = allRows; // Alias for loop compatibility below

        int nameIdx = 0;
        int regNoIdx = 1;
        int emailIdx = 2;
        int phoneIdx = 3;
        int deptIdx = 4;
        int secIdx = 5;
        int yearIdx = 6;
        int passIdx = -1;
        int dobIdx = -1;
        int emNameIdx = -1;
        int emPhoneIdx = -1;
        int advisorIdx = -1;
        int addressIdx = -1;
        int residencyIdx = -1;
        int bloodIdx = -1;
        int cgpaIdx = -1;

        for (var row in rows) {
          if (skipFirst) {
            skipFirst = false;
            for (int i = 0; i < row.length; i++) {
              String header = row[i]?.toString().toLowerCase().trim() ?? '';
              if (header.contains('name') && !header.contains('emergency'))
                nameIdx = i;
              else if (header.contains('id') ||
                  header.contains('reg') ||
                  header.contains('roll'))
                regNoIdx = i;
              else if (header.contains('email'))
                emailIdx = i;
              else if ((header.contains('phone') ||
                      header.contains('mobile')) &&
                  !header.contains('emergency'))
                phoneIdx = i;
              else if (header.contains('dept') || header.contains('department'))
                deptIdx = i;
              else if (header.contains('sec'))
                secIdx = i;
              else if (header.contains('year'))
                yearIdx = i;
              else if (header.contains('pass'))
                passIdx = i;
              else if (header.contains('dob') || header.contains('birth'))
                dobIdx = i;
              else if (header.contains('emergency')) {
                if (header.contains('phone') ||
                    header.contains('number') ||
                    header.contains('no') ||
                    header.contains('num')) {
                  emPhoneIdx = i;
                } else {
                  emNameIdx = i;
                }
              } else if (header.contains('advisor') ||
                  header.contains('mentor') ||
                  header.contains('counselor'))
                advisorIdx = i;
              else if (header.contains('address') ||
                  header.contains('city') ||
                  header.contains('location'))
                addressIdx = i;
              else if (header.contains('resid') ||
                  header.contains('hostel') ||
                  header.contains('scholar') ||
                  header.contains('accom'))
                residencyIdx = i;
              else if (header.contains('blood'))
                bloodIdx = i;
              else if (header.contains('cgpa') || header.contains('gpa'))
                cgpaIdx = i;
            }
            continue;
          }
          if (row.isEmpty) continue;

          // Dynamically extracted values from discovered headers
          String name = getCellValue(row, nameIdx);
          String regNo = getCellValue(row, regNoIdx);
          String email = getCellValue(row, emailIdx);
          String phone = getCellValue(row, phoneIdx);
          String excelDept = getCellValue(row, deptIdx);
          String excelSec = getCellValue(row, secIdx);
          String excelYear = getCellValue(row, yearIdx);

          String excelDob = dobIdx != -1 ? getCellValue(row, dobIdx) : "";
          String excelEmName =
              emNameIdx != -1 ? getCellValue(row, emNameIdx) : "";
          String excelEmPhone =
              emPhoneIdx != -1 ? getCellValue(row, emPhoneIdx) : "";
          String excelAdvisor =
              advisorIdx != -1 ? getCellValue(row, advisorIdx) : "";
          String excelAddress =
              addressIdx != -1 ? getCellValue(row, addressIdx) : "";
          String excelResidency =
              residencyIdx != -1 ? getCellValue(row, residencyIdx) : "";
          String excelBlood = bloodIdx != -1 ? getCellValue(row, bloodIdx) : "";
          String excelCgpa = cgpaIdx != -1 ? getCellValue(row, cgpaIdx) : "0.0";

          String excelPass =
              passIdx != -1 ? getCellValue(row, passIdx) : "pass@123";
          if (excelPass.isEmpty) excelPass = "pass@123";

          // Auto-generate email if missing, to satisfy backend constraints
          if (regNo.isNotEmpty && email.isEmpty) {
            email = "$regNo@student.college.edu".toLowerCase();
          }

          // Determine Target Filters based on User's current screen context
          String targetDept =
              (widget.lockedDepartment != null &&
                      widget.lockedDepartment != "ALL")
                  ? _normalizeDept(widget.lockedDepartment!)
                  : _selectedDept;
          String targetYear =
              (widget.lockedYear != null && widget.lockedYear != "ALL")
                  ? _normalizeYear(widget.lockedYear!)
                  : _selectedYear;
          String targetSection =
              (widget.lockedSection != null && widget.lockedSection != "ALL")
                  ? widget.lockedSection!.toUpperCase().trim()
                  : _selectedSection;

          // We no longer coerce the excel variables! If they exist in the sheet, they dictate reality!

          // Defaults if Excel cell is empty, forcing them into the current active context
          String finalDept =
              excelDept.isNotEmpty
                  ? _normalizeDept(excelDept)
                  : (targetDept != "ALL" ? targetDept : "CSE");
          String tmpSec =
              excelSec.isNotEmpty
                  ? excelSec.toUpperCase()
                  : (targetSection != "ALL" ? targetSection : "A");
          String finalYear =
              excelYear.isNotEmpty
                  ? _normalizeYear(excelYear)
                  : (targetYear != "ALL" ? targetYear : "1");

          String finalSection = (tmpSec == 'A' || tmpSec == 'B') ? tmpSec : 'A';
          String finalResidency =
              excelResidency.toUpperCase().contains('HOSTEL')
                  ? 'HOSTELLER'
                  : 'DAY_SCHOLAR';

          // EXPLICIT FILTER: Only harvest rows that strictly match the active UI screen filters.
          // By skipping rows that conflict, uploading a mixed A/B file while in 'A' portal only captures 'A'.
          if (targetDept != "ALL" && finalDept != targetDept) continue;
          if (targetYear != "ALL" && finalYear != targetYear) continue;
          if (targetSection != "ALL" && finalSection != targetSection) continue;

          if (regNo.isNotEmpty) {
            final data = {
              "id": regNo,
              "name": name.isEmpty ? "Unknown" : name,
              "rollNumber": regNo,
              "email": email,
              "phone": phone,
              "department": finalDept,
              "year": finalYear,
              "section": finalSection,
              "semester": (int.tryParse(finalYear) ?? 1) * 2 - 1,
              "bloodGroup": excelBlood.toUpperCase(),
              "dob": excelDob,
              "emergencyContactName": excelEmName,
              "emergencyContactPhone": excelEmPhone,
              "address": excelAddress,
              "advisor": excelAdvisor,
              "residencyType": finalResidency,
              "cgpa": double.tryParse(excelCgpa) ?? 0.0,
              "status": "ACTIVE",
            };
            // Queue API Calls sequentially in futures array
            studentsToCreate.add({'data': data, 'pass': excelPass});
          }
        }
        // Batch push
        if (studentsToCreate.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No valid students found in the Excel file to upload.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() {
            _isProcessingBatch = true;
            _batchTitle = "Importing Data...";
            _batchSubtitle = "students added";
            _batchTotal = studentsToCreate.length;
            _batchCurrent = 0;
          });

          for (var payload in studentsToCreate) {
            try {
              await _apiService.createStudent(payload['data'], payload['pass']);
            } catch (e) {
              // Silently bypass single-row failures to allow batch to continue mapping
            }
            if (mounted) {
              setState(() {
                _batchCurrent++;
              });
            }
          }

          if (mounted) {
            setState(() {
              _isProcessingBatch = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Excel data processing complete ($_batchTotal rows processed).",
                ),
                backgroundColor: Colors.green,
              ),
            );
            _fetchStudents();
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error importing Excel: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openAddEditDialog({Student? student}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _StudentFormDialog(
            student: student,
            onSave: (Map<String, dynamic> data, String? password) async {
              Navigator.pop(ctx); // Close dialog
              setState(() => _isLoading = true);
              try {
                if (student == null) {
                  // Create
                  await _apiService.createStudent(data, password!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Student created successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Update
                  await _apiService.updateStudent(
                    student.id,
                    data,
                    password: password,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Student updated successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _fetchStudents();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error saving student: $e"),
                    backgroundColor: Colors.red,
                  ),
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
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        elevation: 0,
        title: Text(
          _isSelectionMode
              ? "${_selectedStudentIds.length} Selected"
              : "Manage Students",
          style: ErpTypography.titleLarge.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_selectedStudentIds.length == _filteredStudents.length) {
                    _selectedStudentIds.clear(); // Deselect all
                  } else {
                    _selectedStudentIds.addAll(
                      _filteredStudents.map((s) => s.id),
                    );
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: ErpColors.danger,
              ),
              onPressed:
                  _selectedStudentIds.isEmpty ? null : _deleteSelectedStudents,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedStudentIds.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(
                Icons.checklist_rtl_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
          ],
        ],
      ),
      body:
          _isProcessingBatch
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: ErpColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      _batchTitle,
                      style: GoogleFonts.outfit(
                        color: ErpColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$_batchCurrent of $_batchTotal $_batchSubtitle",
                      style: GoogleFonts.outfit(
                        color: ErpColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${((_batchCurrent / (_batchTotal > 0 ? _batchTotal : 1)) * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.outfit(
                        color: ErpColors.success,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ErpErrorState(
                      message:
                          'We could not retrieve student records right now.',
                      onRetry: _fetchStudents,
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            "Search student by name, roll, or department...",
                        hintStyle: GoogleFonts.outfit(
                          color: ErpColors.textPrimary.withOpacity(0.3),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: ErpColors.textMuted,
                        ),
                        fillColor: ErpColors.bgWhite,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: ErpColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C63FF),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Department & Year Filters Row
                  if (widget.lockedDepartment == null ||
                      widget.lockedYear == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value:
                                  _departments.contains(_selectedDept)
                                      ? _selectedDept
                                      : "ALL",
                              style: GoogleFonts.outfit(
                                color: ErpColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: "Department Filter",
                                labelStyle: GoogleFonts.outfit(
                                  color: ErpColors.textMuted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                fillColor: ErpColors.bgWhite,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              dropdownColor: ErpColors.bgWhite,
                              items:
                                  _departments.map((d) {
                                    return DropdownMenuItem<String>(
                                      value: d,
                                      child: Text(d),
                                    );
                                  }).toList(),
                              onChanged:
                                  widget.lockedDepartment != null
                                      ? null
                                      : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedDept = val;
                                          });
                                          _applyFilters();
                                        }
                                      },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value:
                                  _years.contains(_selectedYear)
                                      ? _selectedYear
                                      : "ALL",
                              style: GoogleFonts.outfit(
                                color: ErpColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: "Year Filter",
                                labelStyle: GoogleFonts.outfit(
                                  color: ErpColors.textMuted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                fillColor: ErpColors.bgWhite,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              dropdownColor: ErpColors.bgWhite,
                              items:
                                  _years.map((y) {
                                    return DropdownMenuItem<String>(
                                      value: y,
                                      child: Text(
                                        y == "ALL" ? "ALL" : "Year $y",
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  widget.lockedYear != null
                                      ? null
                                      : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedYear = val;
                                          });
                                          _applyFilters();
                                        }
                                      },
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child:
                        _filteredStudents.isEmpty
                            ? Center(
                              child: Text(
                                "No students found.",
                                style: GoogleFonts.outfit(
                                  color: ErpColors.textMuted,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredStudents.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (ctx, index) {
                                final student = _filteredStudents[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: ErpColors.bgWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: ErpColors.border),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    onTap:
                                        _isSelectionMode
                                            ? () {
                                              setState(() {
                                                if (_selectedStudentIds
                                                    .contains(student.id)) {
                                                  _selectedStudentIds.remove(
                                                    student.id,
                                                  );
                                                } else {
                                                  _selectedStudentIds.add(
                                                    student.id,
                                                  );
                                                }
                                              });
                                            }
                                            : null,
                                    leading:
                                        _isSelectionMode
                                            ? Checkbox(
                                              value: _selectedStudentIds
                                                  .contains(student.id),
                                              activeColor: const Color(
                                                0xFF6C63FF,
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedStudentIds.add(
                                                      student.id,
                                                    );
                                                  } else {
                                                    _selectedStudentIds.remove(
                                                      student.id,
                                                    );
                                                  }
                                                });
                                              },
                                            )
                                            : Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF00D68F,
                                                ).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.school,
                                                color: Color(0xFF00D68F),
                                              ),
                                            ),
                                    title: Text(
                                      student.name,
                                      style: GoogleFonts.outfit(
                                        color: ErpColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          "ID/Roll: ${student.id} | Dept: ${_normalizeDept(student.department)} · Year ${_normalizeYear(student.year)}",
                                          style: GoogleFonts.outfit(
                                            color: ErpColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Email: ${student.email}",
                                          style: GoogleFonts.outfit(
                                            color: ErpColors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (student.residencyType
                                                            .toUpperCase()
                                                            .contains('HOSTEL'))
                                                        ? Colors.amber
                                                            .withOpacity(0.15)
                                                        : const Color(
                                                          0xFF3A86FF,
                                                        ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (student.residencyType
                                                        .toUpperCase()
                                                        .contains('HOSTEL'))
                                                    ? 'Hosteler'
                                                    : 'Day Scholar',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      (student.residencyType
                                                              .toUpperCase()
                                                              .contains(
                                                                'HOSTEL',
                                                              ))
                                                          ? Colors.amberAccent
                                                          : const Color(
                                                            0xFF3A86FF,
                                                          ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFF72585,
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Sec ${student.section}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFFF72585,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: ErpColors.textSecondary,
                                          ),
                                          onPressed:
                                              () => _openAddEditDialog(
                                                student: student,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed:
                                              () => _deleteStudent(
                                                student.id,
                                                student.name,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'importExcel',
            backgroundColor: const Color(0xFF00D68F),
            foregroundColor: Colors.white,
            onPressed: () => _importFromExcel(),
            icon: const Icon(Icons.table_view_rounded),
            label: Text(
              "Bulk Excel",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addSingle',
            backgroundColor: ErpColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => _openAddEditDialog(),
            icon: const Icon(Icons.person_add_rounded, size: 24),
            label: Text(
              "Add Single",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentFormDialog extends StatefulWidget {
  final Student? student;
  final Function(Map<String, dynamic> data, String? password) onSave;

  const _StudentFormDialog({Key? key, this.student, required this.onSave})
    : super(key: key);

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _rollNumberController;
  late TextEditingController _departmentController;
  late TextEditingController _sectionController;
  late TextEditingController _yearController;
  late TextEditingController _semesterController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _dobController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _advisorController;
  late TextEditingController _cgpaController;
  late TextEditingController _passwordController;
  String _residencyType = "DAY_SCHOLAR";
  late TextEditingController _currentPasswordController;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _idController = TextEditingController(text: s?.id ?? '');
    _nameController = TextEditingController(text: s?.name ?? '');
    _rollNumberController = TextEditingController(text: s?.rollNumber ?? '');
    _departmentController = TextEditingController(text: s?.department ?? '');
    _sectionController = TextEditingController(text: s?.section ?? '');
    _yearController = TextEditingController(text: s?.year ?? '');
    _semesterController = TextEditingController(text: s?.semester ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _bloodGroupController = TextEditingController(text: s?.bloodGroup ?? '');
    _dobController = TextEditingController(text: s?.dob ?? '');
    _emergencyContactNameController = TextEditingController(
      text: s?.emergencyContactName ?? '',
    );
    _emergencyContactPhoneController = TextEditingController(
      text: s?.emergencyContactPhone ?? '',
    );
    _addressController = TextEditingController(text: s?.address ?? '');
    _advisorController = TextEditingController(text: s?.advisor ?? '');
    _cgpaController = TextEditingController(text: s?.cgpa.toString() ?? '0.0');
    _passwordController = TextEditingController();
    _currentPasswordController = TextEditingController(text: "Loading...");
    final initialRes = s?.residencyType ?? 'DAY_SCHOLAR';
    _residencyType =
        initialRes.toUpperCase().contains('HOSTEL')
            ? 'HOSTELLER'
            : 'DAY_SCHOLAR';

    if (s != null) {
      _fetchCurrentPassword(s.id);
    }
  }

  Future<void> _fetchCurrentPassword(String id) async {
    try {
      final AdminApiService apiService = AdminApiService();
      String pwd = await apiService.getStudentPassword(id);
      if (mounted) {
        setState(() {
          _currentPasswordController.text = pwd.isEmpty ? "No password" : pwd;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPasswordController.text = "Error loading";
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _rollNumberController.dispose();
    _departmentController.dispose();
    _sectionController.dispose();
    _yearController.dispose();
    _semesterController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _dobController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _addressController.dispose();
    _advisorController.dispose();
    _cgpaController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

    return AlertDialog(
      backgroundColor: ErpColors.bgWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? "Edit Student Profile" : "Register Student",
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: ErpColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _idController,
                  readOnly: isEdit,
                  decoration: const InputDecoration(
                    labelText: "Student ID (Roll No, e.g. 21CS118)",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? "Student ID is required"
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_pin),
                  ),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? "Name is required"
                              : null,
                ),
                const SizedBox(height: 12),
                if (isEdit) ...[
                  TextFormField(
                    controller: _currentPasswordController,
                    readOnly: true,
                    style: GoogleFonts.outfit(color: ErpColors.textSecondary),
                    decoration: const InputDecoration(
                      labelText: "Current Password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password (Optional)",
                      prefixIcon: Icon(Icons.lock_clock_outlined),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Initial password",
                      prefixIcon: Icon(Icons.lock_clock_outlined),
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? "Initial password is required"
                                : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rollNumberController,
                  decoration: const InputDecoration(
                    labelText: "Roll Number (e.g. 118)",
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email address",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? "Email is required"
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: "Department",
                          hintText: "e.g. CSE",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sectionController,
                        decoration: const InputDecoration(
                          labelText: "Section",
                          hintText: "e.g. A",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: "Year",
                          hintText: "e.g. 3",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _semesterController,
                        decoration: const InputDecoration(
                          labelText: "Semester",
                          hintText: "e.g. 5",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bloodGroupController,
                        decoration: const InputDecoration(
                          labelText: "Blood Group",
                          hintText: "e.g. O+",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cgpaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: "CGPA"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth (YYYY-MM-DD)",
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _advisorController,
                  decoration: const InputDecoration(
                    labelText: "Class Advisor Name",
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyContactNameController,
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Person",
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyContactPhoneController,
                  decoration: const InputDecoration(
                    labelText: "Emergency Phone",
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _residencyType,
                  style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: "Accommodation/Residency Type",
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  dropdownColor: ErpColors.bgWhite,
                  items: const [
                    DropdownMenuItem(
                      value: "DAY_SCHOLAR",
                      child: Text("Day Scholar"),
                    ),
                    DropdownMenuItem(
                      value: "HOSTELLER",
                      child: Text("Hosteler (Hosteller)"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _residencyType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                  decoration: const InputDecoration(labelText: "Address"),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: GoogleFonts.outfit(color: ErpColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ErpColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                "id": _idController.text.trim(),
                "name": _nameController.text.trim(),
                "rollNumber": _rollNumberController.text.trim(),
                "department": _departmentController.text.trim().toUpperCase(),
                "section": _sectionController.text.trim().toUpperCase(),
                "year": _yearController.text.trim(),
                "semester": _semesterController.text.trim(),
                "email": _emailController.text.trim(),
                "phone": _phoneController.text.trim(),
                "bloodGroup": _bloodGroupController.text.trim().toUpperCase(),
                "dob": _dobController.text.trim(),
                "emergencyContactName":
                    _emergencyContactNameController.text.trim(),
                "emergencyContactPhone":
                    _emergencyContactPhoneController.text.trim(),
                "address": _addressController.text.trim(),
                "advisor": _advisorController.text.trim(),
                "cgpa": double.tryParse(_cgpaController.text) ?? 0.0,
                "residencyType": _residencyType,
              };
              widget.onSave(
                data,
                _passwordController.text.trim().isEmpty
                    ? null
                    : _passwordController.text.trim(),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
