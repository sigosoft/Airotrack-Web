import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../utils/app_toast.dart';

/// A `{key, label}` option from the server (types, statuses, payment methods...).
class LookupOption {
  final String key;
  final String label;

  const LookupOption(this.key, this.label);

  static List<LookupOption> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => LookupOption(
            (e['key'] ?? '').toString(),
            (e['label'] ?? e['key'] ?? '').toString(),
          ),
        )
        .where((o) => o.key.isNotEmpty)
        .toList();
  }
}

/// A vehicle from GET /vehicles.
class VehicleOption {
  final int id;
  final String vehicleNumber;
  final String imei;

  const VehicleOption({
    required this.id,
    required this.vehicleNumber,
    required this.imei,
  });

  factory VehicleOption.fromJson(Map json) => VehicleOption(
    id: int.tryParse('${json['id']}') ?? 0,
    vehicleNumber: (json['vehicle_number'] ?? '').toString(),
    imei: (json['imei'] ?? '').toString(),
  );
}

/// Shared helpers for the lookup endpoints and the common
/// `{status, data, message}` response envelope.
class LookupsService {
  LookupsService._();

  static List<VehicleOption>? _vehiclesCache;

  /// GET /vehicles (cached for the session; pass [refresh] to reload).
  static Future<List<VehicleOption>> vehicles({bool refresh = false}) async {
    if (!refresh && _vehiclesCache != null) return _vehiclesCache!;
    try {
      final response = await DioClient().get(ApiEndPoints.vehicles);
      final data = dataOf(response);
      final list = data is Map ? data['vehicles'] : null;
      if (list is List) {
        _vehiclesCache = list
            .whereType<Map>()
            .map(VehicleOption.fromJson)
            .where((v) => v.vehicleNumber.trim().isNotEmpty)
            .toList();
        return _vehiclesCache!;
      }
    } catch (e) {
      debugPrint('[Lookups] vehicles failed: $e');
    }
    return _vehiclesCache ?? const [];
  }

  static void clearCache() => _vehiclesCache = null;

  /// The `data` field of a response, or null.
  static dynamic dataOf(Response response) {
    final body = response.data;
    return body is Map ? body['data'] : null;
  }

  /// True when the server reports success (`status: true` or `"true"`).
  static bool isOk(Response response) {
    final body = response.data;
    if (body is! Map) return false;
    final s = body['status'];
    return s == true || s == 'true' || s == 1;
  }

  /// A readable message from the response (handles validation maps).
  static String messageOf(Response response, {String fallback = ''}) {
    final body = response.data;
    if (body is Map && body['message'] != null) {
      final msg = AppToast.cleanMessage(body['message']);
      if (msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}
