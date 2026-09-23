import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  AppToast._();

  /// Cleans and extracts raw user-friendly message from maps, lists, or stringified objects
  /// (e.g. "{username: [Username is not registered.]}" -> "Username is not registered.")
  static String cleanMessage(dynamic raw) {
    if (raw == null) return '';
    if (raw is Map) {
      if (raw.isEmpty) return '';
      final candidate =
          raw['message'] ?? raw['error'] ?? raw['errors'] ?? raw.values.first;
      return cleanMessage(candidate);
    }
    if (raw is List) {
      if (raw.isEmpty) return '';
      return cleanMessage(raw.first);
    }
    String str = raw.toString().trim();
    if (str.startsWith('Exception: ')) {
      str = str.substring('Exception: '.length).trim();
    }
    // Handle stringified maps/lists like "{username: [Username is not registered.]}"
    if ((str.startsWith('{') && str.endsWith('}')) ||
        (str.startsWith('[') && str.endsWith(']'))) {
      final match = RegExp(
        r'[:\[]\s*([^\{\}\[\]:]+?)\s*[\]\}]',
      ).firstMatch(str);
      if (match != null &&
          match.group(1) != null &&
          match.group(1)!.trim().isNotEmpty) {
        return match.group(1)!.trim();
      }
      str = str.replaceAll(RegExp(r'^[\{\[\s]+|[\}\]\s]+$'), '').trim();
      if (str.contains(':')) {
        str = str.split(':').last.trim();
        str = str.replaceAll(RegExp(r'^[\{\[\s]+|[\}\]\s]+$'), '').trim();
      }
    }
    return str;
  }

  /// Displays floating toast message using GetX snackbar engine
  static void show(String message, {bool isError = false}) {
    final cleaned = cleanMessage(message);
    if (cleaned.isEmpty) return;

    Get.closeCurrentSnackbar();
    Get.rawSnackbar(
      messageText: Text(
        cleaned,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      maxWidth: 380,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFD32F2F)
          : const Color(0xFF212121).withOpacity(0.92),
      borderRadius: 25,
      margin: const EdgeInsets.only(bottom: 36, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  /// Displays error message cleanly handling DioExceptions and general errors
  static void showErrorMessage(dynamic e) {
    String msg = 'An unexpected error occurred. Please try again.';
    if (e != null) {
      try {
        if (e is Exception &&
            e.runtimeType.toString().contains('DioException')) {
          final response = (e as dynamic).response;
          if (response?.data != null) {
            final extracted = cleanMessage(response.data);
            if (extracted.isNotEmpty) {
              msg = extracted;
            }
          } else if ((e as dynamic).message != null) {
            final extracted = cleanMessage((e as dynamic).message);
            if (extracted.isNotEmpty) {
              msg = extracted;
            }
          }
        } else {
          final extracted = cleanMessage(e);
          if (extracted.isNotEmpty) {
            msg = extracted;
          }
        }
      } catch (_) {
        msg = cleanMessage(e.toString());
      }
    }
    show(msg, isError: true);
  }
}
