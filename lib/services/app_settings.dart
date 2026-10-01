import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fcm_service.dart';

/// Settings kept on this device: Profile > General Settings switches and the
/// Notification switch. Read by the Live / History maps and FcmService.
/// (There is no settings API yet, so they are saved in SharedPreferences.)
class AppSettings extends GetxController {
  static AppSettings get to => Get.isRegistered<AppSettings>()
      ? Get.find<AppSettings>()
      : Get.put(AppSettings(), permanent: true);

  static const String _kIconSize = 'vehicle_icon_size';
  static const String _kHistoryOnLive = 'show_history_on_live';
  static const String _kNotifications = 'notifications_enabled';

  static const List<String> iconSizes = ['Small', 'Medium', 'Large'];

  /// 'Small' | 'Medium' | 'Large'
  final RxString vehicleIconSize = 'Medium'.obs;

  /// Draw today's travelled route on the Live tracking map.
  final RxBool showHistoryOnLive = false.obs;

  /// Push notifications on this device.
  final RxBool notificationsEnabled = true.obs;

  final Completer<void> _loaded = Completer<void>();
  Future<void> get ready => _loaded.future;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final size = prefs.getString(_kIconSize);
      if (size != null && iconSizes.contains(size)) {
        vehicleIconSize.value = size;
      }
      showHistoryOnLive.value = prefs.getBool(_kHistoryOnLive) ?? false;
      notificationsEnabled.value = prefs.getBool(_kNotifications) ?? true;
    } catch (e) {
      debugPrint('[AppSettings] load failed: $e');
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Scale of the top-view car on the maps.
  double get iconScale {
    switch (vehicleIconSize.value) {
      case 'Small':
        return 1.0; // the former Medium
      case 'Large':
        return 2.1; // a little bigger than Medium
      default:
        return 1.7; // Medium = the former Large
    }
  }

  Future<void> setVehicleIconSize(String size) async {
    if (!iconSizes.contains(size)) return;
    vehicleIconSize.value = size;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kIconSize, size);
    } catch (_) {}
  }

  Future<void> setShowHistoryOnLive(bool value) async {
    showHistoryOnLive.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHistoryOnLive, value);
    } catch (_) {}
  }

  /// ON: this device gets a push token again and shows notifications.
  /// OFF: the device token is deleted (pushes can no longer reach this
  /// device) and nothing is shown even if a message still arrives.
  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotifications, value);
    } catch (_) {}
    try {
      if (value) {
        await FcmService.instance.getToken();
      } else {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (e) {
      debugPrint('[AppSettings] notification token change failed: $e');
    }
  }
}
