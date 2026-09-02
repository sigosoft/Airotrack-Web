import 'dart:math';
import 'package:flutter/material.dart';

class FleetStatusChart extends StatelessWidget {
  const FleetStatusChart({super.key});

  @override
  Widget build(BuildContext context) {
    final legendItems = [
      {'title': 'Running', 'count': '15', 'color': const Color(0xFF2E7D32)},
      {'title': 'Stopped', 'count': '03', 'color': const Color(0xFFD32F2F)},
      {'title': 'Idle', 'count': '05', 'color': const Color(0xFFF57C00)},
      {'title': 'Expired', 'count': '01', 'color': const Color(0xFFE65100)},
      {'title': 'In Active', 'count': '04', 'color': const Color(0xFF0288D1)},
      {'title': 'No Data', 'count': '03', 'color': const Color(0xFF757575)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Fleet Status',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut Chart Graphic with Center Text
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 140),
                      painter: _DonutChartPainter(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '30',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                        Text(
                          'Objects',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legendItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475467),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['count'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 24.0;

    final slices = [
      {'ratio': 15 / 31, 'color': const Color(0xFF2E7D32)},
      {'ratio': 3 / 31, 'color': const Color(0xFFD32F2F)},
      {'ratio': 5 / 31, 'color': const Color(0xFFF57C00)},
      {'ratio': 1 / 31, 'color': const Color(0xFFE65100)},
      {'ratio': 4 / 31, 'color': const Color(0xFF0288D1)},
      {'ratio': 3 / 31, 'color': const Color(0xFF757575)},
    ];

    double startAngle = -pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice['ratio'] as double) * 2 * pi;
      final paint = Paint()
        ..color = slice['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
