import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/approval_request.dart';
import '../../services/approval_api_service.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final ApprovalApiService _apiService = ApprovalApiService();
  List<ApprovalRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiService.getPendingRequests();
      setState(() => _requests = data);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load approvals: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processRequest(int id, bool approve) async {
    final c = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            title: Text(
              approve ? 'Approve Request' : 'Reject Request',
              style: ErpTypography.titleMedium,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please provide a message for the HOD.',
                  style: ErpTypography.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (Optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      approve ? ErpColors.success : ErpColors.danger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final feedback =
            c.text.trim().isEmpty
                ? (approve ? 'Approved' : 'Rejected')
                : c.text.trim();
        if (approve) {
          await _apiService.approveRequest(id, feedback);
        } else {
          await _apiService.rejectRequest(id, feedback);
        }
        ErpSnackbar.show(
          context,
          message: 'Request processed.',
          type: ErpBadgeType.success,
        );
        _fetchRequests();
      } catch (e) {
        ErpSnackbar.show(
          context,
          message: 'Error: $e',
          type: ErpBadgeType.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(
        title: 'Approval Inbox',
        subtitle: 'Review & manage HOD faculty requests',
        showBack: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : _errorMessage != null
              ? ErpErrorState(message: _errorMessage!, onRetry: _fetchRequests)
              : _requests.isEmpty
              ? const ErpEmptyState(
                icon: Icons.done_all_rounded,
                message: 'No pending approvals right now!',
              )
              : RefreshIndicator(
                onRefresh: _fetchRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (ctx, i) {
                    final req = _requests[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ErpCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ErpStatusBadge(
                                  label: req.actionType,
                                  type:
                                      req.actionType == 'DELETE'
                                          ? ErpBadgeType.danger
                                          : (req.actionType == 'ADD'
                                              ? ErpBadgeType.success
                                              : ErpBadgeType.info),
                                ),
                                const Spacer(),
                                Text(
                                  req.createdAt ?? '',
                                  style: ErpTypography.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Department: ${req.department}',
                              style: ErpTypography.titleSmall,
                            ),
                            Text(
                              'Target: ${req.teacherName ?? "New Teacher"}',
                              style: ErpTypography.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ErpColors.warningSurface,
                                borderRadius: BorderRadius.circular(
                                  ErpRadius.sm,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    color: ErpColors.warning,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '"${req.reason}"\n— HOD (${req.hodId})',
                                      style: ErpTypography.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: ErpColors.danger,
                                    ),
                                    onPressed:
                                        () => _processRequest(req.id!, false),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ErpColors.success,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed:
                                        () => _processRequest(req.id!, true),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
