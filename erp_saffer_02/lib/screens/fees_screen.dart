import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../core/design_system.dart';
import '../services/fee_service.dart';
import '../models/fee_model.dart';
import '../services/student_service.dart';
import '../models/student.dart';

class FeesScreen extends StatefulWidget {
  final String? studentId;
  const FeesScreen({super.key, this.studentId});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

// Global list and service for backward compatibility with Dashboard Screen
final FeeService feeService = FeeService();
List<Fee> feeItems = [];

class _FeesScreenState extends State<FeesScreen> {
  final StudentService _studentService = StudentService();

  bool _isLoading = true;
  String? _error;
  String _activeTab = "Due"; // "Due" | "History"

  Student? _student;
  List<Fee> _backendFees = [];
  List<FeePayment> _paymentHistory = [];
  List<Map<String, dynamic>> _tableRows = [];

  // PDF Download Animation State
  bool _isDownloadingPdf = false;
  double _downloadProgress = 0.0;
  String _downloadingFileName = "";

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final studentId = widget.studentId ?? "STU25";
    try {
      _student = await _studentService.getStudent(studentId);
      _backendFees = await feeService.getFees(studentId);
      _paymentHistory = await feeService.getPaymentHistory(studentId);

      initTableRows();
      _syncGlobalFeeItems();
    } catch (e) {
      _error = 'We could not retrieve fee information right now.';
      print("Error loading fee data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void initTableRows() {
    _tableRows = [];
    if (_backendFees.isEmpty) {
      return;
    }

    int index = 1;
    for (var fee in _backendFees) {
      final ordinals = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"];
      String installment =
          index <= ordinals.length ? ordinals[index - 1] : "${index}th";

      _tableRows.add({
        "installment": installment,
        "details": fee.particular,
        "due": fee.amount,
        "paid": fee.amountPaid,
        "dueDate": fee.dueDate,
        "studentFeeId": fee.studentFeeId,
      });
      index++;
    }
  }

  void _syncGlobalFeeItems() {
    feeItems =
        _tableRows.map((row) {
          final double due = row["due"] as double;
          final double paid = row["paid"] as double;
          return Fee(
            studentFeeId: row["studentFeeId"] as int?,
            particular: row["details"],
            amount: due,
            amountPaid: paid,
            balanceAmount: due - paid,
            isPaid: paid >= due,
            dueDate: row["dueDate"] ?? "",
          );
        }).toList();
  }

  Future<void> _processPayment({
    required int studentFeeId,
    required String category,
    required double amountToPay,
    required String method,
  }) async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final txnId = "TXN${now.millisecondsSinceEpoch.toString().substring(4)}";

      await feeService.recordPayment(
        studentFeeId: studentFeeId,
        studentId: widget.studentId ?? "STU25",
        amountPaid: amountToPay,
        paymentDate: dateStr,
        paymentMode: method.toUpperCase(),
        transactionId: txnId,
        remarks: "Online payment for $category",
        recordedBy: "STUDENT",
        academicYear:
            _backendFees.isNotEmpty
                ? _backendFees.first.academicYear
                : "2026-27",
        semester: _student?.semester ?? "Semester V",
        feeCategory: category,
      );

      // Refresh consolidated data from server
      await loadAllData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Payment of ₹${amountToPay.toStringAsFixed(0)} for $category was successful!",
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // Fallback mock payment simulation if backend is unavailable/offline
      setState(() {
        final now = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        final txnId =
            "TXN${now.millisecondsSinceEpoch.toString().substring(4)}";

        _paymentHistory.insert(
          0,
          FeePayment(
            id: now.millisecondsSinceEpoch % 100000,
            studentId: widget.studentId ?? "STU25",
            amountPaid: amountToPay,
            paymentDate: dateStr,
            paymentMode: method.toUpperCase(),
            transactionId: txnId,
            remarks: "Local offline payment for $category",
            feeCategory: category,
            academicYear: "2026-27",
            semester: _student?.semester ?? "Semester V",
          ),
        );

        for (var row in _tableRows) {
          if (row["details"] == category) {
            double currentPaid = row["paid"] as double;
            row["paid"] = currentPaid + amountToPay;
            break;
          }
        }
        _syncGlobalFeeItems();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Offline simulation: Payment of ₹${amountToPay.toStringAsFixed(0)} for $category recorded.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double getTotalDue() =>
      _tableRows.fold<double>(0.0, (a, b) => a + (b["due"] as double));
  double getTotalPaid() =>
      _tableRows.fold<double>(0.0, (a, b) => a + (b["paid"] as double));

  void _triggerPdfDownload(String referenceId, String type) {
    setState(() {
      _isDownloadingPdf = true;
      _downloadProgress = 0.0;
      _downloadingFileName =
          type == "receipt" ? "Receipt_$referenceId.pdf" : "Fee_Statements.pdf";
    });

    int step = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false;
      step += 10;
      setState(() {
        _downloadProgress = step / 100.0;
      });
      if (step >= 100) {
        setState(() {
          _isDownloadingPdf = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Downloaded $_downloadingFileName to device Storage",
                  ),
                ),
              ],
            ),
          ),
        );
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: ErpAppBar(title: 'Academic Fees'),
        body: _FeesSkeleton(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: const ErpAppBar(title: 'Academic Fees'),
        body: ErpErrorState(message: _error!, onRetry: loadAllData),
      );
    }

