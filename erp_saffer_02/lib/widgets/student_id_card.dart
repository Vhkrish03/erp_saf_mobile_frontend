import 'dart:math';
import 'package:flutter/material.dart';
import '../models/student_id_card_model.dart';

class StudentIdCard extends StatefulWidget {
  final StudentIdCardModel cardModel;
  const StudentIdCard({super.key, required this.cardModel});

  @override
  State<StudentIdCard> createState() => _StudentIdCardState();
}

class _StudentIdCardState extends State<StudentIdCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double value = _controller.value;
                final double rotationValue = value * pi;
                final isBack = rotationValue > (pi / 2);

                return Transform(
                  alignment: Alignment.center,
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateY(rotationValue),
                  child:
                      isBack
                          ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildBackCard(),
                          )
                          : _buildFrontCard(),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flip_camera_android_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  "Tap card to flip (showing ${_showFront ? "Front" : "Back"})",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: 320,
      height: 520,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
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
          // Navy Header Block
          Container(
            height: 90,
            color: const Color(0xFF0F2B5C),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Karpaga Vinayaga Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'KARPAGA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontFamily: 'Serif',
                        ),
                      ),
                      Text(
                        'VINAYAGA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontFamily: 'Serif',
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider line
                Container(
                  width: 1.5,
                  height: 48,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Medicine Dentistry Engineering...
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'MEDICINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'DENTISTRY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'ENGINEERING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'NURSING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'SCHOOL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Orange Header Ribbon
          Container(
            width: double.infinity,
            height: 22,
            color: const Color(0xFFD44C26),
            alignment: Alignment.center,
            child: const Text(
              'EDUCATIONAL GROUP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Student ID Card pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF88251E), width: 1.5),
            ),
            child: Text(
              '${widget.cardModel.designation.toUpperCase()} ID CARD / ${widget.cardModel.dayscholarStatus.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF88251E),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photo & Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Photo Area
                Container(
                  width: 100,
                  height: 125,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      widget.cardModel.photoUrl.isNotEmpty
                          ? Image.network(
                            widget.cardModel.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildAvatarPlaceholder(),
                          )
                          : _buildAvatarPlaceholder(),
                ),
                const SizedBox(width: 12),
                // Name Panel (Navy background with white text)
                Expanded(
                  child: Container(
                    height: 125,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1F57),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Text(
                      widget.cardModel.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dept/Batch Box & Seal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Orange Details Container
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65A28),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cardModel.department.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BATCH: ${widget.cardModel.validity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Round seal emblem
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF3F51B5),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF3F51B5),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Bottom area: Admin/Register Number & QR code
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Admin ID
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADMIN NO.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.cardModel.idOrRollNumber,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // QR code box
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomPaint(
                    painter: QrCodePainter(widget.cardModel.idOrRollNumber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: 320,
      height: 520,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DOB & BLOOD GROUP
          _buildBackRow('D.O.B', widget.cardModel.dob),
          const SizedBox(height: 12),
          _buildBackRow('BLOOD GROUP', widget.cardModel.bloodGroup),
          const SizedBox(height: 12),

          // ADDRESS
          const Text(
            'ADDRESS:',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.cardModel.address,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // EMERGENCY CONTACT
          _buildBackRow(
            'EMERGENCY CONTACT NO',
            widget.cardModel.emergencyContact,
          ),
          const SizedBox(height: 18),

          // Green highlighted pickup point sticker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.cardModel.dayscholarStatus.toUpperCase() == "DAYSCHOLAR"
                  ? 'PICKUP: MANNIVAKKAM'
                  : 'ROUTE: HOSTELLER',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Authorized Signatory section
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'K.V. Prasad',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF0F2B5C),
                  ),
                ),
                const SizedBox(height: 2),
                Container(width: 140, height: 1, color: Colors.black38),
                const SizedBox(height: 4),
                const Text(
                  'AUTHORIZED SIGNATORY',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // General Card warning/instructions
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text(
              'IF THIS CARD IS LOST / FOUND BY SOMEONE PLEASE\nRETURN TO:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'KARPAGA VINAYAGA COLLEGE OF ENGINEERING AND TECHNOLOGY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2B5C),
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Center(
            child: Text(
              'GST Road, Chinna Kolambakkam, Maduranthagam (Tk),\nKanchipuram Dist, TN - 603308\nPhone: 044-71565100, 27565195 | www.kveg.in',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: Colors.black45, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ': $value',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 54, color: Colors.grey.shade400),
    );
  }
}

class QrCodePainter extends CustomPainter {
  final String data;
  QrCodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paintObj = Paint()..color = Colors.black;
    final double blockW = size.width / 15;
    final double blockH = size.height / 15;

    // Draw finder patterns (top-left, top-right, bottom-left)
    _drawFinderPattern(canvas, 0, 0, blockW, blockH);
    _drawFinderPattern(canvas, 10, 0, blockW, blockH);
    _drawFinderPattern(canvas, 0, 10, blockW, blockH);

    // Draw deterministic blocks based on data hash
    final int hashVal = data.hashCode;
    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        // Skip finder patterns
        if ((r < 7 && c < 7) || (r < 7 && c >= 8) || (r >= 8 && c < 7)) {
          continue;
        }
        final int cellValue = (hashVal ^ (r * 179 + c * 233)) % 103;
        if (cellValue % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * blockW, r * blockH, blockW, blockH),
            paintObj,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, int col, int row, double w, double h) {
    final paintObj = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(col * w, row * h, 7 * w, 7 * h), paintObj);
    paintObj.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * w, (row + 1) * h, 5 * w, 5 * h),
      paintObj,
    );
    paintObj.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH((col + 2) * w, (row + 2) * h, 3 * w, 3 * h),
      paintObj,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
