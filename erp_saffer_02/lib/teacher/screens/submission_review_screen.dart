import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../services/assignment_service.dart';
import '../theme/teacher_theme.dart';

class SubmissionsReviewScreen extends StatefulWidget {
  final Assignment assignment;

  final AssignmentService service;

  const SubmissionsReviewScreen({
    super.key,

    required this.assignment,

    required this.service,
  });

  @override
  State<SubmissionsReviewScreen> createState() =>
      _SubmissionsReviewScreenState();
}

class _SubmissionsReviewScreenState extends State<SubmissionsReviewScreen> {
  late Future<List<AssignmentSubmission>> _future;

  int selectedFilter = 0;

  final filters = ["All", "Pending", "Reviewed"];

  @override
  void initState() {
    super.initState();

    _load();
  }

  void _load() {
    _future = widget.service.getSubmissions(widget.assignment.id);
  }

  Future<void> _review(AssignmentSubmission submission) async {
    await widget.service.reviewSubmission(
      assignmentId: widget.assignment.id,

      studentId: submission.studentId,

      marks: 8.0,
    );

    setState(() {
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,

      appBar: AppBar(title: Text("Review Submission")),

      body: Column(
        children: [
          _assignmentHeader(),

          _filters(),

          Expanded(
            child: FutureBuilder<List<AssignmentSubmission>>(
              future: _future,

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                var submissions = snapshot.data ?? [];

                if (selectedFilter == 1) {
                  submissions = submissions.where((e) {
                    return !e.isReviewed;
                  }).toList();
                }

                if (selectedFilter == 2) {
                  submissions = submissions.where((e) {
                    return e.isReviewed;
                  }).toList();
                }

                if (submissions.isEmpty) {
                  return const Center(child: Text("No submissions found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),

                  itemCount: submissions.length,

                  itemBuilder: (context, index) {
                    return _studentCard(submissions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentHeader() {
    return Container(
      margin: const EdgeInsets.all(16),

      padding: const EdgeInsets.all(18),

      decoration: TeacherDecorations.card(radius: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(widget.assignment.title, style: TeacherTextStyles.heading2),

          const SizedBox(height: 8),

          Text(
            "${widget.assignment.year} Year • "
            "${widget.assignment.department} • "
            "${widget.assignment.section}",

            style: TeacherTextStyles.bodyMuted,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _infoBox(
                "Due",

                "${widget.assignment.dueDate.day}/"
                    "${widget.assignment.dueDate.month}",
              ),

              const SizedBox(width: 10),

              _infoBox(
                "Status",

                widget.assignment.isPublished ? "Published" : "Draft",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: TeacherColors.navy.withOpacity(.08),

          borderRadius: BorderRadius.circular(14),
        ),

        child: Column(
          children: [
            Text(title, style: TeacherTextStyles.bodyMuted),

            const SizedBox(height: 5),

            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 45,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        padding: const EdgeInsets.symmetric(horizontal: 18),

        itemCount: filters.length,

        itemBuilder: (context, index) {
          bool selected = index == selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = index;
              });
            },

            child: Container(
              margin: const EdgeInsets.only(right: 10),

              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),

              decoration: BoxDecoration(
                color: selected ? TeacherColors.navy : Colors.white,

                borderRadius: BorderRadius.circular(30),
              ),

              child: Text(
                filters[index],

                style: TextStyle(color: selected ? Colors.white : Colors.black),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _studentCard(AssignmentSubmission s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: TeacherDecorations.card(radius: 18),

      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: TeacherColors.navy,

            child: Text(s.studentName[0], selectionColor: Colors.white,),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(s.studentName, style: TeacherTextStyles.heading3),

                Text(s.rollNumber, style: TeacherTextStyles.bodyMuted),

                const SizedBox(height: 5),

                Text(
                  s.isReviewed
                      ? "Reviewed • ${s.marksAwarded}/10"
                      : "Waiting for review",

                  style: TextStyle(
                    color: s.isReviewed ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          s.isReviewed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : OutlinedButton(
                  onPressed: () {
                    _review(s);
                  },

                  child: const Text("Review"),
                ),
        ],
      ),
    );
  }
}
