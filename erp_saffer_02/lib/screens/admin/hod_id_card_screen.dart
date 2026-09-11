import 'package:flutter/material.dart';
import '../../services/hod_id_card_service.dart';
import '../../teacher/models/teacher_id_card_model.dart';
import '../../models/bus_pass_model.dart';
import '../../teacher/widgets/teacher_id_card.dart';
import '../../teacher/widgets/teacher_bus_pass.dart';
import '../../theme/app_theme.dart';

class HodIdCardScreen extends StatefulWidget {
  final String employeeId;
  const HodIdCardScreen({super.key, required this.employeeId});

  @override
  State<HodIdCardScreen> createState() => _HodIdCardScreenState();
}

class _HodIdCardScreenState extends State<HodIdCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HodIdCardService _idCardService = HodIdCardService();

  TeacherIdCardModel? _idCard;
  BusPassModel? _busPass;
  bool _loading = true;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final card = await _idCardService.getHodIdCard(widget.employeeId);
      final pass = await _idCardService.getHodBusPass(widget.employeeId);
      setState(() {
        _idCard = card;
        _busPass = pass;
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
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: const Text('HOD Documents'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.navy,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.brass,
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
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.brass),
              )
              : _error.isNotEmpty
              ? _buildErrorView()
              : TabBarView(
                controller: _tabController,
                children: [_buildIdCardTab(), _buildBusPassTab()],
              ),
    );
  }

  Widget _buildIdCardTab() {
    if (_idCard == null) {
      return const Center(
        child: Text(
          "HOD ID Card not available",
          style: TextStyle(color: AppColors.inkMuted),
        ),
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
      return const Center(
        child: Text(
          "HOD Bus Pass not available",
          style: TextStyle(color: AppColors.inkMuted),
        ),
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
                        ? 'HOD ID Card downloaded (mock)'
                        : 'HOD Bus Pass downloaded (mock)',
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = "";
                });
                _fetchData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
