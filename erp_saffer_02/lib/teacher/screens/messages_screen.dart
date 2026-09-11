import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../theme/teacher_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _service = MessageService();
  late Future<List<Conversation>> _conversationsFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _service.getConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search conversations',
                  prefixIcon: Icon(Icons.search, color: TeacherColors.textSecondary),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Conversation>>(
                future: _conversationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _MessagesSkeleton();
                  }
                  if (snapshot.hasError) {
                    return const ErpErrorState(
                      message: 'We could not retrieve conversations right now.',
                    );
                  }
                  final conversations = snapshot.data!
                      .where((c) => c.contactName.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                  if (conversations.isEmpty) {
                    return const ErpEmptyState(
                      message: 'No conversations found',
                      subtitle: 'Try a different contact name or start a new conversation.',
                      icon: Icons.forum_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    itemCount: conversations.length,
                    itemBuilder: (context, i) {
                      final c = conversations[i];
                      return _ConversationTile(
                        conversation: c,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => _ChatScreen(conversation: c, service: _service)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isParent = conversation.type == ConversationType.parent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: TeacherDecorations.card(radius: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                  backgroundColor: (isParent ? TeacherColors.info : TeacherColors.navy).withValues(alpha: 0.1),
                child: Icon(
                  isParent ? Icons.family_restroom_outlined : Icons.school_outlined,
                  color: isParent ? TeacherColors.info : TeacherColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conversation.contactName, style: TeacherTextStyles.heading3, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TeacherTextStyles.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (conversation.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: TeacherColors.brass, shape: BoxShape.circle),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final MessageService service;

  const _ChatScreen({required this.conversation, required this.service});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await widget.service.getMessages(widget.conversation.id);
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final sent = await widget.service.sendMessage(conversationId: widget.conversation.id, text: text);
    if (!mounted) return;
    setState(() {
      _messages = [..._messages, sent];
      _controller.clear();
      _sending = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(title: Text(widget.conversation.contactName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: TeacherColors.navy))
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return Align(
                          alignment: m.isFromTeacher ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: m.isFromTeacher ? TeacherColors.navy : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: TeacherColors.navy.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(color: m.isFromTeacher ? Colors.white : TeacherColors.textPrimary, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: TeacherColors.navy,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _send,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
