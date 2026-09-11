import '../models/assignment.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';

/// Handles creating, listing, and reviewing assignments.
///
/// Mock data phase: in-memory list seeded with sample assignments.
/// Later, replace with real `http` calls, e.g. multipart POST for the PDF
/// attachment upload in [createAssignment].
class AssignmentService {
  // static final List<Assignment> _mockAssignments = [
  //   Assignment(
  //     id: 'A001',
  //     title: 'Binary Search Trees - Implementation',
  //     description: 'Implement insertion, deletion, and traversal for a BST in C++.',
  //     dueDate: DateTime.now().add(const Duration(days: 5)),
  //     section: 'III CSE A',
  //     attachmentFileName: 'bst_assignment.pdf',
  //     submissionCount: 24,
  //     totalStudents: 48,
  //     isPublished: true,
  //   ),
  //   Assignment(
  //     id: 'A002',
  //     title: 'Normalization Case Study',
  //     description: 'Normalize the given schema up to 3NF with justification.',
  //     dueDate: DateTime.now().add(const Duration(days: 2)),
  //     section: 'III CSE B',
  //     attachmentFileName: 'normalization_case_study.pdf',
  //     submissionCount: 31,
  //     totalStudents: 46,
  //     isPublished: true,
  //   ),
  //   Assignment(
  //     id: 'A003',
  //     title: 'Process Scheduling Algorithms',
  //     description: 'Compare FCFS, SJF, and Round Robin with worked examples.',
  //     dueDate: DateTime.now().add(const Duration(days: 7)),
  //     section: 'III CSE A',
  //     submissionCount: 6,
  //     totalStudents: 48,
  //     isPublished: false,
  //   ),
  // ];

  /// GET /assignments?teacherId=
  Future<List<Assignment>> getAssignments() async {

    final response = await http.get(Uri.parse(ApiConstants.assignments));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      try {
        return data.map((e) => Assignment.fromJson(e)).toList();
      } catch (e, s) {
        print("JSON ERROR: $e");
        print(s);
        rethrow;
      }
    }

    throw Exception("Failed to load assignments");
  }


  Future<void> createAssignment({
    required String title,
    required String description,
    required DateTime dueDate,
    required String section,
    required String department,
    required String year,
    String? attachmentFileName,
    required String createdBy,
  }) async {

    final body = {
      "title": title,
      "description": description,
      "dueDate": dueDate.toIso8601String(),
      "department": department,
      "year": year,
      "section": section,
      "attachmentFile": attachmentFileName,
      "createdBy": createdBy,
      "isPublished": true,
    };

    final response = await http.post(
      Uri.parse(ApiConstants.assignments),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Unable to create assignment");
    }
  }

  /// GET /assignments/{id}/submissions
  Future<List<AssignmentSubmission>> getSubmissions(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return List.generate(6, (i) {
      final n = i + 1;
      return AssignmentSubmission(
        studentId: 'STU${n.toString().padLeft(3, '0')}',
        studentName: _mockNames[i % _mockNames.length],
        rollNumber: '21CSE${n.toString().padLeft(3, '0')}',
        submittedAt: DateTime.now().subtract(Duration(hours: i * 3)),
        isReviewed: i.isEven,
        marksAwarded: i.isEven ? 8.5 : null,
      );
    });
  }

  static const _mockNames = [
    'Arun Kumar', 'Divya Sri', 'Karthik Raja', 'Priya Dharshini', 'Vignesh S', 'Meena Loshini',
  ];

  /// PUT /assignments/{assignmentId}/submissions/{studentId}/review
  Future<bool> reviewSubmission({
    required String assignmentId,
    required String studentId,
    required double marks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: PUT marks to backend.
    return true;
  }
}
