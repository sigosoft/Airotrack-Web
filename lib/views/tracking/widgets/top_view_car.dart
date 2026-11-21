import 'package:airotrack_web/services/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top-view car for the Live map, as on the mobile app: in the vehicle's
/// status colour and 44 px (x Vehicle Icon Size).
/// The pictures show the car from above with its FRONT POINTING UP;
/// rotating it by the heading makes it face the direction of travel.
/// The coloured cars were made from the green one with the mobile app's
/// `_tintCarPng` rule (only the green body is recoloured).
class TopViewCar extends StatelessWidget {
  static const String assetPath = 'assets/images/green_car_top.png';

  /// Mobile `_carPx`: the car's size at Medium.
  static const double basePx = 44;

  /// Status text ("Running", "Stopped", "Idle"...).
  final String status;

  const TopViewCar({super.key, this.status = 'Running'});

  static String assetFor(String status) {
    final s = status.toLowerCase();
    if (s.contains('run') || s.contains('moving')) return assetPath;
    if (s.contains('idle')) return 'assets/images/car_top_idle.png';
    if (s.contains('inactive')) return 'assets/images/car_top_inactive.png';
    if (s.contains('expire')) return 'assets/images/car_top_expired.png';
    if (s.contains('no data') || s.contains('nodata')) {
      return 'assets/images/car_top_nodata.png';
    }
    return 'assets/images/car_top_stopped.png';
  }

  @override
  Widget build(BuildContext context) {
    // OverflowBox: the map marker box must not squeeze the car.
    return Obx(() {
      final px = basePx * AppSettings.to.iconScale;
      return OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: SizedBox(
          width: px,
          height: px,
          child: Image.asset(
            assetFor(status),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    });
  }
}
