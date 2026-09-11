import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/grievance_message.dart';
import '../../services/message_api_service.dart';
import 'message_compose_screen.dart';

class MessageInboxScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;
  final String department;
  final bool isAdmin;

  const MessageInboxScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.department,
    this.isAdmin = false,
  });

  @override
  State<MessageInboxScreen> createState() => _MessageInboxScreenState();
}

class _MessageInboxScreenState extends State<MessageInboxScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = MessageApiService();
  late TabController _tabController;

  List<GrievanceMessage> _inbox = [];
  List<GrievanceMessage> _sent = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isAdmin ? 1 : 2, vsync: this);
    _fetchMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (widget.isAdmin) {
        _inbox = await _apiService.getAllAdminMessages();
      } else {
        final results = await Future.wait([
          _apiService.getInbox(widget.userId),
          _apiService.getSentMessages(widget.userId),
        ]);
        _inbox = results[0];
        _sent = results[1];
      }
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markRead(GrievanceMessage msg) {
    if (widget.isAdmin && !msg.isReadByAdmin) {
      _apiService.markReadByAdmin(msg.id!).then((_) => _fetchMessages());
    } else if (!widget.isAdmin &&
        !msg.isReadByReceiver &&
        msg.receiverId == widget.userId) {
      _apiService.markReadByReceiver(msg.id!).then((_) => _fetchMessages());
    }
  }

  void _showMessageDetails(GrievanceMessage msg) {
    _markRead(msg);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            title: Text(msg.subject, style: ErpTypography.titleMedium),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${msg.senderName} (${msg.senderRole})',
                    style: ErpTypography.bodySmall,
                  ),
                  Text(
                    'To: ${msg.receiverName} (${msg.receiverRole})',
                    style: ErpTypography.bodySmall,
                  ),
                  Text(
                    'Date: ${msg.timestamp?.replaceAll('T', ' ') ?? ''}',
                    style: ErpTypography.caption,
                  ),
                  const Divider(height: 24),
                  Text(msg.content, style: ErpTypography.bodyMedium),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildList(List<GrievanceMessage> msgs, bool isSentBox) {
    if (msgs.isEmpty) {
      return ErpEmptyState(
        icon: Icons.mail_outline,
        message:
            isSentBox
                ? 'You haven\'t sent any messages.'
                : 'Your inbox is empty.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: msgs.length,
        itemBuilder: (ctx, i) {
          final msg = msgs[i];
          final isUnread =
              widget.isAdmin
                  ? !msg.isReadByAdmin
                  : (!isSentBox && !msg.isReadByReceiver);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ErpCard(
              onTap: () => _showMessageDetails(msg),
              color: isUnread ? ErpColors.primarySurface : ErpColors.bgWhite,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSentBox ? Icons.send_rounded : Icons.mail_rounded,
                        color:
                            isUnread ? ErpColors.primary : ErpColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg.subject,
                          style:
                              isUnread
                                  ? ErpTypography.titleSmall.copyWith(
                                    color: ErpColors.primary,
                                  )
                                  : ErpTypography.titleSmall,
                        ),
                      ),
                      Text(
                        msg.timestamp?.split('T').first ?? '',
                        style: ErpTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSentBox
                        ? 'To: ${msg.receiverName} (${msg.receiverRole})'
                        : 'From: ${msg.senderName} (${msg.senderRole})',
                    style: ErpTypography.bodySmall,
                  ),
                  if (widget.isAdmin)
                    Text(
                      'Dept: ${msg.department}',
                      style: ErpTypography.caption,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin ? 'Global Messages & Grievances' : 'Secure Inbox',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.isAdmin
                  ? 'Monitor all confidential comms'
                  : '${widget.department} Department',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom:
            widget.isAdmin
                ? null
                : TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: ErpColors.accent,
                  tabs: const [Tab(text: 'Inbox'), Tab(text: 'Sent')],
                ),
      ),
      floatingActionButton:
          widget.isAdmin
              ? null
              : FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MessageComposeScreen(
                            senderId: widget.userId,
                            senderName: widget.userName,
                            senderRole: widget.userRole,
                            department: widget.department,
                          ),
                    ),
                  );
                  if (result == true) _fetchMessages();
                },
                backgroundColor: ErpColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Compose'),
              ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchMessages)
              : widget.isAdmin
              ? _buildList(_inbox, false)
              : TabBarView(
                controller: _tabController,
                children: [_buildList(_inbox, false), _buildList(_sent, true)],
              ),
    );
  }
}
