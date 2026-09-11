import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../services/admin_id_card_service.dart';
import '../../teacher/models/teacher_id_card_model.dart';
import '../../models/bus_pass_model.dart';
import '../../teacher/widgets/teacher_id_card.dart';
import '../../teacher/widgets/teacher_bus_pass.dart';

class AdminIdCardScreen extends StatefulWidget {
  final String employeeId;
  const AdminIdCardScreen({super.key, required this.employeeId});

  @override
  State<AdminIdCardScreen> createState() => _AdminIdCardScreenState();
}

class _AdminIdCardScreenState extends State<AdminIdCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminIdCardService _idCardService = AdminIdCardService();

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
      final card = await _idCardService.getAdminIdCard(widget.employeeId);
      final pass = await _idCardService.getAdminBusPass(widget.employeeId);
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
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        title: Text(
          'Admin Documents',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: ErpColors.primary,
            child: TabBar(
              controller: _tabController,
              labelColor: ErpColors.accent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: ErpColors.accent,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
                child: CircularProgressIndicator(color: ErpColors.primary),
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
      return Center(
        child: Text(
          "Admin ID Card not available",
          style: GoogleFonts.outfit(color: Colors.white54),
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
      return Center(
        child: Text(
          "Admin Bus Pass not available",
          style: GoogleFonts.outfit(color: Colors.white54),
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
              backgroundColor: const Color(0xFF6C63FF),
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
                        ? 'Admin ID Card downloaded (mock)'
                        : 'Admin Bus Pass downloaded (mock)',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded),
            label: Text('Download', style: GoogleFonts.outfit()),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
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
            label: Text('Share', style: GoogleFonts.outfit()),
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
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = "";
                });
                _fetchData();
              },
              child: Text('Retry', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ),
    );
  }
}
