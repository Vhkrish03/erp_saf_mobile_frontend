import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'student_section_dashboard.dart';

class StudentYearDashboardScreen extends StatelessWidget {
  final String departmentId, departmentName;
  final bool isFeeMode;
  const StudentYearDashboardScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
    this.isFeeMode = false,
  });

  static const List<Map<String, dynamic>> _years = [
    {'id': '1', 'name': '1st Year', 'icon': Icons.filter_1_rounded},
    {'id': '2', 'name': '2nd Year', 'icon': Icons.filter_2_rounded},
    {'id': '3', 'name': '3rd Year', 'icon': Icons.filter_3_rounded},
    {'id': '4', 'name': '4th Year', 'icon': Icons.filter_4_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: ErpAppBar(
        title: '$departmentId — Batches',
        subtitle: departmentName,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ErpSectionHeader(
              title: 'Select Academic Year',
              subtitle: 'Choose a batch to manage students',
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: _years.length,
                itemBuilder: (ctx, i) {
                  final y = _years[i];
                  return ErpCard(
                    onTap:
                        () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder:
                                (_) => StudentSectionDashboardScreen(
                                  departmentId: departmentId,
                                  departmentName: departmentName,
                                  yearId: y['id'] as String,
                                  isFeeMode: isFeeMode,
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
                            color: ErpColors.infoSurface,
                            borderRadius: BorderRadius.circular(ErpRadius.md),
                          ),
                          child: Icon(
                            y['icon'] as IconData,
                            size: 34,
                            color: ErpColors.info,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          y['name'] as String,
                          style: ErpTypography.headlineSmall,
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
