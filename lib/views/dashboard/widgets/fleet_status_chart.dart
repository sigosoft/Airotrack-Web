import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/dashboard_controller.dart';

class FleetStatusChart extends StatelessWidget {
  const FleetStatusChart({super.key});

  // Status colours, same as the Airotrack mobile app. The dashboard API
  // sends counts only; if it ever sends a colour, that colour is used.
  static const Map<String, int> _defaultColors = {
    'running': 0xFF34A853, // green
    'stopped': 0xFFEA4335, // red
    'idle': 0xFFFBBC05, // yellow
    'expired': 0xFFF58A2E, // orange
    'inactive': 0xFF4285F4, // blue
    'nodata': 0xFF9E9E9E, // grey
  };
  static const Map<String, String> _defaultTitles = {
    'running': 'Running',
    'stopped': 'Stopped',
    'idle': 'Idle',
    'expired': 'Expired',
    'inactive': 'Inactive',
    'nodata': 'No Data',
  };
  // Same order as the mobile app: legend top-to-bottom and donut clockwise
  // from the top.
  static const List<String> _shownKeys = [
    'running',
    'stopped',
    'idle',
    'expired',
    'inactive',
    'nodata',
  ];

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    return Obx(() {
      // Counts from the dashboard API response (fleet_status). All six
      // statuses are always listed, like the mobile app; a status missing
      // from the response shows 00.
      final loaded = dashboard.fleetLoaded.value;
      final byKey = {
        for (final f in dashboard.fleetStatus) f['key'] as String: f,
      };
      final slices = <_Slice>[];
      if (loaded) {
        for (final key in _shownKeys) {
          final f = byKey[key];
          slices.add(
            _Slice(
              title: _defaultTitles[key]!,
              count: (f?['count'] as int?) ?? 0,
              color: Color((f?['color'] as int?) ?? _defaultColors[key]!),
            ),
          );
        }
      }
      final total = dashboard.fleetTotal.value;

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
                          slices: slices,
                        ),
                      ),
                      if (!loaded)
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0288D1),
                          ),
                        )
                      else
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
                            Text(
                              total == 1 ? 'Vehicle' : 'Vehicles',
                              style: const TextStyle(
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
                    children: slices.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475467),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item.count.toString().padLeft(2, '0'),
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

class _Slice {
  final String title;
  final int count;
  final Color color;
  const _Slice({required this.title, required this.count, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final int total;
  final List<_Slice> slices;

  _DonutChartPainter({required this.total, required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 24.0;

    final safeTotal = total > 0 ? total : 1;
    double startAngle = -pi / 2;

    for (final slice in slices) {
      final ratio = slice.count / safeTotal;
      if (ratio <= 0) continue;

      final sweepAngle = ratio * 2 * pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
