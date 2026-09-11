import 'package:erp_saf/models/student.dart';
import 'package:erp_saf/models/subject_model.dart';

class AssessmentModel {
  final int id;
  final String type; // "WEEKLY" or "IAT"
  final String name; // e.g. "Weekly Test 1", "IAT 1"
  final String academicYear;
  final String department;
  final int year;
  final String semester;
  final String section;
  final SubjectModel? subject;
  final String facultyId;
  final String date;
  final double maxMarks;
  final String
  status; // DRAFT, SUBMITTED, CLASS_INCHARGE_VERIFIED, HOD_VERIFIED, DEAN_APPROVED
  final List<AssessmentComponentModel> components;
  final AssessmentWorkflowModel? workflow;

  AssessmentModel({
    required this.id,
    required this.type,
    required this.name,
    required this.academicYear,
    required this.department,
    required this.year,
    required this.semester,
    required this.section,
    this.subject,
    required this.facultyId,
    required this.date,
    required this.maxMarks,
    required this.status,
    required this.components,
    this.workflow,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    var compsJson = json['components'] as List? ?? [];
    List<AssessmentComponentModel> comps =
        compsJson.map((c) => AssessmentComponentModel.fromJson(c)).toList();

    return AssessmentModel(
      id: json['id'],
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      academicYear: json['academicYear'] ?? '',
      department: json['department'] ?? '',
      year: json['year'] ?? 0,
      semester: json['semester'] ?? '',
      section: json['section'] ?? '',
      subject:
          json['subject'] != null
              ? SubjectModel.fromJson(json['subject'])
              : null,
      facultyId: json['facultyId'] ?? '',
      date: json['date'] ?? '',
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'DRAFT',
      components: comps,
      workflow:
          json['workflow'] != null
              ? AssessmentWorkflowModel.fromJson(json['workflow'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'academicYear': academicYear,
      'department': department,
      'year': year,
      'semester': semester,
      'section': section,
      'facultyId': facultyId,
      'date': date,
      'maxMarks': maxMarks,
      'status': status,
    };
  }
}

class AssessmentComponentModel {
  final int id;
  final String componentType; // WRITTEN, ASSIGNMENT, SEMINAR, QUIZ
  final double maxMarks;
  final double weightage;
  final bool isEntered;

  AssessmentComponentModel({
    required this.id,
    required this.componentType,
    required this.maxMarks,
    required this.weightage,
    this.isEntered = false,
  });

  factory AssessmentComponentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentComponentModel(
      id: json['id'],
      componentType: json['componentType'] ?? '',
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 0.0,
      weightage: (json['weightage'] as num?)?.toDouble() ?? 0.0,
      isEntered: json['entered'] ?? false,
    );
  }
}

class AssessmentMarkModel {
  final int? id;
  final Student student;
  final double marksObtained;
  final String enteredBy;
  final String? enteredAt;
  final int? componentId;

  AssessmentMarkModel({
    this.id,
    required this.student,
    required this.marksObtained,
    required this.enteredBy,
    this.enteredAt,
    this.componentId,
  });

  factory AssessmentMarkModel.fromJson(Map<String, dynamic> json) {
    return AssessmentMarkModel(
      id: (json['id'] as num?)?.toInt(),
      student: Student.fromJson(json['student']),
      marksObtained: (json['marksObtained'] as num?)?.toDouble() ?? 0.0,
      enteredBy: json['enteredBy'] ?? '',
      enteredAt: json['enteredAt'],
      componentId:
          json['component'] != null
              ? (json['component']['id'] as num?)?.toInt()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'student': {
        'id': student.id,
        'name': student.name,
        'rollNumber': student.rollNumber,
        'department': student.department,
        'section': student.section,
        'year': student.year,
        'semester': student.semester,
        'email': student.email,
        'phone': student.phone,
        'bloodGroup': student.bloodGroup,
        'dob': student.dob,
        'emergencyContactName': student.emergencyContactName,
        'emergencyContactPhone': student.emergencyContactPhone,
        'address': student.address,
        'advisor': student.advisor,
        'cgpa': student.cgpa,
      },
      'marksObtained': marksObtained,
      'enteredBy': enteredBy,
    };
  }
}

class AssessmentWorkflowModel {
  final int id;
  final String facultyStatus;
  final String classInchargeStatus;
  final String hodStatus;
  final String deanStatus;
  final String? hodComments;
  final String? submittedAt;
  final String? verifiedAt;
  final String? approvedAt;
  final String? lockedAt;

  AssessmentWorkflowModel({
    required this.id,
    required this.facultyStatus,
    required this.classInchargeStatus,
    required this.hodStatus,
    required this.deanStatus,
    this.hodComments,
    this.submittedAt,
    this.verifiedAt,
    this.approvedAt,
    this.lockedAt,
  });

  factory AssessmentWorkflowModel.fromJson(Map<String, dynamic> json) {
    return AssessmentWorkflowModel(
      id: json['id'],
      facultyStatus: json['facultyStatus'] ?? 'DRAFT',
      classInchargeStatus: json['classInchargeStatus'] ?? 'PENDING',
      hodStatus: json['hodStatus'] ?? 'PENDING',
      deanStatus: json['deanStatus'] ?? 'PENDING',
      hodComments: json['hodComments'],
      submittedAt: json['submittedAt'],
      verifiedAt: json['verifiedAt'],
      approvedAt: json['approvedAt'],
      lockedAt: json['lockedAt'],
    );
  }
}
