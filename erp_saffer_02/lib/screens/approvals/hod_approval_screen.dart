import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/approval_request.dart';
import '../../services/approval_api_service.dart';

class HodApprovalScreen extends StatefulWidget {
  final String hodId;
  const HodApprovalScreen({super.key, required this.hodId});

  @override
  State<HodApprovalScreen> createState() => _HodApprovalScreenState();
}

class _HodApprovalScreenState extends State<HodApprovalScreen> {
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
      final data = await _apiService.getHodRequests(widget.hodId);
      setState(() => _requests = data);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load request history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(
        title: 'Request History',
        subtitle: 'Track your faculty modification approvals',
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
                icon: Icons.history_rounded,
                message: 'No approval history found.',
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
                                  type: ErpBadgeType.info,
                                ),
                                const SizedBox(width: 8),
                                ErpStatusBadge(
                                  label: req.status,
                                  type:
                                      req.status == 'APPROVED'
                                          ? ErpBadgeType.success
                                          : (req.status == 'REJECTED'
                                              ? ErpBadgeType.danger
                                              : ErpBadgeType.warning),
                                ),
                                const Spacer(),
                                Text(
                                  req.createdAt?.split('T').first ?? '',
                                  style: ErpTypography.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Target: ${req.teacherName ?? "New Teacher"}',
                              style: ErpTypography.titleSmall,
                            ),
                            Text(
                              'Reason: "${req.reason}"',
                              style: ErpTypography.bodySmall,
                            ),
                            if (req.adminFeedback != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ErpColors.bgSubtle,
                                  borderRadius: BorderRadius.circular(
                                    ErpRadius.sm,
                                  ),
                                  border: Border.all(color: ErpColors.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.admin_panel_settings_rounded,
                                      size: 16,
                                      color: ErpColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Admin Reply: ${req.adminFeedback}',
                                        style: ErpTypography.caption,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