    final double total = getTotalDue();
    final double paid = getTotalPaid();
    final double due = total - paid;
    final double progress = total == 0 ? 0.0 : paid / total;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.parchment,
          appBar: AppBar(title: const Text('Academic Fees')),
          body: Column(
            children: [
              // Segment selector
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton("Due Summary", "Due")),
                      Expanded(
                        child: _buildTabButton("Receipts History", "History"),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_activeTab == "Due") ...[
                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_student?.semester ?? "Semester V"} Fee Consolidated Status',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              due > 0
                                  ? '₹${due.toStringAsFixed(0)} Outstanding'
                                  : 'Consolidated Fully Paid',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.15,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.brass,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '₹${paid.toStringAsFixed(0)} Paid of ₹${total.toStringAsFixed(0)} Total Plan (${(progress * 100).toStringAsFixed(0)}%)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fees Table
                      _buildDueTable(),
                      const SizedBox(height: 8),

                      // Payment Actions Row
                      _buildPaymentCards(due),
                    ] else ...[
                      // Payment History View
                      _buildHistoryHeader(),
                      const SizedBox(height: 12),
                      _buildHistoryList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // PDF Generation Overlay
        if (_isDownloadingPdf)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text(
                          "Generating Secure PDF Receipt...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _downloadingFileName,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${(_downloadProgress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, String value) {
    final bool active = _activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = value),
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.inkMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDueTable() {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Headers
          Container(
            color: AppColors.navyLight,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Installment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Due",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Pay Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table Data Rows
          if (_tableRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No outstanding fees allocated.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Institution administrative staff haven't added fees for this block.",
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_tableRows.length, (idx) {
              final row = _tableRows[idx];
              final double due = row["due"] as double;
              final double paid = row["paid"] as double;
              final isEven = idx % 2 == 0;

              Widget payColWidget;
              if (paid >= due) {
                payColWidget = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Paid (₹${paid.toStringAsFixed(0)})",
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                );
              } else if (paid > 0) {
                payColWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Part: ₹${paid.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Due: ₹${(due - paid).toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              } else {
                payColWidget = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Not Paid (₹0)",
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      isEven
                          ? Colors.white
                          : AppColors.parchment.withValues(alpha: 0.25),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        row["installment"],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        row["details"],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "₹${due.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: payColWidget,
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Total aggregate row
          Container(
            color: AppColors.divider.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                const Expanded(
                  flex: 4,
                  child: Text(
                    "Total",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "₹${getTotalDue().toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                      fontSize: 13.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    getTotalPaid() >= getTotalDue()
                        ? "Fully Settled"
                        : "Ours: ₹${(getTotalDue() - getTotalPaid()).toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          getTotalPaid() >= getTotalDue()
                              ? AppColors.success
                              : AppColors.moduleFees,
                      fontSize: 12.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCards(double due) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Payment Channels",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: AppColors.navy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Pay Online",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Pay directly through creditcard/debitcard, net banking, or UPI channels.",
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            due <= 0 ? null : () => _showPayNowSheet(due),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          "Pay Now",
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brass.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.brass,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Monthly EMI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Split outstanding balances into 3, 6, or 9 months interest free auto debits.",
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            due <= 0 ? null : () => _showEMISetupSheet(due),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brass,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          "Setup EMI",
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Receipt Statement Reports",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  fontSize: 13.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Consolidated logs for all transaction records",
                style: TextStyle(fontSize: 10.5, color: AppColors.inkMuted),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _triggerPdfDownload("ALL", "consolidated"),
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.danger,
            ),
            tooltip: "Download PDF Statement",
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final list =
        _paymentHistory.isNotEmpty ? _paymentHistory : _getDummyPayments();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = list[index];
        return Card(
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outlined,
                color: AppColors.success,
                size: 20,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Receipt: #${p.id}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  "₹${p.amountPaid.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Date: ${p.paymentDate} · ${p.paymentMode}",
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  p.remarks.isEmpty ? "Payment Settlement" : p.remarks,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            trailing: InkWell(
              onTap: () => _showReceiptModal(p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: AppColors.navy,
                  size: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<FeePayment> _getDummyPayments() {
    return [
      FeePayment(
        id: 48920,
        studentId: widget.studentId ?? "STU25",
        amountPaid: 40000.0,
        paymentDate: "2026-08-10",
        paymentMode: "ONLINE - CARD",
        transactionId: "TXN10284910283",
        remarks: "1st Installment Tuition Fee",
        feeCategory: "Tuition Fee",
        academicYear: "2026-27",
        semester: _student?.semester ?? "Semester V",
      ),
      FeePayment(
        id: 48214,
        studentId: widget.studentId ?? "STU25",
        amountPaid: 10000.0,
        paymentDate: "2026-07-28",
        paymentMode: "ONLINE - UPI",
        transactionId: "TXN47102938122",
        remarks: "Hostel/Mess Deposit Fee",
        feeCategory: "Mess Fee",
        academicYear: "2026-27",
        semester: _student?.semester ?? "Semester V",
      ),
      FeePayment(
        id: 47910,
        studentId: widget.studentId ?? "STU25",
        amountPaid: 3000.0,
        paymentDate: "2026-07-15",
        paymentMode: "ONLINE - NET BANKING",
        transactionId: "TXN84920492811",
        remarks: "Library & Other Activity Fee",
        feeCategory: "Other Fee",
        academicYear: "2026-27",
        semester: _student?.semester ?? "Semester V",
      ),
    ];
  }

  void _showPayNowSheet(double balance) {
    bool loading = false;
    String loadMsg = "";

    final unpaidItems =
        _tableRows.where((row) {
          final double due = row["due"] as double;
          final double paid = row["paid"] as double;
          return (due - paid) > 0;
        }).toList();

    Map<String, dynamic>? selectedPaymentRow =
        unpaidItems.isNotEmpty ? unpaidItems.first : null;
    final amountCtrl = TextEditingController(
      text:
          selectedPaymentRow != null
              ? ((selectedPaymentRow["due"] as double) -
                      (selectedPaymentRow["paid"] as double))
                  .toStringAsFixed(0)
              : "0",
    );
    final modalFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cardCtrl = TextEditingController(text: "4829 4010 3982 9102");
            final expCtrl = TextEditingController(text: "12/29");
            final cvvCtrl = TextEditingController(text: "812");
            final nameCtrl = TextEditingController(
              text: _student?.name ?? "STUDENT USER",
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: modalFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Gateway Instant Pay",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.navy,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (loading) ...[
                        const SizedBox(height: 40),
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            loadMsg,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ] else ...[
                        const Text(
                          "Select Fee Category to Pay",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedPaymentRow,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              unpaidItems.map((row) {
                                double catRemaining =
                                    (row["due"] as double) -
                                    (row["paid"] as double);
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: row,
                                  child: Text(
                                    "${row['details']} (Remaining: ₹${catRemaining.toStringAsFixed(0)})",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (newRow) {
                            setModalState(() {
                              selectedPaymentRow = newRow;
                              if (newRow != null) {
                                double remaining =
                                    (newRow["due"] as double) -
                                    (newRow["paid"] as double);
                                amountCtrl.text = remaining.toStringAsFixed(0);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Amount to Pay (₹)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            hintText: "Enter amount to pay",
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return "Please enter amount";
                            final amt = double.tryParse(val);
                            if (amt == null || amt <= 0)
                              return "Please enter a valid amount";
                            if (selectedPaymentRow != null) {
                              double limit =
                                  (selectedPaymentRow!["due"] as double) -
                                  (selectedPaymentRow!["paid"] as double);
                              if (amt > limit)
                                return "Amount cannot exceed outstanding ₹${limit.toStringAsFixed(0)}";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.navy, AppColors.navyLight],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "DEBIT RECEIPT CARD",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.contactless,
                                    color: Colors.white60,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                "•••• •••• •••• 9102",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    nameCtrl.text.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Text(
                                    "12/29",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: cardCtrl,
                          decoration: const InputDecoration(
                            labelText: "Card Number",
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: expCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Expiry Date (MM/YY)",
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: cvvCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: "CVV",
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (!modalFormKey.currentState!.validate()) return;
                            if (selectedPaymentRow == null) return;

                            final double amountToPay = double.parse(
                              amountCtrl.text,
                            );
                            final int? studentFeeId =
                                selectedPaymentRow!["studentFeeId"] as int?;
                            final String category =
                                selectedPaymentRow!["details"] as String;

                            setModalState(() {
                              loading = true;
                              loadMsg = "Contacting Secure Bank Server...";
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              if (!context.mounted) return;
                              setModalState(
                                () =>
                                    loadMsg =
                                        "Processing payment authentication...",
                              );
                              Future.delayed(const Duration(seconds: 1), () {
                                if (!context.mounted) return;
                                if (studentFeeId != null) {
                                  Navigator.pop(context);
                                  _processPayment(
                                    studentFeeId: studentFeeId,
                                    category: category,
                                    amountToPay: amountToPay,
                                    method: "ONLINE - CARD",
                                  );
                                } else {
                                  Navigator.pop(context);
                                  _processPayment(
                                    studentFeeId: -1,
                                    category: category,
                                    amountToPay: amountToPay,
                                    method: "ONLINE - CARD",
                                  );
                                }
                              });
                            });
                          },
                          child: const Text("Authenticate & Pay"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEMISetupSheet(double balance) {
    int selectedMonths = 3;
    double monthlyInstallment = balance / 3;
    bool loading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "0% Interest EMI Scheme",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.navy,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (loading) ...[
                      const SizedBox(height: 40),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          "Configuring Instant Installments...",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ] else ...[
                      const Text(
                        "Configure interest-free installments via academic banking systems (HDFC/Eduvanz). You pay the first installment now.",
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children:
                            [3, 6, 9].map((m) {
                              final selected = selectedMonths == m;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedMonths = m;
                                      monthlyInstallment = balance / m;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? AppColors.navy
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            selected
                                                ? AppColors.navy
                                                : AppColors.divider,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "$m Months",
                                      style: TextStyle(
                                        color:
                                            selected
                                                ? Colors.white
                                                : AppColors.navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Monthly Auto-Debit",
                                  style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Processing Fee",
                                  style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${monthlyInstallment.toStringAsFixed(0)}/mo",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "₹0 (Zero Cost)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () {
                          setModalState(() => loading = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (!context.mounted) return;
                            final unpaid = _tableRows.firstWhere(
                              (row) =>
                                  ((row["due"] as double) -
                                      (row["paid"] as double)) >
                                  0,
                              orElse: () => <String, dynamic>{},
                            );
                            final int sFeeId =
                                unpaid.containsKey("studentFeeId")
                                    ? (unpaid["studentFeeId"] as int? ?? -1)
                                    : -1;
                            final String cat =
                                unpaid.containsKey("details")
                                    ? (unpaid["details"] as String)
                                    : "EMI Plan Setup";

                            _processPayment(
                              studentFeeId: sFeeId,
                              category: cat,
                              amountToPay: monthlyInstallment,
                              method: "EMI - STAGE 1",
                            );
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder:
                                  (c) => AlertDialog(
                                    title: const Text("EMI Plan Established"),
                                    content: Text(
                                      "Your $selectedMonths-month EMI setup is complete. ₹${monthlyInstallment.toStringAsFixed(0)} has been processed as the 1st installment.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text("Okay"),
                                      ),
                                    ],
                                  ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brass,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          "Pay 1st Installment (₹${monthlyInstallment.toStringAsFixed(0)})",
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiptModal(FeePayment payment) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: AppColors.navy,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SAFFER ENG COLLEGE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "Affiliated to AU · AICTE Approved",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              Text(
                                "Receipt Branch Office, Chennai - 25",
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RECEIPT ID: SEC-${payment.id}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "DATE: ${payment.paymentDate}",
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "TXN ID: ${payment.transactionId}",
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReceiptField(
                            "STUDENT:",
                            _student?.name ?? "STUDENT USER",
                          ),
                          _buildReceiptField(
                            "ID / ROLL:",
                            "${_student?.id ?? 'STU25'} / ${_student?.rollNumber ?? '2026SEC05'}",
                          ),
                          _buildReceiptField(
                            "PROGRAM:",
                            "${_student?.department ?? 'CSE'} · ${_student?.semester ?? 'Semester V'}",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "FEE PARTICULARS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          payment.remarks.isEmpty
                              ? "Particular Fee Settlement"
                              : payment.remarks,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        Text(
                          "₹${payment.amountPaid.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Paid Total (Net):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "₹${payment.amountPaid.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PAYMENT MODE: ${payment.paymentMode}",
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "STATUS: SUCCESS / COMPLETED",
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.brass.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "SEAL",
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brass,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Authorized Sign",
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Close",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _triggerPdfDownload(payment.id.toString(), "receipt");
                        },
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Download PDF",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeesSkeleton extends StatelessWidget {
  const _FeesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(width: double.infinity, height: 48, radius: 12),
        SizedBox(height: 16),
        ErpSkeleton(height: 152, radius: 16),
        SizedBox(height: 20),
        ErpSkeleton(height: 180, radius: 16),
        SizedBox(height: 12),
        ErpSkeleton(height: 180, radius: 16),
      ],
    );
  }
}
