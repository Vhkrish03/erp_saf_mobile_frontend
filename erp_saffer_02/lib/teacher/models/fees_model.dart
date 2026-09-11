// ─── Models for the Fees module ─────────────────────────────────────────────
// lib/teacher/models/fees_model.dart

class FeeStructureModel {
  final int id;
  final String academicYear;
  final String semester;
  final String department;
  final String yearOfStudy;
  final String? section;
  final String feeCategory;
  final double totalAmount;
  final String? dueDate;
  final String? description;
  final bool isActive;

  const FeeStructureModel({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.department,
    required this.yearOfStudy,
    this.section,
    required this.feeCategory,
    required this.totalAmount,
    this.dueDate,
    this.description,
    this.isActive = true,
  });

  factory FeeStructureModel.fromJson(Map<String, dynamic> j) {
    return FeeStructureModel(
      id: (j['id'] as num).toInt(),
      academicYear: j['academicYear']?.toString() ?? '',
      semester: j['semester']?.toString() ?? '',
      department: j['department']?.toString() ?? '',
      yearOfStudy: j['yearOfStudy']?.toString() ?? '',
      section: j['section']?.toString(),
      feeCategory: j['feeCategory']?.toString() ?? '',
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: j['dueDate']?.toString(),
      description: j['description']?.toString(),
      isActive: j['isActive'] as bool? ?? true,
    );
  }
}

// ─── Student Fee (per student, per fee structure) ─────────────────────────────

class StudentFeeModel {
  final int studentFeeId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String department;
  final String semester;
  final String section;
  final String academicYear;
  final String feeCategory;
  final double totalFee;
  final double amountPaid;
  final double balanceAmount;
  final String
  paymentStatus; // PAID | PARTIALLY_PAID | PENDING | OVERDUE | WAIVED
  final String? dueDate;
  final String? remarks;
  final String? updatedAt;

  const StudentFeeModel({
    required this.studentFeeId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.department,
    required this.semester,
    required this.section,
    required this.academicYear,
    required this.feeCategory,
    required this.totalFee,
    required this.amountPaid,
    required this.balanceAmount,
    required this.paymentStatus,
    this.dueDate,
    this.remarks,
    this.updatedAt,
  });

  factory StudentFeeModel.fromJson(Map<String, dynamic> j) {
    return StudentFeeModel(
      studentFeeId: (j['studentFeeId'] as num).toInt(),
      studentId: j['studentId']?.toString() ?? '',
      studentName: j['studentName']?.toString() ?? '',
      rollNumber: j['rollNumber']?.toString() ?? '',
      department: j['department']?.toString() ?? '',
      semester: j['semester']?.toString() ?? '',
      section: j['section']?.toString() ?? '',
      academicYear: j['academicYear']?.toString() ?? '',
      feeCategory: j['feeCategory']?.toString() ?? '',
      totalFee: (j['totalFee'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (j['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (j['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: j['paymentStatus']?.toString() ?? 'PENDING',
      dueDate: j['dueDate']?.toString(),
      remarks: j['remarks']?.toString(),
      updatedAt: j['updatedAt']?.toString(),
    );
  }
}

// ─── Dashboard Stats ─────────────────────────────────────────────────────────

class FeeDashboardModel {
  final String department;
  final String semester;
  final String section;
  final String academicYear;
  final int totalStudents;
  final int paidCount;
  final int partiallyPaidCount;
  final int pendingCount;
  final int overdueCount;
  final double totalFeeAmount;
  final double collectedAmount;
  final double outstandingAmount;

  const FeeDashboardModel({
    required this.department,
    required this.semester,
    required this.section,
    required this.academicYear,
    required this.totalStudents,
    required this.paidCount,
    required this.partiallyPaidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.totalFeeAmount,
    required this.collectedAmount,
    required this.outstandingAmount,
  });

  factory FeeDashboardModel.fromJson(Map<String, dynamic> j) {
    return FeeDashboardModel(
      department: j['department']?.toString() ?? '',
      semester: j['semester']?.toString() ?? '',
      section: j['section']?.toString() ?? '',
      academicYear: j['academicYear']?.toString() ?? '',
      totalStudents: (j['totalStudents'] as num?)?.toInt() ?? 0,
      paidCount: (j['paidCount'] as num?)?.toInt() ?? 0,
      partiallyPaidCount: (j['partiallyPaidCount'] as num?)?.toInt() ?? 0,
      pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
      overdueCount: (j['overdueCount'] as num?)?.toInt() ?? 0,
      totalFeeAmount: (j['totalFeeAmount'] as num?)?.toDouble() ?? 0.0,
      collectedAmount: (j['collectedAmount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (j['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Fee Payment record ───────────────────────────────────────────────────────

class FeePaymentModel {
  final int id;
  final String studentId;
  final double amountPaid;
  final String paymentDate;
  final String? paymentMode;
  final String? transactionId;
  final String? paymentReference;
  final String? remarks;
  final String? recordedBy;
  final String? academicYear;
  final String? semester;
  final String? feeCategory;

  const FeePaymentModel({
    required this.id,
    required this.studentId,
    required this.amountPaid,
    required this.paymentDate,
    this.paymentMode,
    this.transactionId,
    this.paymentReference,
    this.remarks,
    this.recordedBy,
    this.academicYear,
    this.semester,
    this.feeCategory,
  });

  factory FeePaymentModel.fromJson(Map<String, dynamic> j) {
    return FeePaymentModel(
      id: (j['id'] as num).toInt(),
      studentId: j['student']?['id']?.toString() ?? '',
      amountPaid: (j['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: j['paymentDate']?.toString() ?? '',
      paymentMode: j['paymentMode']?.toString(),
      transactionId: j['transactionId']?.toString(),
      paymentReference: j['paymentReference']?.toString(),
      remarks: j['remarks']?.toString(),
      recordedBy: j['recordedBy']?.toString(),
      academicYear: j['academicYear']?.toString(),
      semester: j['semester']?.toString(),
      feeCategory: j['feeCategory']?.toString(),
    );
  }
}
