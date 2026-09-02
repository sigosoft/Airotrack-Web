import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';

class EngineHoursChart extends StatelessWidget {
  final List<EngineHourDataPoint> dataPoints;

  const EngineHoursChart({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
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
              'Engine Hours',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y-Axis Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('24', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    Text('20', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    Text('16', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    Text('12', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    Text('8', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    Text('4', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                  ],
                ),
                const SizedBox(width: 8),
                // Y-Axis Vertical Line & Canvas Area
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _EngineHoursPainter(dataPoints),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // X-Axis Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: dataPoints.map((item) {
                          return Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF667085),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineHoursPainter extends CustomPainter {
  final List<EngineHourDataPoint> points;

  _EngineHoursPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final axisPaint = Paint()
      ..color = const Color(0xFFD0D5DD)
      ..strokeWidth = 1;

    // Draw Y-Axis & Baseline
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    final double stepX = size.width / (points.length - 1);
    final maxVal = 24.0;

    final path = Path();
    final fillPath = Path();

    final List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i].hours / maxVal) * size.height);
      offsets.add(Offset(x, y));
    }

    if (offsets.length > 1) {
      path.moveTo(offsets[0].dx, offsets[0].dy);
      fillPath.moveTo(offsets[0].dx, size.height);
      fillPath.lineTo(offsets[0].dx, offsets[0].dy);

      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = offsets[i];
        final p1 = offsets[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      fillPath.lineTo(offsets.last.dx, size.height);
      fillPath.close();

      // Draw Gradient Fill under line
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2E7D32).withOpacity(0.25),
            const Color(0xFFE4E7EC).withOpacity(0.4),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);

      // Draw Line
      final linePaint = Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
