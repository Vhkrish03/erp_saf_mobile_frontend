enum ConversationType { student, parent }

/// A single conversation thread (with a student or a parent).
class Conversation {
  final String id;
  final String contactName;
  final ConversationType type;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String avatarUrl;

  const Conversation({
    required this.id,
    required this.contactName,
    required this.type,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.avatarUrl = '',
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      type: (json['type'] as String? ?? 'student') == 'parent'
          ? ConversationType.parent
          : ConversationType.student,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] as String? ?? '') ?? DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactName': contactName,
      'type': type == ConversationType.parent ? 'parent' : 'student',
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
    };
  }
}

/// A single chat message within a conversation.
class ChatMessage {
  final String id;
  final String text;
  final bool isFromTeacher;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isFromTeacher,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isFromTeacher: json['isFromTeacher'] as bool? ?? false,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isFromTeacher': isFromTeacher,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
