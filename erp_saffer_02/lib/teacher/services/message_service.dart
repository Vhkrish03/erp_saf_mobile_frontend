import '../models/message.dart';

/// Handles conversation lists and chat messages for the Messages screen.
/// Mock data phase: static conversations/messages. Later, this likely
/// wires up to either REST polling or a websocket/STOMP connection.
class MessageService {
  static final List<Conversation> _mockConversations = [
    Conversation(
      id: 'C001',
      contactName: 'Arun Kumar',
      type: ConversationType.student,
      lastMessage: 'Sir, could you clarify the assignment deadline?',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 20)),
      unreadCount: 2,
    ),
    Conversation(
      id: 'C002',
      contactName: 'Mr. Ganesan (Parent of Divya Sri)',
      type: ConversationType.parent,
      lastMessage: 'Thank you for the update on her attendance.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Conversation(
      id: 'C003',
      contactName: 'Karthik Raja',
      type: ConversationType.student,
      lastMessage: 'Submitted the assignment, please check.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 6)),
      unreadCount: 1,
    ),
    Conversation(
      id: 'C004',
      contactName: 'Mrs. Lakshmi (Parent of Priya Dharshini)',
      type: ConversationType.parent,
      lastMessage: 'Is there a parent-teacher meeting this month?',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// GET /messages/conversations?teacherId=
  Future<List<Conversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockConversations;
  }

  /// GET /messages/conversations/{id}
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      ChatMessage(
        id: 'M1',
        text: 'Good morning sir, I had a doubt about today\'s class.',
        isFromTeacher: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
      ),
      ChatMessage(
        id: 'M2',
        text: 'Sure, go ahead and ask.',
        isFromTeacher: true,
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: 'M3',
        text: 'Could you clarify the assignment deadline?',
        isFromTeacher: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    ];
  }

  /// POST /messages/conversations/{id}
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return ChatMessage(
      id: 'M${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromTeacher: true,
      sentAt: DateTime.now(),
    );
  }
}
