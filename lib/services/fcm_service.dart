import 'dart:convert';

import 'package:airotrack_web/constants/app_strings.dart';
import 'package:airotrack_web/services/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../utils/app_toast.dart';

/// Runs when a push arrives while the app is in the background / closed
/// (Android). Notification-type messages are shown by the system itself.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] background message: ${message.messageId}');
}

/// Push notifications for Airotrack (Android + Web).
/// - asks permission
/// - gets the device token (web needs the VAPID key)
/// - shows notifications that arrive while the app is open
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  /// Firebase console > Project settings > Cloud Messaging >
  /// Web configuration > Web Push certificates > Key pair.
  static const String webVapidKey = 'PASTE_YOUR_WEB_PUSH_VAPID_KEY_HERE';

  static const String _prefsTokenKey = 'fcm_token';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'airotrack_alerts', // must match AndroidManifest meta-data
    'Airotrack alerts',
    description: 'Vehicle alerts and notifications',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  String? _token;
  bool _initialized = false;

  /// Call once at app start, after Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    if (!kIsWeb) {
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _handleTap(response.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    await getToken();
    messaging.onTokenRefresh.listen(_saveToken);

    // App open (foreground)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    // App in background, user tapped the notification
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _handleTap(jsonEncode(m.data)),
    );
    // App was closed, opened by tapping the notification
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleTap(jsonEncode(initial.data));
  }

  /// Current device token (null if permission denied / not supported).
  Future<String?> getToken() async {
    // Notification switch OFF: do not register this device for pushes.
    await AppSettings.to.ready;
    if (!AppSettings.to.notificationsEnabled.value) return null;
    try {
      final validVapid =
          (kIsWeb && webVapidKey.isNotEmpty && !webVapidKey.startsWith('PASTE'))
          ? webVapidKey
          : null;
      _token = await FirebaseMessaging.instance.getToken(vapidKey: validVapid);
      if (_token != null) await _saveToken(_token!);
      debugPrint('[FCM] token: $_token');
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }
    return _token;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsTokenKey, token);
    } catch (_) {}
    // If the user is already logged in, you can also send the new token to
    // the backend here (same API used at login).
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Profile > Notification switch OFF: show nothing.
    if (!AppSettings.to.notificationsEnabled.value) return;
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    if (kIsWeb) {
      // Browsers do not show a system popup while the page is open.
      AppToast.show([title, body].whereType<String>().join('\n'));
      return;
    }

    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Notification tapped. Use the data (e.g. imei / alert id) to open a
  /// screen.
  void _handleTap(String? payload) {
    debugPrint('[FCM] notification tapped: $payload');
    // Example: open the vehicle / alerts screen using the payload data.
  }
}
