import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'department_assignment_screen.dart';

class AdminAssignmentDashboardScreen extends StatelessWidget {
  const AdminAssignmentDashboardScreen({super.key});

  static const List<Map<String, dynamic>> _departments = [
    {
      'id': 'CSE',
      'name': 'Computer Science & Engineering',
      'icon': Icons.computer_outlined,
      'color': ErpColors.info,
      'surface': ErpColors.infoSurface,
    },
    {
      'id': 'ECE',
      'name': 'Electronics & Communication',
      'icon': Icons.memory_outlined,
      'color': ErpColors.attendance,
      'surface': ErpColors.attendanceSurface,
    },
    {
      'id': 'EEE',
      'name': 'Electrical & Electronics',
      'icon': Icons.electrical_services_outlined,
      'color': ErpColors.fees,
      'surface': ErpColors.feesSurface,
    },
    {
      'id': 'MECH',
      'name': 'Mechanical Engineering',
      'icon': Icons.settings_outlined,
      'color': ErpColors.warning,
      'surface': ErpColors.warningSurface,
    },
    {
      'id': 'CIVIL',
      'name': 'Civil Engineering',
      'icon': Icons.architecture_outlined,
      'color': ErpColors.library,
      'surface': ErpColors.librarySurface,
    },
    {
      'id': 'AIDS',
      'name': 'AI & Data Science',
      'icon': Icons.psychology_outlined,
      'color': ErpColors.results,
      'surface': ErpColors.resultsSurface,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(
        title: 'Teacher Assignment Hub',
        subtitle: 'Manage subject & incharge allocations',
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ErpSectionHeader(
              title: 'Select Department',
              subtitle:
                  'Choose a department to manage subject and class incharge assignments',
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                itemCount: _departments.length,
                itemBuilder: (ctx, i) {
                  final d = _departments[i];
                  return ErpCard(
                    onTap:
                        () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder:
                                (_) => DepartmentAssignmentScreen(
                                  departmentId: d['id'] as String,
                                  departmentName: d['name'] as String,
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
                            color: d['surface'] as Color,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                          ),
                          child: Icon(
                            d['icon'] as IconData,
                            size: 30,
                            color: d['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          d['id'] as String,
                          style: ErpTypography.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d['name'] as String,
                          style: ErpTypography.caption,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
