import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/notice_service.dart';
import '../theme/teacher_theme.dart';
import '../widgets/teacher_notice_card.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final NoticeService _service = NoticeService();
  late Future<List<Notice>> _historyFuture;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  NoticePriority _priority = NoticePriority.normal;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = _service.getNoticeHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title.'), backgroundColor: TeacherColors.danger),
      );
      return;
    }
    setState(() => _publishing = true);
    await _service.publishNotice(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
    );
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _historyFuture = _service.getNoticeHistory();
      _titleController.clear();
      _descriptionController.clear();
      _priority = NoticePriority.normal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice published successfully.'), backgroundColor: TeacherColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(title: const Text('Notices')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: TeacherDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Notice', style: TeacherTextStyles.heading2),
                  const SizedBox(height: 14),
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  Text('Priority', style: TeacherTextStyles.label),
                  const SizedBox(height: 8),
                  Row(
                    children: NoticePriority.values.map((p) {
                      final selected = p == _priority;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.label),
                          selected: selected,
                          selectedColor: TeacherColors.navy.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: selected ? TeacherColors.navy : TeacherColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          onSelected: (_) => setState(() => _priority = p),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _publishing ? null : _publish,
                      child: _publishing
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Publish'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Notice History', style: TeacherTextStyles.heading2),
            const SizedBox(height: 12),
            FutureBuilder<List<Notice>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: TeacherColors.navy)),
                  );
                }
                final notices = snapshot.data!;
                if (notices.isEmpty) {
                  return const Text('No notices published yet.', style: TeacherTextStyles.bodyMuted);
                }
                return Column(children: notices.map((n) => TeacherNoticeCard(notice: n)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}
