class GrievanceMessage {
  final int? id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String department;
  final String receiverId;
  final String receiverName;
  final String receiverRole;
  final String subject;
  final String content;
  final bool isReadByReceiver;
  final bool isReadByAdmin;
  final String? timestamp;

  GrievanceMessage({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.department,
    required this.receiverId,
    required this.receiverName,
    required this.receiverRole,
    required this.subject,
    required this.content,
    this.isReadByReceiver = false,
    this.isReadByAdmin = false,
    this.timestamp,
  });

  factory GrievanceMessage.fromJson(Map<String, dynamic> json) {
    return GrievanceMessage(
      id: json['id'],
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? '',
      department: json['department'] ?? '',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      receiverRole: json['receiverRole'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      isReadByReceiver: json['readByReceiver'] ?? false,
      isReadByAdmin: json['readByAdmin'] ?? false,
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'department': department,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverRole': receiverRole,
      'subject': subject,
      'content': content,
    };
  }
}
