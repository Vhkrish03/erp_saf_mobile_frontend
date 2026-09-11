import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';
import '../../teacher/models/teacher.dart';
import 'teacher_subject_assignment_screen.dart';

class DepartmentAssignmentScreen extends StatefulWidget {
  final String departmentId, departmentName;
  const DepartmentAssignmentScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  State<DepartmentAssignmentScreen> createState() =>
      _DepartmentAssignmentScreenState();
}

class _DepartmentAssignmentScreenState
    extends State<DepartmentAssignmentScreen> {
  final AdminApiService _apiService = AdminApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Teacher> _teachers = [];
  List<Teacher> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final all = await _apiService.getAllTeachers();
      final dept =
          all
              .where(
                (t) =>
                    t.department.toUpperCase() ==
                    widget.departmentId.toUpperCase(),
              )
              .toList();
      setState(() {
        _teachers = dept;
        _filtered = dept;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load faculty: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered =
          _teachers
              .where(
                (t) =>
                    t.name.toLowerCase().contains(q) ||
                    t.employeeId.toLowerCase().contains(q),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: '${widget.departmentId} Faculty',
        subtitle: 'Manage subject & role assignments',
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetch)
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: ErpSearchBar(
                      controller: _searchController,
                      onChanged: (_) {},
                      hint: 'Search faculty by name or ID…',
                    ),
                  ),
                  Expanded(
                    child:
                        _filtered.isEmpty
                            ? ErpEmptyState(
                              message:
                                  'No faculty found for ${widget.departmentId}',
                              icon: Icons.badge_outlined,
                            )
                            : RefreshIndicator(
                              color: ErpColors.primary,
                              onRefresh: _fetch,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                padding: const EdgeInsets.all(16),
                                itemBuilder: (ctx, i) {
                                  final t = _filtered[i];
                                  final initial =
                                      t.name.isNotEmpty
                                          ? t.name[0].toUpperCase()
                                          : 'F';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ErpCard(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      TeacherAssignmentManagementScreen(
                                                        teacher: t,
                                                      ),
                                            ),
                                          ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: ErpColors.infoSurface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    ErpRadius.md,
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              initial,
                                              style: ErpTypography
                                                  .headlineMedium
                                                  .copyWith(
                                                    color: ErpColors.info,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t.name,
                                                  style:
                                                      ErpTypography.titleMedium,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${t.employeeId} · ${t.department}',
                                                  style:
                                                      ErpTypography.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: ErpColors.primarySurface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    ErpRadius.sm,
                                                  ),
                                            ),
                                            child: const Icon(
                                              Icons.assignment_ind_outlined,
                                              size: 18,
                                              color: ErpColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
    );
  }
}
