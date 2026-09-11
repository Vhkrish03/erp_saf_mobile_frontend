import 'package:flutter/material.dart';
import '../models/student_id_card_model.dart';
import '../models/bus_pass_model.dart';
import '../services/student_id_card_service.dart';
import '../widgets/student_id_card.dart';
import '../widgets/student_bus_pass.dart';
import '../theme/app_theme.dart';
import '../core/design_system.dart';

class StudentIdCardScreen extends StatefulWidget {
  final String studentId;
  const StudentIdCardScreen({super.key, required this.studentId});

  @override
  State<StudentIdCardScreen> createState() => _StudentIdCardScreenState();
}

class _StudentDocumentsSkeleton extends StatelessWidget {
  const _StudentDocumentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 260, radius: 18),
        SizedBox(height: 24),
        ErpSkeleton(width: 180, height: 48, radius: 12),
      ],
    );
  }
}

class _StudentIdCardScreenState extends State<StudentIdCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentIdCardService _service = StudentIdCardService();

  StudentIdCardModel? _idCard;
  BusPassModel? _busPass;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        _service.getStudentIdCard(widget.studentId),
        _service.getStudentBusPass(widget.studentId),
      ]);
      setState(() {
        _idCard = results[0] as StudentIdCardModel;
        _busPass = results[1] as BusPassModel;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        title: const Text('Digital Documents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: ErpColors.primary,
              unselectedLabelColor: ErpColors.textMuted,
              indicatorColor: ErpColors.accent,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.badge_outlined), text: 'ID Card'),
                Tab(
                  icon: Icon(Icons.directions_bus_outlined),
                  text: 'Bus Pass',
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _loading
              ? const _StudentDocumentsSkeleton()
              : _error.isNotEmpty
              ? ErpErrorState(
                message: 'We could not retrieve your digital documents right now.',
                onRetry: _loadData,
              )
              : TabBarView(
                controller: _tabController,
                children: [_buildIdCardTab(), _buildBusPassTab()],
              ),
    );
  }

  Widget _buildIdCardTab() {
    if (_idCard == null) {
      return const ErpEmptyState(
        message: 'ID Card unavailable',
        subtitle: 'Your digital ID card has not been issued yet.',
        icon: Icons.badge_outlined,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          StudentIdCard(cardModel: _idCard!),
          const SizedBox(height: 24),
          _buildActionButtons(isIdCard: true),
        ],
      ),
    );
  }

  Widget _buildBusPassTab() {
    if (_busPass == null) {
      return const ErpEmptyState(
        message: 'Bus Pass unavailable',
        subtitle: 'Your digital bus pass has not been issued yet.',
        icon: Icons.directions_bus_outlined,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          StudentBusPass(passModel: _busPass!),
          const SizedBox(height: 24),
          _buildActionButtons(isIdCard: false),
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool isIdCard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isIdCard
                        ? 'ID Card downloaded successfully (mock)'
                        : 'Bus Pass downloaded successfully (mock)',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document shared successfully (mock)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

}
