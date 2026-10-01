import 'package:airotrack_web/constants/app_strings.dart';
import 'package:airotrack_web/services/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top-view image of the vehicle for the Live and History maps.
/// The image must show the car from above with its FRONT POINTING UP;
/// rotating it by the heading then makes it face the direction of travel.
class TopViewCar extends StatelessWidget {
  /// Path of the top-view image (listed under assets in pubspec.yaml).
  static const String assetPath = 'assets/images/green_car_top.png';

  final double width;
  final double height;

  const TopViewCar({super.key, this.width = 22, this.height = 42});

  @override
  Widget build(BuildContext context) {
    // Size from Profile > General Settings > Vehicle Icon Size.
    // OverflowBox: the map marker box must not squeeze the car, otherwise
    // Large looked the same as Medium.
    return Obx(() {
      final k = AppSettings.to.iconScale;
      return OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: SizedBox(
          width: width * k,
          height: height * k,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    });
  }
}
