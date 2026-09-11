import 'package:erp_saf/teacher/screens/submission_review_screen.dart';
import 'package:flutter/material.dart';
import '../../core/design_system.dart';

import '../models/assignment.dart';
import '../services/assignment_service.dart';
import '../theme/teacher_theme.dart';
import '../widgets/assignment_card.dart';
import 'create_assignment_sheet.dart';

class AssignmentsScreen extends StatefulWidget {
  final String employeeId;

  const AssignmentsScreen({super.key, required this.employeeId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final AssignmentService _service = AssignmentService();

  late Future<List<Assignment>> _assignmentsFuture;

  int _selectedFilter = 0;

  final List<String> filters = ["Active", "Completed", "All"];

  @override
  void initState() {
    super.initState();

    _loadAssignments();
  }

  void _loadAssignments() {
    _assignmentsFuture = _service.getAssignments();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadAssignments();
    });
  }

  void _openReview(Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionsReviewScreen(
          assignment: assignment,
          service: _service,
        ),
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return CreateAssignmentSheet(
          service: _service,
          onCreated: _refresh,
          employeeId: widget.employeeId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TeacherColors.navy,

        icon: const Icon(Icons.add, color: Colors.white),

        label: const Text(
          "Create Assignment",

          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),

        onPressed: _openCreateSheet,
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildFilters(),

            Expanded(
              child: FutureBuilder<List<Assignment>>(
                future: _assignmentsFuture,

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _AssignmentsSkeleton();
                  }

                  if (snapshot.hasError) {
                    return ErpErrorState(
                      message: 'We could not retrieve assignments right now.',
                      onRetry: _refresh,
                    );
                  }

                  List<Assignment> assignments = snapshot.data ?? [];

                  final now = DateTime.now();

                  if (_selectedFilter == 0) {
                    assignments = assignments.where((a) {
                      return a.dueDate.isAfter(now);
                    }).toList();
                  } else if (_selectedFilter == 1) {
                    assignments = assignments.where((a) {
                      return a.dueDate.isBefore(now);
                    }).toList();
                  }

                  if (assignments.isEmpty) {
                    return _emptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,

                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),

                      itemCount: assignments.length,

                      itemBuilder: (context, index) {
                        return AssignmentCard(
                          assignment: assignments[index],

                          onReview: () => _openReview(assignments[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Assignments",

                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  "Manage tasks and student submissions",

                  style: TextStyle(color: TeacherColors.textSecondary),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: TeacherColors.navy,

              borderRadius: BorderRadius.circular(16),
            ),

            child: const Icon(Icons.assignment_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 50,

      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18),

        scrollDirection: Axis.horizontal,

        itemCount: filters.length,

        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              margin: const EdgeInsets.only(right: 10),

              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),

              decoration: BoxDecoration(
                color: selected ? TeacherColors.navy : Colors.white,

                borderRadius: BorderRadius.circular(30),
              ),

              child: Text(
                filters[index],

                style: TextStyle(
                  color: selected ? Colors.white : TeacherColors.textPrimary,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.assignment_add, size: 70, color: TeacherColors.textMuted),

          const SizedBox(height: 15),

          const Text(
            "No assignments found",

            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 5),

          Text(
            "Create a new assignment for students",

            style: TextStyle(color: TeacherColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsSkeleton extends StatelessWidget {
  const _AssignmentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
