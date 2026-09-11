import 'package:flutter/material.dart';
import '../models/fees_model.dart';
import '../services/fee_service.dart';
import '../theme/teacher_theme.dart';

/// Detailed fee record for a single student, with payment history
/// and option for Class Incharge to record a new payment.
class StudentFeeDetailScreen extends StatefulWidget {
  final StudentFeeModel fee;
  final String employeeId;
  final VoidCallback? onPaymentRecorded;

  const StudentFeeDetailScreen({
    super.key,
    required this.fee,
    required this.employeeId,
    this.onPaymentRecorded,
  });

  @override
  State<StudentFeeDetailScreen> createState() => _StudentFeeDetailScreenState();
}

class _StudentFeeDetailScreenState extends State<StudentFeeDetailScreen> {
  final FeeService _api = FeeService();
  List<FeePaymentModel> _payments = [];
  bool _loadingPayments = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final p = await _api.getPaymentHistory(widget.fee.studentId);
      if (mounted)
        setState(() {
          _payments = p;
          _loadingPayments = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAID':
        return TeacherColors.success;
      case 'PARTIALLY_PAID':
        return TeacherColors.warning;
      case 'OVERDUE':
        return TeacherColors.danger;
      default:
        return TeacherColors.info;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PAID':
        return 'Paid';
      case 'PARTIALLY_PAID':
        return 'Partially Paid';
      case 'OVERDUE':
        return 'Overdue';
      case 'WAIVED':
        return 'Waived';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fee;
    final statusColor = _statusColor(f.paymentStatus);

    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        title: Text(
          f.studentName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (f.paymentStatus != 'PAID' && f.paymentStatus != 'WAIVED')
            TextButton.icon(
              onPressed: () => _showRecordPaymentDialog(context),
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: TeacherColors.brass,
              ),
              label: const Text(
                'Record Payment',
                style: TextStyle(
                  color: TeacherColors.brass,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Header Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TeacherDecorations.navyCard(radius: 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          f.rollNumber,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${f.department} · Sem ${f.semester} · Sec ${f.section}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        _statusLabel(f.paymentStatus),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavyAmountCol(
                      'Total Fee',
                      '₹${f.totalFee.toStringAsFixed(0)}',
                      Colors.white,
                    ),
                    _navyDiv(),
                    _NavyAmountCol(
                      'Paid',
                      '₹${f.amountPaid.toStringAsFixed(0)}',
                      const Color(0xFF7DF9C0),
                    ),
                    _navyDiv(),
                    _NavyAmountCol(
                      'Balance',
                      '₹${f.balanceAmount.toStringAsFixed(0)}',
                      const Color(0xFFFF8A8A),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Fee Details Card ──
          _SectionCard(
            title: 'Fee Details',
            children: [
              _InfoRow('Academic Year', f.academicYear),
              _InfoRow('Semester', f.semester),
              _InfoRow('Fee Category', f.feeCategory),
              if (f.dueDate != null) _InfoRow('Due Date', f.dueDate!),
              if (f.remarks != null && f.remarks!.isNotEmpty)
                _InfoRow('Remarks', f.remarks!),
            ],
          ),

          const SizedBox(height: 16),

          // ── Parent Reminder ──
          if (f.paymentStatus != 'PAID')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TeacherColors.warning.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: TeacherColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Parent Reminder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: TeacherColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"Dear Parent,\nThe semester fee for ${f.studentName} (${f.studentId}) is ${_statusLabel(f.paymentStatus)}.\n'
                    'Due Date: ${f.dueDate ?? "N/A"}\nOutstanding Amount: ₹${f.balanceAmount.toStringAsFixed(0)}\n\n'
                    'Please complete the payment at the earliest."',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TeacherColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ReminderBtn(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        onTap: () => _showComingSoon(context, 'Email'),
                      ),
                      const SizedBox(width: 8),
                      _ReminderBtn(
                        icon: Icons.sms_outlined,
                        label: 'SMS',
                        onTap: () => _showComingSoon(context, 'SMS'),
                      ),
                      const SizedBox(width: 8),
                      _ReminderBtn(
                        icon: Icons.message_outlined,
                        label: 'WhatsApp',
                        onTap: () => _showComingSoon(context, 'WhatsApp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ── Payment History ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment History', style: TeacherTextStyles.heading3),
              if (_loadingPayments)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TeacherColors.navy,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (!_loadingPayments && _payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: TeacherDecorations.card(radius: 12),
              child: const Center(
                child: Text(
                  'No payment records found.',
                  style: TextStyle(color: TeacherColors.textMuted),
                ),
              ),
            ),

          ..._payments
              .where(
                (p) =>
                    p.academicYear == widget.fee.academicYear &&
                    p.semester == widget.fee.semester,
              )
              .map((p) => _PaymentTile(payment: p)),
        ],
      ),
    );
  }

  Widget _navyDiv() => Container(width: 1, height: 36, color: Colors.white24);

  void _showComingSoon(BuildContext ctx, String service) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          '$service reminders will be available in the next release.',
        ),
        backgroundColor: TeacherColors.info,
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext ctx) {
    final amountCtrl = TextEditingController();
    final txnCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String mode = 'ONLINE';
    final modes = ['CASH', 'ONLINE', 'UPI', 'NEFT', 'DD', 'CHEQUE'];

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (bCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24,
            ),
            child: StatefulBuilder(
              builder:
                  (_, setModal) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TeacherColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Max payable: ₹${widget.fee.balanceAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: TeacherColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: mode,
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          isDense: true,
                        ),
                        items:
                            modes
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setModal(() => mode = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: txnCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Transaction ID (optional)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Remarks (optional)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount =
                                double.tryParse(amountCtrl.text) ?? 0;
                            if (amount <= 0 ||
                                amount > widget.fee.balanceAmount) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid amount.'),
                                  backgroundColor: TeacherColors.danger,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(bCtx);
                            final ok = await _api.recordPayment({
                              'studentId': widget.fee.studentId,
                              'studentFeeId': widget.fee.studentFeeId,
                              'amountPaid': amount,
                              'paymentDate': DateTime.now()
                                  .toIso8601String()
                                  .substring(0, 10),
                              'paymentMode': mode,
                              'transactionId': txnCtrl.text.trim(),
                              'remarks': remarksCtrl.text.trim(),
                              'recordedBy': widget.employeeId,
                              'academicYear': widget.fee.academicYear,
                              'semester': widget.fee.semester,
                              'feeCategory': widget.fee.feeCategory,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Payment recorded successfully.'
                                        : 'Failed to record payment.',
                                  ),
                                  backgroundColor:
                                      ok
                                          ? TeacherColors.success
                                          : TeacherColors.danger,
                                ),
                              );
                              if (ok) {
                                _loadPayments();
                                widget.onPaymentRecorded?.call();
                              }
                            }
                          },
                          child: const Text('Record Payment'),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _NavyAmountCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NavyAmountCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: TeacherDecorations.card(radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TeacherTextStyles.heading3),
        const Divider(height: 16),
        ...children,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TeacherTextStyles.bodyMuted),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}

class _ReminderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ReminderBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TeacherColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TeacherColors.warning),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: TeacherColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentTile extends StatelessWidget {
  final FeePaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: TeacherDecorations.card(radius: 12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TeacherColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: TeacherColors.success,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${payment.amountPaid.toStringAsFixed(0)} Paid',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${payment.paymentMode ?? ''} · ${payment.paymentDate}'
                '${payment.transactionId != null && payment.transactionId!.isNotEmpty ? '  ·  TxnID: ${payment.transactionId}' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: TeacherColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
