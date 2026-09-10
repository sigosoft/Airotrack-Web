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

  /// Displays error message cleanly handling DioExceptions and general errors
  static void showErrorMessage(dynamic e) {
    debugPrint('❌ [App Error]: $e');
    String msg = 'An unexpected error occurred. Please try again.';
    if (e != null) {
      try {
        if (e is Exception && e.runtimeType.toString().contains('DioException')) {
          final response = (e as dynamic).response;
          if (response?.data != null && response.data is Map) {
            final dataMap = response.data as Map;
            if (dataMap['message'] is Map) {
              final msgMap = dataMap['message'] as Map;
              if (msgMap.isNotEmpty) {
                final firstVal = msgMap.values.first;
                if (firstVal is List && firstVal.isNotEmpty) {
                  msg = firstVal.first.toString();
                } else {
                  msg = firstVal.toString();
                }
              }
            } else if (dataMap['message'] != null) {
              msg = dataMap['message'].toString();
            } else if (dataMap['error'] != null) {
              msg = dataMap['error'].toString();
            }
          } else if ((e as dynamic).message != null) {
            msg = (e as dynamic).message.toString();
          }
        } else if (e is Map) {
          msg = e['message']?.toString() ?? e['error']?.toString() ?? msg;
        } else {
          msg = e.toString().replaceAll('Exception: ', '');
        }
      } catch (_) {
        msg = e.toString();
      }
    }
    show(msg, isError: true);
  }

}

