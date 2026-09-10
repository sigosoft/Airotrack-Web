import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';

class FleetStatusChart extends StatelessWidget {
  const FleetStatusChart({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Obx(() {
      final total = int.tryParse(homeController.totalCount.value) ?? homeController.vehicles.length;
      final running = int.tryParse(homeController.runningCount.value) ?? homeController.vehicles.where((v) => v.status == 'Running').length;
      final stopped = int.tryParse(homeController.stoppedCount.value) ?? homeController.vehicles.where((v) => v.status == 'Stopped').length;
      final idle = int.tryParse(homeController.idleCount.value) ?? homeController.vehicles.where((v) => v.status == 'Idle').length;
      final inactive = int.tryParse(homeController.inactiveCount.value) ?? homeController.vehicles.where((v) => v.status == 'Inactive').length;

      final legendItems = [
        {'title': 'Running', 'count': running.toString().padLeft(2, '0'), 'color': const Color(0xFF2E7D32), 'raw': running},
        {'title': 'Stopped', 'count': stopped.toString().padLeft(2, '0'), 'color': const Color(0xFFD32F2F), 'raw': stopped},
        {'title': 'Idle', 'count': idle.toString().padLeft(2, '0'), 'color': const Color(0xFFF57C00), 'raw': idle},
        {'title': 'Expired', 'count': '00', 'color': const Color(0xFFE65100), 'raw': 0},
        {'title': 'In Active', 'count': inactive.toString().padLeft(2, '0'), 'color': const Color(0xFF0288D1), 'raw': inactive},
        {'title': 'No Data', 'count': '00', 'color': const Color(0xFF757575), 'raw': 0},
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
                        painter: _DonutChartPainter(
                          total: total,
                          running: running,
                          stopped: stopped,
                          idle: idle,
                          inactive: inactive,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                          const Text(
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
    });
  }
}

class _DonutChartPainter extends CustomPainter {
  final int total;
  final int running;
  final int stopped;
  final int idle;
  final int inactive;

  _DonutChartPainter({
    required this.total,
    required this.running,
    required this.stopped,
    required this.idle,
    required this.inactive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 24.0;

    final safeTotal = total > 0 ? total : 1;

    final slices = [
      {'ratio': running / safeTotal, 'color': const Color(0xFF2E7D32)},
      {'ratio': stopped / safeTotal, 'color': const Color(0xFFD32F2F)},
      {'ratio': idle / safeTotal, 'color': const Color(0xFFF57C00)},
      {'ratio': 0.0, 'color': const Color(0xFFE65100)},
      {'ratio': inactive / safeTotal, 'color': const Color(0xFF0288D1)},
      {'ratio': 0.0, 'color': const Color(0xFF757575)},
    ];

    double startAngle = -pi / 2;

    for (final slice in slices) {
      final ratio = slice['ratio'] as double;
      if (ratio <= 0) continue;

      final sweepAngle = ratio * 2 * pi;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
