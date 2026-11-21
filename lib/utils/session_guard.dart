import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/dio_client.dart';
import '../services/lookups_service.dart';
import '../views/login_view.dart';
import 'app_toast.dart';

/// Ends the session when the server rejects the saved token (HTTP 401),
/// from any screen, the same way the mobile app does.
class SessionGuard {
  SessionGuard._();

  static bool _handling = false;

  /// Paths whose 401 does not mean "session expired" (wrong password on
  /// login, or a sign-out that already cleared the session).
  static const _ignoredPaths = ['login', 'logout'];

  static bool shouldHandle(String path, int? statusCode) {
    if (statusCode != 401) return false;
    final p = path.split('?').first.replaceAll(RegExp(r'^/+'), '');
    return !_ignoredPaths.contains(p);
  }

  static Future<void> handleUnauthorized() async {
    if (_handling) return;
    final token = await DioClient().getToken();
    if (token == null || token.isEmpty) return; // already signed out
    _handling = true;
    try {
      LookupsService.clearCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('token');
      await prefs.remove('username');
      await prefs.remove('user_phone');
      await DioClient().clearToken();
      AppToast.show(
        'Your session has expired. Please sign in again.',
        isError: true,
      );
      Get.offAll(() => const LoginView());
    } finally {
      _handling = false;
    }
  }
}
