import 'package:flutter/material.dart';
import '../../models/bus_pass_model.dart';
import '../../widgets/student_id_card.dart'; // QrCodePainter

class TeacherBusPass extends StatelessWidget {
  final BusPassModel passModel;
  const TeacherBusPass({super.key, required this.passModel});

  @override
  Widget build(BuildContext context) {
    final bool isValid = passModel.status.toUpperCase() == 'VALID';

    return Center(
      child: Container(
        width: 330,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0F2B5C), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Transport Pass Header
            Container(
              color: const Color(0xFF0F2B5C),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'KARPAGA VINAYAGA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    'STAFF TRANSPORT PASS',
                    style: TextStyle(
                      color: Color(0xFFE65A28),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isValid
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isValid ? 'VALID STAFF PASS' : 'EXPIRED STAFF PASS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pass Metadata Banner
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PASS NO: ${passModel.passNumber}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AY: ${passModel.academicYear}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Teacher Photo & Core Details Row
                    Row(
                      children: [
                        Container(
                          width: 76,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passModel.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F2B5C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Employee ID: ${passModel.rollNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Designation: ${passModel.designation}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dept: ${passModel.department}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Route Detail Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2B5C).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0F2B5C).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'ROUTE',
                            passModel.route.toUpperCase(),
                          ),
                          const Divider(height: 12),
                          _buildDetailRow(
                            'PICKUP POINT',
                            passModel.pickupPoint.toUpperCase(),
                          ),
                          const Divider(height: 12),
                          _buildDetailRow('PICKUP TIME', passModel.pickupTime),
                          const Divider(height: 12),
                          _buildDetailRow(
                            'VALIDITY',
                            '${passModel.validFrom} to ${passModel.validUntil}',
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Bottom Signature & QR block
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'M. Raghunath',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2B5C),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 1,
                              color: Colors.black38,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'TRANSPORT MANAGER',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomPaint(
                            painter: QrCodePainter(passModel.passNumber),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
      ],
    );
  }
}
