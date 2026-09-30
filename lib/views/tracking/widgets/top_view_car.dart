import 'package:flutter/material.dart';
import '../../../constants/app_assets.dart';

/// Top-view image of the vehicle for the Live and History maps.
/// The image must show the car from above with its FRONT POINTING UP;
/// rotating it by the heading then makes it face the direction of travel.
class TopViewCar extends StatelessWidget {
  /// Path of the top-view image (listed under assets in pubspec.yaml).
  static const String assetPath = AppAssets.greenCarTop;

  final double width;
  final double height;

  const TopViewCar({super.key, this.width = 44, this.height = 66});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          // If asset is not yet bundled in hot reload, fallback to vector top view car
          return const CustomPaint(
            painter: _TopViewCarPainter(),
          );
        },
      ),
    );
  }
}

/// Fallback vector painter rendering an aerodynamic top-down green vehicle.
class _TopViewCarPainter extends CustomPainter {
  const _TopViewCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.08, w * 0.7, h * 0.85),
        Radius.circular(w * 0.35),
      ),
      shadowPaint,
    );

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    const wheelW = 3.0;
    final wheelH = h * 0.16;
    // Front wheels
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.18, wheelW, wheelH),
        const Radius.circular(1.5),
      ),
      wheelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.92 - wheelW, h * 0.18, wheelW, wheelH),
        const Radius.circular(1.5),
      ),
      wheelPaint,
    );
    // Rear wheels
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.68, wheelW, wheelH),
        const Radius.circular(1.5),
      ),
      wheelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.92 - wheelW, h * 0.68, wheelW, wheelH),
        const Radius.circular(1.5),
      ),
      wheelPaint,
    );

    // Side Mirrors
    final mirrorPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.05, h * 0.28, w * 0.15, h * 0.08),
      mirrorPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.80, h * 0.28, w * 0.15, h * 0.08),
      mirrorPaint,
    );

    // Car Body
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.18, h * 0.05, w * 0.64, h * 0.88),
      topLeft: Radius.circular(w * 0.32),
      topRight: Radius.circular(w * 0.32),
      bottomLeft: Radius.circular(w * 0.22),
      bottomRight: Radius.circular(w * 0.22),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(bodyRect, borderPaint);

    // Headlights
    final lightPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.25, h * 0.08, w * 0.12, h * 0.07),
      lightPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.63, h * 0.08, w * 0.12, h * 0.07),
      lightPaint,
    );

    // Windshield (Front glass)
    final glassPaint = Paint()..color = const Color(0xFF0F172A);
    final windshield = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.26, w * 0.48, h * 0.14),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(windshield, glassPaint);

    // Roof
    final roofPaint = Paint()..color = const Color(0xFF047857);
    final roof = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.42, w * 0.44, h * 0.24),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(roof, roofPaint);

    // Rear glass
    final rearGlass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.27, h * 0.68, w * 0.46, h * 0.11),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(rearGlass, glassPaint);

    // Taillights
    final tailPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.90, w * 0.14, h * 0.025),
        const Radius.circular(1),
      ),
      tailPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.62, h * 0.90, w * 0.14, h * 0.025),
        const Radius.circular(1),
      ),
      tailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
