import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'student_management.dart';
import 'admin_fees_entry_screen.dart';

class StudentSectionDashboardScreen extends StatelessWidget {
  final String departmentId, departmentName, yearId;
  final bool isFeeMode;
  const StudentSectionDashboardScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
    required this.yearId,
    this.isFeeMode = false,
  });

  static const List<Map<String, dynamic>> _sections = [
    {
      'id': 'A',
      'name': 'Section A',
      'icon': Icons.group_outlined,
      'color': ErpColors.attendance,
      'surface': ErpColors.attendanceSurface,
    },
    {
      'id': 'B',
      'name': 'Section B',
      'icon': Icons.group_add_outlined,
      'color': ErpColors.info,
      'surface': ErpColors.infoSurface,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: '$departmentId — Year $yearId',
        subtitle: departmentName,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ErpSectionHeader(
              title: 'Select Class Section',
              subtitle: 'Tap a section to view and manage students',
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: _sections.length,
                itemBuilder: (ctx, i) {
                  final s = _sections[i];
                  return ErpCard(
                    onTap:
                        () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    isFeeMode
                                        ? AdminFeesEntryScreen(
                                          lockedDept: departmentId,
                                          lockedYear: yearId,
                                          lockedSec: s['id'] as String,
                                        )
                                        : StudentManagementScreen(
                                          lockedDepartment: departmentId,
                                          lockedYear: yearId,
                                          lockedSection: s['id'] as String,
                                        ),
                          ),
                        ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: s['surface'] as Color,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                          ),
                          child: Icon(
                            s['icon'] as IconData,
                            size: 34,
                            color: s['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s['name'] as String,
                          style: ErpTypography.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Year $yearId · $departmentId',
                          style: ErpTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
