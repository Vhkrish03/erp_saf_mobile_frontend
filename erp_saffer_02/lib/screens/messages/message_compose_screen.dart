import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/grievance_message.dart';
import '../../services/message_api_service.dart';
import '../../services/admin_api_service.dart';
import '../../teacher/models/teacher.dart';
import '../../models/student.dart';

class MessageComposeScreen extends StatefulWidget {
  final String senderId;
  final String senderName;
  final String senderRole;
  final String department;

  const MessageComposeScreen({
    super.key,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.department,
  });

  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  final _apiService = MessageApiService();
  final _adminApiService = AdminApiService();

  late String _selectedRole;
  List<String> _roles = [];

  bool _isFetchingUsers = false;
  bool _isSending = false;

  // Selected Target
  String? _selectedReceiverId;
  String? _selectedReceiverName;

  // Caches for target population
  List<Teacher> _departmentTeachers = [];
  Map<String, dynamic>? _departmentHod;

  // Student Filters
  String _selectedYear = '1';
  String _selectedSection = 'A';
  List<Student> _filteredStudents = [];

  final List<String> _years = ['1', '2', '3', '4'];
  final List<String> _sections = ['A', 'B', 'C'];

  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.senderRole == 'STUDENT') {
      _roles = ['TEACHER', 'HOD'];
    } else {
      _roles = ['STUDENT', 'TEACHER', 'HOD'];
    }
    _selectedRole = _roles.first;
    _fetchUsersForRole();
  }

  Future<void> _fetchUsersForRole() async {
    setState(() {
      _isFetchingUsers = true;
      _selectedReceiverId = null;
      _selectedReceiverName = null;
    });

    try {
      if (_selectedRole == 'TEACHER') {
        final allTeachers = await _adminApiService.getAllTeachers();
        _departmentTeachers =
            allTeachers
                .where(
                  (t) =>
                      t.department.toUpperCase() ==
                      widget.department.toUpperCase(),
                )
                .toList();
      } else if (_selectedRole == 'HOD') {
        final allHods = await _adminApiService.getAllHods();
        final hodsInDept =
            allHods
                .where(
                  (h) =>
                      (h['department'] as String).toUpperCase() ==
                      widget.department.toUpperCase(),
                )
                .toList();
        if (hodsInDept.isNotEmpty) {
          _departmentHod = hodsInDept.first;
          _selectedReceiverId = _departmentHod!['employeeId'];
          _selectedReceiverName = _departmentHod!['name'];
        } else {
          _departmentHod = null;
        }
      } else if (_selectedRole == 'STUDENT') {
        await _fetchStudents();
      }
    } catch (e) {
      if (mounted)
        ErpSnackbar.show(
          context,
          message: 'Failed to load recipients: $e',
          type: ErpBadgeType.danger,
        );
    } finally {
      if (mounted) setState(() => _isFetchingUsers = false);
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isFetchingUsers = true;
      _selectedReceiverId = null;
      _selectedReceiverName = null;
    });
    try {
      final allStudents = await _adminApiService.getAllStudents();
      _filteredStudents =
          allStudents
              .where(
                (s) =>
                    s.department.toUpperCase() ==
                        widget.department.toUpperCase() &&
                    s.year == _selectedYear &&
                    s.section == _selectedSection,
              )
              .toList();
    } catch (e) {
      if (mounted)
        ErpSnackbar.show(
          context,
          message: 'Failed to load students: $e',
          type: ErpBadgeType.danger,
        );
    } finally {
      if (mounted) setState(() => _isFetchingUsers = false);
    }
  }

  void _send() async {
    if (_selectedReceiverId == null ||
        _contentCtrl.text.trim().isEmpty ||
        _subjectCtrl.text.trim().isEmpty) {
      ErpSnackbar.show(
        context,
        message: 'Please complete all fields and select a recipient',
        type: ErpBadgeType.warning,
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final msg = GrievanceMessage(
        senderId: widget.senderId,
        senderName: widget.senderName,
        senderRole: widget.senderRole,
        department: widget.department,
        receiverId: _selectedReceiverId!,
        receiverName: _selectedReceiverName ?? 'Unknown',
        receiverRole: _selectedRole,
        subject: _subjectCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );

      await _apiService.sendMessage(msg);
      ErpSnackbar.show(
        context,
        message: 'Message Sent Successfully.',
        type: ErpBadgeType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      ErpSnackbar.show(
        context,
        message: 'Failed to send message: $e',
        type: ErpBadgeType.danger,
      );
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildRecipientSelector() {
    if (_isFetchingUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: ErpColors.primary),
        ),
      );
    }

    if (_selectedRole == 'HOD') {
      if (_departmentHod == null) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            'No HOD configured for ${widget.department}',
            style: ErpTypography.bodySmall.copyWith(color: ErpColors.danger),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ErpColors.successSurface,
            borderRadius: BorderRadius.circular(ErpRadius.sm),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: ErpColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-selected: ${_departmentHod!['name']} (${_departmentHod!['employeeId']})',
                  style: ErpTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedRole == 'TEACHER') {
      if (_departmentTeachers.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            'No Teachers found in ${widget.department}',
            style: ErpTypography.bodySmall.copyWith(color: ErpColors.danger),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: DropdownButtonFormField<String>(
          value: _selectedReceiverId,
          hint: const Text('Select a Teacher'),
          dropdownColor: ErpColors.bgWhite,
          decoration: const InputDecoration(labelText: 'Faculty Member'),
          items:
              _departmentTeachers
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.employeeId,
                      child: Text('${t.name} (${t.employeeId})'),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            setState(() {
              _selectedReceiverId = v;
              _selectedReceiverName =
                  _departmentTeachers.firstWhere((t) => t.employeeId == v).name;
            });
          },
        ),
      );
    }

    if (_selectedRole == 'STUDENT') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items:
                      _years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('Year $y'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    _selectedYear = v!;
                    _fetchStudents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items:
                      _sections
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text('Sec $s'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    _selectedSection = v!;
                    _fetchStudents();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_filteredStudents.isEmpty)
            Text(
              'No Students found in Year $_selectedYear $_selectedSection',
              style: ErpTypography.bodySmall.copyWith(color: ErpColors.danger),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedReceiverId,
              hint: const Text('Select a Student'),
              dropdownColor: ErpColors.bgWhite,
              decoration: const InputDecoration(labelText: 'Student'),
              items:
                  _filteredStudents
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} (${s.rollNumber})'),
                        ),
                      )
                      .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedReceiverId = v;
                  _selectedReceiverName =
                      _filteredStudents.firstWhere((s) => s.id == v).name;
                });
              },
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(
        title: 'Compose Message',
        subtitle: 'Confidential peer-to-peer communication',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErpCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient Details (Auto-filtered for ${widget.department})',
                    style: ErpTypography.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    dropdownColor: ErpColors.bgWhite,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items:
                        _roles
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() => _selectedRole = v!);
                      _fetchUsersForRole();
                    },
                  ),
                  _buildRecipientSelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ErpCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message Content', style: ErpTypography.titleSmall),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject (e.g. Complaint, Query)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Message',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: ErpColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isSending
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Send Confidential Message'),
            ),
          ],
        ),
      ),
    );
  }
}
