class Fee {
  final int? studentFeeId;
  final String particular;
  final double amount;
  final double amountPaid;
  final double balanceAmount;
  final bool isPaid;
  final String dueDate;
  final String status;
  final String academicYear;
  final String semester;

  Fee({
    this.studentFeeId,
    required this.particular,
    required this.amount,
    required this.amountPaid,
    required this.balanceAmount,
    required this.isPaid,
    required this.dueDate,
    this.status = 'PENDING',
    this.academicYear = '',
    this.semester = '',
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    final sId = json["studentFeeId"] as int?;
    final feeCategory = json["feeCategory"] ?? json["particular"] ?? "";
    final totalFee = (json["totalFee"] ?? json["amount"] ?? 0.0) as num;
    final paidAmount = (json["amountPaid"] ?? 0.0) as num;
    final paymentStatus = json["paymentStatus"] ?? json["status"] ?? "";
    final ay = json["academicYear"]?.toString() ?? "";
    final sem = json["semester"]?.toString() ?? "";

    final isPaid =
        paymentStatus.toString().toUpperCase() == "PAID" ||
        json["paid"] == true ||
        json["isPaid"] == true;

    final balAmount =
        json["balanceAmount"] != null
            ? (json["balanceAmount"] as num).toDouble()
            : (totalFee.toDouble() - paidAmount.toDouble());

    return Fee(
      studentFeeId: sId,
      particular: feeCategory,
      amount: totalFee.toDouble(),
      amountPaid: paidAmount.toDouble(),
      balanceAmount: balAmount,
      isPaid: isPaid,
      dueDate: json["dueDate"]?.toString() ?? "",
      status:
          paymentStatus.toString().isEmpty
              ? (isPaid ? 'PAID' : 'PENDING')
              : paymentStatus.toString(),
      academicYear: ay,
      semester: sem,
    );
  }
}

class FeePayment {
  final int id;
  final String studentId;
  final double amountPaid;
  final String paymentDate;
  final String paymentMode;
  final String transactionId;
  final String remarks;
  final String feeCategory;
  final String academicYear;
  final String semester;

  FeePayment({
    required this.id,
    required this.studentId,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMode,
    required this.transactionId,
    required this.remarks,
    required this.feeCategory,
    required this.academicYear,
    required this.semester,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: json['id'] as int? ?? 0,
      studentId:
          json['student']?['id']?.toString() ??
          json['studentId']?.toString() ??
          '',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['paymentDate']?.toString() ?? '',
      paymentMode: json['paymentMode']?.toString() ?? 'ONLINE',
      transactionId: json['transactionId']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      feeCategory: json['feeCategory']?.toString() ?? '',
      academicYear: json['academicYear']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
    );
  }
}
