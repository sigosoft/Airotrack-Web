import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A geofence from the API, same fields the mobile app reads:
/// `type` circle | rectangle | polygon, `radius` and `tolerance` in km,
/// `event_type` 1 = Entry, 2 = Exit, 3 = Both, `coordinates` [{lat, lng}]
/// (rectangle: two opposite corners; polygon: every corner).
class GeofenceModel {
  final int id;
  final String name;

  /// 'circle' | 'rectangle' | 'polygon'
  final String shape;
  final String address;
  final String description;
  final double? latitude;
  final double? longitude;

  /// Circle radius in km.
  final double radius;

  /// Tolerance in km.
  final double tolerance;

  /// 1 = Entry, 2 = Exit, 3 = Both
  final int eventCode;
  final List<LatLng> coordinates;

  GeofenceModel({
    required this.id,
    required this.name,
    required this.shape,
    required this.address,
    required this.description,
    this.latitude,
    this.longitude,
    this.radius = 0.0,
    this.tolerance = 0.0,
    this.eventCode = 3,
    this.coordinates = const [],
  });

  /// Display name of the shape: Circle / Rectangle / Polygon.
  String get type => shape.isEmpty
      ? 'Circle'
      : '${shape[0].toUpperCase()}${shape.substring(1)}';

  static const Map<int, String> eventLabels = {
    1: 'Entry',
    2: 'Exit',
    3: 'Both',
  };

  String get eventType => eventLabels[eventCode] ?? 'Both';

  double get radiusMeters => radius * 1000;
  double get toleranceMeters => tolerance * 1000;

  /// Centre of the fence (circle centre, or the middle of the corners).
  LatLng? get center {
    if (shape == 'circle' && latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    final pts = outline;
    if (pts.isNotEmpty) {
      final lat =
          pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
      final lng =
          pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
      return LatLng(lat, lng);
    }
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  /// Corners to draw: a rectangle's two saved corners become four.
  List<LatLng> get outline {
    if (shape == 'rectangle' && coordinates.length == 2) {
      return rectangleFromCorners(coordinates[0], coordinates[1]);
    }
    return coordinates;
  }

  static List<LatLng> rectangleFromCorners(LatLng a, LatLng b) {
    final north = math.max(a.latitude, b.latitude);
    final south = math.min(a.latitude, b.latitude);
    final west = math.min(a.longitude, b.longitude);
    final east = math.max(a.longitude, b.longitude);
    return [
      LatLng(north, west),
      LatLng(north, east),
      LatLng(south, east),
      LatLng(south, west),
    ];
  }

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    final t = (json['type'] ?? '').toString().toLowerCase();
    final shape = switch (t) {
      '2' || 'polygon' => 'polygon',
      '3' || 'rectangle' => 'rectangle',
      _ => 'circle',
    };

    final coords = <LatLng>[];
    final raw = json['coordinates'];
    if (raw is List) {
      for (final c in raw) {
        if (c is! Map) continue;
        final lat = double.tryParse('${c['lat']}');
        final lng = double.tryParse('${c['lng']}');
        if (lat != null && lng != null) coords.add(LatLng(lat, lng));
      }
    }

    final event = json['event_type']?.toString().toLowerCase() ?? '3';
    final eventCode = switch (event) {
      '1' || 'entry' => 1,
      '2' || 'exit' => 2,
      _ => 3,
    };

    return GeofenceModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? json['geofence_name'] ?? '').toString(),
      shape: shape,
      address: (json['address'] ?? json['location'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      latitude: double.tryParse(
        (json['latitude'] ?? json['lat'] ?? '').toString(),
      ),
      longitude: double.tryParse(
        (json['longitude'] ?? json['lng'] ?? '').toString(),
      ),
      radius: double.tryParse('${json['radius']}') ?? 0.0,
      tolerance: double.tryParse('${json['tolerance']}') ?? 0.0,
      eventCode: eventCode,
      coordinates: coords,
    );
  }
}

class GeofenceVehicleItem {
  final int id;
  final String name;
  final String vehicleNumber;
  bool isSelected;

  GeofenceVehicleItem({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    this.isSelected = false,
  });

  factory GeofenceVehicleItem.fromJson(Map<String, dynamic> json, {bool isSelected = false}) {
    return GeofenceVehicleItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      vehicleNumber: (json['vehicle_number'] ?? json['plate_number'] ?? json['name'] ?? '').toString(),
      isSelected: isSelected,
    );
  }
}
