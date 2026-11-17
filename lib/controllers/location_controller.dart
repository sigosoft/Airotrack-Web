import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/vehicle_model.dart';
import 'home_controller.dart';

enum AiroMapStyle {
  mapboxStreets,
  mapboxSatellite,
  mapboxOutdoors,
  osm;

  String get displayName {
    switch (this) {
      case AiroMapStyle.mapboxStreets:
        return 'Streets';
      case AiroMapStyle.mapboxSatellite:
        return 'Satellite';
      case AiroMapStyle.mapboxOutdoors:
        return 'Terrain';
      case AiroMapStyle.osm:
        return 'OpenStreetMap';
    }
  }

  String tileUrl(bool trafficEnabled) {
    final token = ApiConfig.mapboxAccessToken;
    if (token.isEmpty) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }

    if (trafficEnabled) {
      return 'https://api.mapbox.com/styles/v1/mapbox/traffic-day-v2/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
    }

    switch (this) {
      case AiroMapStyle.mapboxStreets:
        return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
      case AiroMapStyle.mapboxSatellite:
        return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
      case AiroMapStyle.mapboxOutdoors:
        return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
      case AiroMapStyle.osm:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
}

enum VehicleMarkerStatus {
  running,
  idle,
  stopped,
  expired,
  inactive,
  noData;

  Color get color {
    switch (this) {
      case VehicleMarkerStatus.running:
        return const Color(0xFF00C853); // #00C853 Green
      case VehicleMarkerStatus.idle:
        return const Color(0xFFFFD600); // #FFD600 Yellow
      case VehicleMarkerStatus.stopped:
        return const Color(0xFFFF3D00); // #FF3D00 Red
      case VehicleMarkerStatus.expired:
        return const Color(0xFFFF9100); // #FF9100 Orange
      case VehicleMarkerStatus.inactive:
        return const Color(0xFF2196F3); // Colors.blue
      case VehicleMarkerStatus.noData:
        return const Color(0xFF9E9E9E); // Colors.grey
    }
  }

  String get label {
    switch (this) {
      case VehicleMarkerStatus.running:
        return 'Running';
      case VehicleMarkerStatus.idle:
        return 'Idle';
      case VehicleMarkerStatus.stopped:
        return 'Stopped';
      case VehicleMarkerStatus.expired:
        return 'Expired';
      case VehicleMarkerStatus.inactive:
        return 'Inactive';
      case VehicleMarkerStatus.noData:
        return 'No data';
    }
  }

  String get assetPath {
    switch (this) {
      case VehicleMarkerStatus.running:
        return 'lib/assets/images/Green right Car.png';
      case VehicleMarkerStatus.idle:
        return 'lib/assets/images/Idle_yellow_rightcar.png';
      case VehicleMarkerStatus.stopped:
        return 'lib/assets/images/Red right Car.png';
      case VehicleMarkerStatus.expired:
        return 'lib/assets/images/Expired_GlossyOrange_rightcar.png';
      case VehicleMarkerStatus.inactive:
        return 'lib/assets/images/Inactive_blue_rightcar.png';
      case VehicleMarkerStatus.noData:
        return 'lib/assets/images/No data_grey_rightcar.png';
    }
  }

