import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  AppToast._();

  /// Displays floating toast message using GetX snackbar engine
  static void show(String message, {bool isError = false}) {
    Get.closeCurrentSnackbar();
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFD32F2F)
          : const Color(0xFF212121).withOpacity(0.92),
      borderRadius: 25,
      margin: const EdgeInsets.only(bottom: 36, left: 36, right: 36),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      snackStyle: SnackStyle.FLOATING,
    );
  }
}
