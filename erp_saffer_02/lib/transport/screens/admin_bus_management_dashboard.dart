import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import 'admin_manage_drivers.dart';
import 'admin_manage_routes.dart';
import 'admin_manage_buses.dart';
import 'admin_student_assignments.dart';
import 'admin_live_tracking.dart';

class AdminBusManagementDashboardScreen extends StatelessWidget {
  const AdminBusManagementDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(title: 'Transport Management Hub'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrative Controls',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ErpColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage fleet operations, route planning, student bus allocations, and mock real-time GPS telemetry broadcasts.',
              style: GoogleFonts.outfit(
                color: ErpColors.textMuted,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuCard(
                  context,
                  title: 'Buses Fleet',
                  desc: 'Register vehicles, assign drivers, and map routes.',
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF6C63FF),
                  screen: const AdminManageBusesScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: 'Drivers',
                  desc: 'Add personnel, license metrics, and status tracking.',
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF00D68F),
                  screen: const AdminManageDriversScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: 'Routes & Stops',
                  desc: 'Define travel legs and sequence bus stop coordinates.',
                  icon: Icons.map_outlined,
                  color: const Color(0xFFFFB703),
                  screen: const AdminManageRoutesScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: 'Assignments',
                  desc: 'Match day scholars to buses with capacity checks.',
                  icon: Icons.assignment_ind_outlined,
                  color: const Color(0xFFF72585),
                  screen: const AdminStudentAssignmentsScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: 'GPS Simulator',
                  desc:
                      'Simulate location updates directly to standard tables.',
                  icon: Icons.gps_fixed_rounded,
                  color: const Color(0xFF3A86FF),
                  screen: const AdminLiveTrackingScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ErpColors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ErpColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: ErpColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