  String get fallbackAssetPath {
    switch (this) {
      case VehicleMarkerStatus.running:
        return 'lib/assets/images/Green Car.png';
      case VehicleMarkerStatus.stopped:
        return 'lib/assets/images/Red Car.png';
      default:
        return 'lib/assets/images/Car image.png';
    }
  }
}

VehicleMarkerStatus evaluateVehicleStatus(Vehicle v) {
  final s = v.status.toLowerCase();
  if (s.contains('expired')) return VehicleMarkerStatus.expired;
  if (s.contains('inactive')) return VehicleMarkerStatus.inactive;
  if (s.contains('no data') || s.contains('nodata')) {
    return VehicleMarkerStatus.noData;
  }

  final speedVal =
      double.tryParse(v.speed.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  if (v.isIgnitionOn) {
    if (speedVal > 0) return VehicleMarkerStatus.running;
    return VehicleMarkerStatus.idle;
  } else {
    if (s.contains('run') || s.contains('moving')) {
      return VehicleMarkerStatus.running;
    }
    if (s.contains('idle')) return VehicleMarkerStatus.idle;
    return VehicleMarkerStatus.stopped;
  }
}

class VehicleGroup {
  final Vehicle anchor;
  final List<Vehicle> vehicles;
  final double pixelX;
  final double pixelY;

  VehicleGroup({
    required this.anchor,
    required this.vehicles,
    required this.pixelX,
    required this.pixelY,
  });
}

class LocationController extends GetxController {
  static const double _minZoom = 3.0;
  static const double _maxZoom = 19.0;
  static const String _kMapTypeKey = 'set_map_type';

  MapController? _mapController;
  MapController? get mapController => _mapController;

  late final HomeController _home;

  final Rx<AiroMapStyle> currentStyle = AiroMapStyle.mapboxStreets.obs;
  final RxBool trafficEnabled = false.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxString selectedVehicleId = ''.obs;
  final RxBool _following = false.obs;
  bool get isFollowing => _following.value;

  LatLng? lastCenter;
  double lastZoom = 13.0;
  final RxDouble currentZoomStep = 13.0.obs;

  final RxString searchQuery = ''.obs;

  Worker? _vehiclesWorker;

  @override
  void onInit() {
    super.onInit();
    _home = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    _loadPreferences();

    _vehiclesWorker = ever(_home.allVehicles, (_) => _onVehiclesChanged());
  }

  @override
  void onClose() {
    _vehiclesWorker?.dispose();
    super.onClose();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapType = prefs.getString(_kMapTypeKey);
      if (mapType != null) {
        if (mapType == 'satellite') {
          currentStyle.value = AiroMapStyle.mapboxSatellite;
        } else if (mapType == 'terrain' || mapType == 'outdoors') {
          currentStyle.value = AiroMapStyle.mapboxOutdoors;
        } else if (mapType == 'osm') {
          currentStyle.value = AiroMapStyle.osm;
        } else {
          currentStyle.value = AiroMapStyle.mapboxStreets;
        }
      }
    } catch (_) {}
  }

  void attachMap(MapController controller) {
    _mapController = controller;
  }

  void detachMap(MapController controller) {
    if (_mapController == controller) {
      _mapController = null;
    }
  }

  void onMapReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (lastCenter != null) {
        _mapController?.move(lastCenter!, lastZoom);
      } else {
        fitAll();
      }
    });
  }

  void onPositionChanged(MapPosition position, bool hasGesture) {
    if (position.center != null) lastCenter = position.center;
    if (position.zoom != null) lastZoom = position.zoom!;

    final currentZ = position.zoom ?? lastZoom;
    final step = (currentZ * 2).round() / 2.0;
    if ((step - currentZoomStep.value).abs() >= 0.25) {
      currentZoomStep.value = step;
    }

    if (hasGesture) {
      _following.value = false;
    }
  }

  void _onVehiclesChanged() {
    if (_following.value && selectedVehicleId.value.isNotEmpty) {
      final match = _home.vehicles.firstWhereOrNull(
        (v) => v.deviceId == selectedVehicleId.value,
      );
      if (match != null && match.hasValidCoordinates) {
        _mapController?.move(
          LatLng(match.latitude!, match.longitude!),
          max(lastZoom, 15.0),
        );
      }
    }
  }

  List<Vehicle> get mapVehicles {
    return _home.vehicles.where((v) => v.hasValidCoordinates).toList();
  }

  List<Vehicle> get visibleVehicles {
    var list = mapVehicles;
    final filter = selectedFilter.value;

    if (filter != 'All') {
      list = list.where((v) {
        final st = evaluateVehicleStatus(v);
        return st.label.toLowerCase() == filter.toLowerCase();
      }).toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((v) {
        return v.plateNumber.toLowerCase().contains(query) ||
            v.deviceId.toLowerCase().contains(query) ||
            v.address.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  int countFor(String filter) {
    if (filter == 'All') return mapVehicles.length;
    return mapVehicles.where((v) {
      final st = evaluateVehicleStatus(v);
      return st.label.toLowerCase() == filter.toLowerCase();
    }).length;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitAll();
    });
  }

  void setSearchQuery(String q) {
    searchQuery.value = q;
  }

  void fitAll() {
    final points = visibleVehicles
        .where((v) => v.hasValidCoordinates)
        .map((v) => LatLng(v.latitude!, v.longitude!))
        .toList();

    if (points.isEmpty) {
      if (lastCenter != null) {
        _mapController?.move(lastCenter!, lastZoom);
      } else {
        _mapController?.move(const LatLng(20.5937, 78.9629), 5.0);
      }
      return;
    }

    if (points.length == 1) {
      _mapController?.move(points.first, 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController?.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(80, 200, 90, 200),
      ),
    );
  }

  void zoomIn() {
    if (_mapController == null) return;
    final z = (_mapController!.camera.zoom + 1.0).clamp(_minZoom, _maxZoom);
    _mapController!.move(_mapController!.camera.center, z);
  }

  void zoomOut() {
    if (_mapController == null) return;
    final z = (_mapController!.camera.zoom - 1.0).clamp(_minZoom, _maxZoom);
    _mapController!.move(_mapController!.camera.center, z);
  }

  void selectVehicle(Vehicle v) {
    selectedVehicleId.value = v.deviceId;
    _following.value = true;
    if (v.hasValidCoordinates) {
      final targetZoom = max(_mapController?.camera.zoom ?? 13.0, 15.0);
      _mapController?.move(LatLng(v.latitude!, v.longitude!), targetZoom);
    }
  }

  void cycleMapStyle() {
    switch (currentStyle.value) {
      case AiroMapStyle.mapboxStreets:
        currentStyle.value = AiroMapStyle.mapboxSatellite;
        break;
      case AiroMapStyle.mapboxSatellite:
        currentStyle.value = AiroMapStyle.mapboxOutdoors;
        break;
      case AiroMapStyle.mapboxOutdoors:
        currentStyle.value = AiroMapStyle.mapboxStreets;
        break;
      case AiroMapStyle.osm:
        currentStyle.value = AiroMapStyle.mapboxStreets;
        break;
    }
    trafficEnabled.value = false;
    _saveMapStyle();
  }

  void toggleTraffic() {
    trafficEnabled.value = !trafficEnabled.value;
  }

  Future<void> _saveMapStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'streets';
      if (currentStyle.value == AiroMapStyle.mapboxSatellite) {
        val = 'satellite';
      } else if (currentStyle.value == AiroMapStyle.mapboxOutdoors) {
        val = 'terrain';
      } else if (currentStyle.value == AiroMapStyle.osm) {
        val = 'osm';
      }
      await prefs.setString(_kMapTypeKey, val);
    } catch (_) {}
  }

  static Offset _toPixel(LatLng latLng, double zoom) {
    final scale = 256.0 * pow(2.0, zoom);
    final lng = latLng.longitude;
    final lat = latLng.latitude.clamp(-85.05112878, 85.05112878);
    final latRad = lat * pi / 180.0;

    final x = ((lng + 180.0) / 360.0) * scale;
    final secLat = 1.0 / cos(latRad);
    final tanLat = tan(latRad);
    final term = (tanLat + secLat).clamp(0.000001, 1000000.0);
    final y = (1.0 - (log(term) / pi)) / 2.0 * scale;
    return Offset(x, y);
  }

  List<VehicleGroup> groupedVehicles(double zoom) {
    final list = visibleVehicles;
    if (list.isEmpty) return [];

    const maxDx = 140.0;
    const maxDy = 60.0;

    final groups = <VehicleGroup>[];

    for (final v in list) {
      if (!v.hasValidCoordinates) continue;
      final pt = LatLng(v.latitude!, v.longitude!);
      final pixel = _toPixel(pt, zoom);

      bool merged = false;
      for (final g in groups) {
        if ((pixel.dx - g.pixelX).abs() <= maxDx &&
            (pixel.dy - g.pixelY).abs() <= maxDy) {
          g.vehicles.add(v);
          merged = true;
          break;
        }
      }

      if (!merged) {
        groups.add(
          VehicleGroup(
            anchor: v,
            vehicles: [v],
            pixelX: pixel.dx,
            pixelY: pixel.dy,
          ),
        );
      }
    }

    return groups;
  }
}
