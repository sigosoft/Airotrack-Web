import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';

/// Converts the GPS device's own km count into the vehicle's odometer (same
/// as the mobile app).
///
/// The server keeps two counters per vehicle: `kilometer` (counted by the
/// tracker since it was fitted) and `odometer` (the real odometer, set from
/// Track > Update Odometer). Statistics and reports return the device count
/// (`odometer_km`), so they disagreed with Track. The gap is fixed per
/// vehicle and live_track_snapshot returns both counters.
class OdometerOffsetService {
  OdometerOffsetService._();

  static final Map<String, num> _offsets = {};
  static final Map<String, Future<num>> _pending = {};

  /// Offset in km for [imei]; 0 when it can't be worked out.
  static Future<num> offsetFor(String imei) {
    final key = imei.trim();
    if (key.isEmpty) return Future.value(0);
    final known = _offsets[key];
    if (known != null) return Future.value(known);
    return _pending[key] ??= _fetch(key).whenComplete(() => _pending.remove(key));
  }

  /// Call after the user changes a vehicle's odometer.
  static void forget(String imei) => _offsets.remove(imei.trim());

  static Future<num> _fetch(String imei) async {
    try {
      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei},
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      final position = data is Map ? data['position'] : null;
      final odometer = _num(position is Map ? position['odometer'] : null);
      final kilometer = _num(position is Map ? position['kilometer'] : null);
      if (odometer == null || kilometer == null) return 0;
      final offset = odometer - kilometer;
      _offsets[imei] = offset;
      return offset;
    } catch (e) {
      debugPrint('[Odometer] offset unavailable: $e');
      return 0;
    }
  }

  static num? _num(dynamic raw) {
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }

  static const _keys = [
    'odometer_km',
    'odometer',
    'start_odometer',
    'odometer_start',
    'start_odo',
    'start_odometer_km',
    'end_odometer',
    'odometer_end',
    'end_odo',
    'end_odometer_km',
  ];

  /// Adds [offset] to the odometer fields of a report / statistics row.
  static Map<String, dynamic> applyTo(Map<String, dynamic> row, num offset) {
    if (offset == 0) return row;
    final out = Map<String, dynamic>.from(row);
    for (final key in _keys) {
      final value = _num(out[key]);
      if (value != null) {
        out[key] = double.parse((value + offset).toStringAsFixed(2));
      }
    }
    return out;
  }
}
