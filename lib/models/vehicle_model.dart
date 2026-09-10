import '../config/api_config.dart';

class Vehicle {
  final int id;
  final String plateNumber;
  final String status; // 'Running', 'Stopped', 'Idle', 'Inactive'
  final String statusDuration;
  final String lastUpdated;
  /// Place name from API `location` (home endpoint).
  final String address;
  final double? latitude;
  final double? longitude;
  final String speed;
  final String distance;
  /// Today's traveled km from API `today_km`.
  final String todayKm;
  final String validityDays;
  final bool isIgnitionOn;
  final bool isLocked;
  final String deviceId;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.status,
    required this.statusDuration,
    required this.lastUpdated,
    required this.address,
    this.latitude,
    this.longitude,
    required this.speed,
    required this.distance,
    required this.todayKm,
    required this.validityDays,
    this.isIgnitionOn = false,
    this.isLocked = true,
    required this.deviceId,
  });

  bool get hasValidCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    return !(lat == 0 && lng == 0);
  }

  /// Display text from API `location` (no client reverse-geocode).
  String get locationLabel {
    final text = address.trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    return 'Location unavailable';
  }

  Vehicle copyWith({
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return Vehicle(
      id: id,
      plateNumber: plateNumber,
      status: status,
      statusDuration: statusDuration,
      lastUpdated: lastUpdated,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed,
      distance: distance,
      todayKm: todayKm,
      validityDays: validityDays,
      isIgnitionOn: isIgnitionOn,
      isLocked: isLocked,
      deviceId: deviceId,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final mode = json['mode']?.toString().toUpperCase();
    final speed = double.tryParse(json['speed']?.toString() ?? '0') ?? 0;
    final ignitionRaw = json['ignition'];
    final ignition = ignitionRaw == 1 ||
        ignitionRaw == true ||
        ignitionRaw?.toString() == '1';

    // Prefer explicit status string from API when present (not bool flags).
    final rawStatus =
        json['current_status'] ?? json['vehicle_status'] ?? json['status'];
    final apiStatus = rawStatus is String ? rawStatus.trim() : null;

    final derivedStatus = _resolveVehicleStatus(
      apiStatus: apiStatus,
      mode: mode,
      speed: speed,
      ignition: ignition,
    );

    final lat = double.tryParse(json['latitude']?.toString() ?? '');
    final lng = double.tryParse(json['longitude']?.toString() ?? '');

    // API `location` only (no reverse-geocode / no address fallbacks).
    final locationRaw = json['location'];
    String address = '';
    if (locationRaw is String) {
      final text = locationRaw.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        address = text;
      }
    }

    return Vehicle(
      id: json['id'] ?? 0,
      plateNumber: json['vehicle_number'] ?? json['name'] ?? '',
      status: derivedStatus,
      statusDuration: json['duration'] ?? '',
      lastUpdated: json['last_update'] ?? json['device_time'] ?? '',
      address: address,
      latitude: lat,
      longitude: lng,
      speed: speed.toStringAsFixed(1),
      distance: (json['distance'] ?? 0).toString(),
      todayKm: _formatTodayKm(
        json['today_km'] ??
            json['total_kilometers_today'] ??
            json['todayKm'] ??
            json['distance'],
      ),
      validityDays: _daysFromExpiration(
        json['expirationtime'] ??
            json['expiration_time'] ??
            json['expirationTime'],
      ),
      isIgnitionOn: ignition,
      isLocked: json['lock'] != 0,
      deviceId: (json['imei'] ?? json['device_id'] ?? '').toString(),
    );
  }

  static String _formatTodayKm(dynamic raw) {
    final value = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '') ?? 0.0;
    if (value == value.roundToDouble()) {
      return '${value.toInt()} Km';
    }
    return '${value.toStringAsFixed(2)} Km';
  }

  /// Days between today and `expirationtime` (calendar days remaining).
  /// Returns `0` when `expirationtime` is missing or invalid.
  static String _daysFromExpiration(dynamic expirationRaw, {dynamic fallback}) {
    final expiry = _parseExpirationDate(expirationRaw);
    if (expiry == null) return '0';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiry.year, expiry.month, expiry.day);
    final days = end.difference(today).inDays;
    return days < 0 ? '0' : days.toString();
  }

  static DateTime? _parseExpirationDate(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    // Common API form: "yyyy-MM-dd HH:mm:ss"
    final withT = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (withT != null) return withT;

    final parts = text.split(RegExp(r'[/\-.]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2].split(RegExp(r'\s')).first);
      if (a != null && b != null && c != null) {
        // yyyy-MM-dd vs dd-MM-yyyy
        if (parts[0].length == 4) {
          return DateTime(a, b, c);
        }
        if (parts[2].length == 4) {
          return DateTime(c, b, a);
        }
      }
    }
    return null;
  }

  /// Aligns with live-track modes: M/R = Running, H/I = Idle, S = Stopped.
  static String _resolveVehicleStatus({
    String? apiStatus,
    String? mode,
    required double speed,
    required bool ignition,
  }) {
    if (apiStatus != null && apiStatus.isNotEmpty) {
      final s = apiStatus.toLowerCase();
      if (s.contains('inactive') || s.contains('expired')) return 'Inactive';
      if (s.contains('run') || s.contains('mov')) return 'Running';
      if (s.contains('idle')) return 'Idle';
      if (s.contains('stop')) return 'Stopped';
    }

    final m = mode?.toUpperCase();
    if (m == 'INACTIVE' || m == 'EXPIRED') return 'Inactive';
    // Mode is authoritative — do not override Stopped with noisy speed.
    if (m == 'M' || m == 'R' || m == 'RUNNING' || m == 'MOVING') {
      return 'Running';
    }
    if (m == 'H' || m == 'I' || m == 'IDLE') return 'Idle';
    if (m == 'S' || m == 'STOPPED' || m == 'STOP') return 'Stopped';

    // Fallback when mode is missing.
    if (speed > 1.0) return 'Running';
    if (ignition) return 'Idle';
    return 'Stopped';
  }
}
