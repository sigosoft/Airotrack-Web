import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized Custom MediaQuery, Orientation & Screen Responsive Utilities
class CustomMediaQuery {
  CustomMediaQuery._();

  /// Direct access to [MediaQueryData]
  static MediaQueryData of(BuildContext context) => MediaQuery.of(context);

  /// Get Screen Width using MediaQuery
  static double screenWidth(BuildContext context) => of(context).size.width;

  /// Get Screen Height using MediaQuery
  static double screenHeight(BuildContext context) => of(context).size.height;

  /// Get Device Orientation using MediaQuery
  static Orientation orientation(BuildContext context) =>
      of(context).orientation;

  /// Check if screen orientation is Landscape
  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  /// Check if screen orientation is Portrait
  static bool isPortrait(BuildContext context) =>
      orientation(context) == Orientation.portrait;

  /// Viewport Category Breakpoints
  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 1024;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

  /// Width percentage helper using MediaQuery
  static double widthPercent(BuildContext context, double percentage) =>
      (screenWidth(context) * percentage) / 100;

  /// Height percentage helper using MediaQuery
  static double heightPercent(BuildContext context, double percentage) =>
      (screenHeight(context) * percentage) / 100;

  /// Dynamic card width calculator based on screen width
  static double cardWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < 600) return width * 0.9;
    return 420.0;
  }

  /// Generic responsive value provider
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// Custom Extension on [BuildContext] for shorthand access
extension CustomContextUtils on BuildContext {
  double get customWidth => CustomMediaQuery.screenWidth(this);
  double get customHeight => CustomMediaQuery.screenHeight(this);
  bool get customIsLandscape => CustomMediaQuery.isLandscape(this);
  bool get customIsPortrait => CustomMediaQuery.isPortrait(this);
  bool get customIsMobile => CustomMediaQuery.isMobile(this);
  ThemeData get appTheme => Theme.of(this);
  TextTheme get appTextTheme => appTheme.textTheme;
  Color get appPrimaryColor => AppColors.primary;
  Color get appButtonColor => AppColors.buttonBlue;
}
