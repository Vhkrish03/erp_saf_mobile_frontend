class ApprovalRequest {
  final int? id;
  final String hodId;
  final String department;
  final String actionType;
  final int? teacherId;
  final String? teacherName;
  final String? payload;
  final String reason;
  final String status;
  final String? adminFeedback;
  final String? createdAt;

  ApprovalRequest({
    this.id,
    required this.hodId,
    required this.department,
    required this.actionType,
    this.teacherId,
    this.teacherName,
    this.payload,
    required this.reason,
    required this.status,
    this.adminFeedback,
    this.createdAt,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'],
      hodId: json['hodId'] ?? '',
      department: json['department'] ?? '',
      actionType: json['actionType'] ?? 'UNKNOWN',
      teacherId: json['teacherId'],
      teacherName: json['teacherName'],
      payload: json['payload'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminFeedback: json['adminFeedback'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hodId': hodId,
      'department': department,
      'actionType': actionType,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'payload': payload,
      'reason': reason,
    };
  }
}
