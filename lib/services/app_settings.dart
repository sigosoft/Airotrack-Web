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
  static const String _k24Hour = 'use_24_hour_time';
  static const String _kSpeedometer = 'show_speedometer';
  static const String _kMapType = 'map_type';
  static const String _kSpeedUnit = 'speed_unit';
  static const String _kDistanceUnit = 'distance_unit';

  static const List<String> iconSizes = ['Small', 'Medium', 'Large'];

  /// Map Type options (same as the mobile app).
  static const List<String> mapTypes = ['Default', 'Satellite', 'Terrain'];

  /// Speed options: stored value -> label.
  static const Map<String, String> speedUnits = {
    'kmh': 'km/h',
    'mph': 'mph',
  };

  /// Distance options: stored value -> label.
  static const Map<String, String> distanceUnits = {
    'km': 'Kilometres (km)',
    'mi': 'Miles (mi)',
  };

  static const double _kmPerMile = 1.609344;

  /// Time Format: true = 24 hour (14:05), false = 12 hour (02:05 PM).
  final RxBool use24HourTime = true.obs;

  /// Speedometer on the Track screen.
  final RxBool showSpeedometer = true.obs;

  /// 'Default' | 'Satellite' | 'Terrain'
  final RxString mapType = 'Default'.obs;

  /// 'kmh' | 'mph'
  final RxString speedUnit = 'kmh'.obs;

  /// 'km' | 'mi'
  final RxString distanceUnit = 'km'.obs;

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
      use24HourTime.value = prefs.getBool(_k24Hour) ?? true;
      showSpeedometer.value = prefs.getBool(_kSpeedometer) ?? true;
      final map = prefs.getString(_kMapType);
      if (map != null && mapTypes.contains(map)) mapType.value = map;
      final speed = prefs.getString(_kSpeedUnit);
      if (speed != null && speedUnits.containsKey(speed)) {
        speedUnit.value = speed;
      }
      final dist = prefs.getString(_kDistanceUnit);
      if (dist != null && distanceUnits.containsKey(dist)) {
        distanceUnit.value = dist;
      }
    } catch (e) {
      debugPrint('[AppSettings] load failed: $e');
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Scale of the top-view car on the maps.
  double get iconScale {
    switch (vehicleIconSize.value) {
      // Same multipliers as the mobile app (Medium = 1).
      case 'Small':
        return 0.75;
      case 'Large':
        return 1.3;
      default:
        return 1.0;
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

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> setUse24HourTime(bool value) async {
    use24HourTime.value = value;
    await _saveBool(_k24Hour, value);
  }

  Future<void> setShowSpeedometer(bool value) async {
    showSpeedometer.value = value;
    await _saveBool(_kSpeedometer, value);
  }

  Future<void> setMapType(String value) async {
    if (!mapTypes.contains(value)) return;
    mapType.value = value;
    await _saveString(_kMapType, value);
  }

  Future<void> setSpeedUnit(String value) async {
    if (!speedUnits.containsKey(value)) return;
    speedUnit.value = value;
    await _saveString(_kSpeedUnit, value);
  }

  Future<void> setDistanceUnit(String value) async {
    if (!distanceUnits.containsKey(value)) return;
    distanceUnit.value = value;
    await _saveString(_kDistanceUnit, value);
  }

  // ---------------------------------------------------------------------
  // Display helpers. Values stay in km and km/h everywhere; only what is
  // shown changes.
  // ---------------------------------------------------------------------

  /// Google tile layer for the chosen Map Type (m = road, s = satellite
  /// with labels via y, p = terrain).
  String get tileUrl =>
      'https://mt{s}.google.com/vt/lyrs=$mapLayerCode&x={x}&y={y}&z={z}';

  /// Google `lyrs` code for the chosen Map Type.
  String get mapLayerCode => switch (mapType.value) {
    'Satellite' => 'y',
    'Terrain' => 'p',
    _ => 'm',
  };

  static const List<String> tileSubdomains = ['0', '1', '2', '3'];

  bool get isMph => speedUnit.value == 'mph';
  bool get isMiles => distanceUnit.value == 'mi';

  String get speedLabel => isMph ? 'mph' : 'km/h';
  String get distanceLabel => isMiles ? 'mi' : 'km';

  num convertSpeed(num kmh) => isMph ? kmh / _kmPerMile : kmh;
  num convertDistance(num km) => isMiles ? km / _kmPerMile : km;

  /// "45 km/h" / "28 mph".
  String speed(num? kmh, {int decimals = 0, bool withUnit = true}) {
    if (kmh == null) return '-';
    final v = convertSpeed(kmh).toStringAsFixed(decimals);
    return withUnit ? '$v $speedLabel' : v;
  }

  /// "12.34 km" / "7.67 mi".
  String distance(num? km, {int decimals = 2, bool withUnit = true}) {
    if (km == null) return '-';
    final v = convertDistance(km).toStringAsFixed(decimals);
    return withUnit ? '$v $distanceLabel' : v;
  }

  /// Rewrites a speed text from the API or the app ("45 km/h", "45 Kmph",
  /// "45") in the chosen unit. A bare number stays bare (the caller shows
  /// [speedLabel]); text without a number is returned unchanged.
  String speedText(String? text) => _convertText(
    text,
    unitPattern: r'(\s*(?:km\s*/\s*hr?|kmph|kph))?',
    toUnit: speedLabel,
    convert: convertSpeed,
    active: isMph,
  );

  /// Rewrites a distance text ("12.3 km", "12.3 Km", "12.3") in the chosen
  /// unit, like [speedText].
  String distanceText(String? text) => _convertText(
    text,
    unitPattern: r'(\s*(?:km|kms|kilometers|kilometres))?',
    toUnit: distanceLabel,
    convert: convertDistance,
    active: isMiles,
  );

  String _convertText(
    String? text, {
    required String unitPattern,
    required String toUnit,
    required num Function(num) convert,
    required bool active,
  }) {
    final t = text?.trim() ?? '';
    if (!active || t.isEmpty) return t;
    final m = RegExp(
      '^(-?[0-9][0-9,]*(?:\\.[0-9]+)?)$unitPattern\$',
      caseSensitive: false,
    ).firstMatch(t);
    if (m == null) return t;
    final n = num.tryParse(m.group(1)!.replaceAll(',', ''));
    if (n == null) return t;
    final decimals = m.group(1)!.contains('.')
        ? m.group(1)!.split('.').last.length.clamp(0, 2)
        : 0;
    final value = convert(n).toStringAsFixed(decimals);
    return m.group(2) == null ? value : '$value $toUnit';
  }

  static final RegExp _speedInText = RegExp(
    r'(-?\d[\d,]*(?:\.\d+)?)\s*(km\s*/\s*hr?|kmph|kph)\b',
    caseSensitive: false,
  );
  static final RegExp _distanceInText = RegExp(
    r'(-?\d[\d,]*(?:\.\d+)?)\s*(km|kms|kilometers|kilometres)\b(?!\s*/)',
    caseSensitive: false,
  );

  /// Rewrites every "45 km/h" and "12.3 km" inside [text] in the chosen
  /// units (unchanged when km and km/h are selected).
  String units(String? text) {
    var t = text ?? '';
    if (t.isEmpty) return t;
    String fmt(String raw, num Function(num) convert, String unit) {
      final n = num.tryParse(raw.replaceAll(',', ''));
      if (n == null) return raw;
      final decimals = raw.contains('.')
          ? raw.split('.').last.length.clamp(0, 2)
          : 0;
      return '${convert(n).toStringAsFixed(decimals)} $unit';
    }

    if (isMph) {
      t = t.replaceAllMapped(
        _speedInText,
        (m) => fmt(m.group(1)!, convertSpeed, speedLabel),
      );
    }
    if (isMiles) {
      t = t.replaceAllMapped(
        _distanceInText,
        (m) => fmt(m.group(1)!, convertDistance, distanceLabel),
      );
    }
    return t;
  }

  /// Formats a time of day in the chosen 12 / 24 hour format.
  String timeOfDay(DateTime t, {bool seconds = false}) {
    String two(int v) => v.toString().padLeft(2, '0');
    final s = seconds ? ':${two(t.second)}' : '';
    if (use24HourTime.value) return '${two(t.hour)}:${two(t.minute)}$s';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${two(h)}:${two(t.minute)}$s ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Re-formats a date-time text from the API ("2026-11-16 14:32:37",
  /// "16-11-2026 02:32 PM", ISO) as "dd-MM-yyyy" plus the time in the chosen
  /// format. Text it can't read is returned unchanged.
  String dateTime(String? raw, {bool seconds = false}) {
    final text = raw?.trim() ?? '';
    final parsed = parseDateTime(text);
    if (parsed == null) return text;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(parsed.day)}-${two(parsed.month)}-${parsed.year} '
        '${timeOfDay(parsed, seconds: seconds)}';
  }

  /// A date-time or a bare time from the API, in the chosen time format
  /// (seconds kept when the text has them). Unreadable text is unchanged.
  String anyTime(String? raw) {
    final text = raw?.trim() ?? '';
    final hasSeconds = RegExp(r'\d:\d{2}:\d{2}').hasMatch(text);
    if (parseDateTime(text) != null) {
      return dateTime(text, seconds: hasSeconds);
    }
    return timeText(text);
  }

  /// Re-formats only the time part of a text ("14:32", "02:32 PM",
  /// "2026-11-16 14:32:37"). Text it can't read is returned unchanged.
  String timeText(String? raw) {
    final text = raw?.trim() ?? '';
    final full = parseDateTime(text);
    if (full != null) return timeOfDay(full);
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    ).firstMatch(text);
    if (m == null) return text;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final sec = int.tryParse(m.group(3) ?? '') ?? 0;
    final ap = m.group(4)?.toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    if (h > 23 || min > 59) return text;
    return timeOfDay(
      DateTime(2000, 1, 1, h, min, sec),
      seconds: m.group(3) != null,
    );
  }

  /// Reads "yyyy-MM-dd HH:mm[:ss]", ISO, or "dd-MM-yyyy hh:mm[:ss] [AM|PM]".
  static DateTime? parseDateTime(String text) {
    if (text.isEmpty) return null;
    final iso = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (iso != null) return iso.isUtc ? iso.toLocal() : iso;
    final m = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})[ ,T]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    ).firstMatch(text);
    if (m == null) return null;
    var h = int.parse(m.group(4)!);
    final ap = m.group(7)?.toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
      h,
      int.parse(m.group(5)!),
      int.tryParse(m.group(6) ?? '') ?? 0,
    );
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
