import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/teacher_id_card_model.dart';
import '../../models/bus_pass_model.dart';
import '../services/teacher_id_card_service.dart';
import '../widgets/teacher_id_card.dart';
import '../widgets/teacher_bus_pass.dart';

// Named IdCardTeacherColors to avoid naming clash with global TeacherColors definitions
class IdCardTeacherColors {
  static const Color navy = Color(0xFF0F2B5C);
  static const Color accent = Color(0xFFD44C26);
  static const Color danger = Color(0xFFD32F2F);
  static const Color textSecondary = Colors.black54;
}

class TeacherIdCardScreen extends StatefulWidget {
  final String employeeId;
  const TeacherIdCardScreen({super.key, required this.employeeId});

  @override
  State<TeacherIdCardScreen> createState() => _TeacherIdCardScreenState();
}

class _TeacherIdCardScreenState extends State<TeacherIdCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeacherIdCardService _service = TeacherIdCardService();

  TeacherIdCardModel? _idCard;
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
        _service.getTeacherIdCard(widget.employeeId),
        _service.getTeacherBusPass(widget.employeeId),
      ]);
      setState(() {
        _idCard = results[0] as TeacherIdCardModel;
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
        title: const Text('Staff Documents'),
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: ErpColors.primary,
            child: TabBar(
              controller: _tabController,
              labelColor: ErpColors.accent,
              unselectedLabelColor: Colors.white70,
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
              ? const _TeacherDocumentsSkeleton()
              : _error.isNotEmpty
                  ? ErpErrorState(
                    message: 'We could not retrieve your staff documents right now.',
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
        subtitle: 'Your staff ID card has not been issued yet.',
        icon: Icons.badge_outlined,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          TeacherIdCard(cardModel: _idCard!),
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
        subtitle: 'Your staff bus pass has not been issued yet.',
        icon: Icons.directions_bus_outlined,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          TeacherBusPass(passModel: _busPass!),
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
              backgroundColor: IdCardTeacherColors.navy,
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
                        ? 'Staff ID Card downloaded (mock)'
                        : 'Staff Bus Pass downloaded (mock)',
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
              foregroundColor: IdCardTeacherColors.navy,
              side: const BorderSide(color: IdCardTeacherColors.navy),
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

class _TeacherDocumentsSkeleton extends StatelessWidget {
  const _TeacherDocumentsSkeleton();

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
