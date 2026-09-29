import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/live_track_model.dart';
import '../models/vehicle_detail_model.dart';
import '../models/vehicle_model.dart';
import '../services/directions_service.dart';
import '../services/live_track_websocket_service.dart';
import '../utils/app_toast.dart';
import 'alerts_controller.dart';
import 'dashboard_controller.dart';
import 'home_controller.dart';

class VehicleDetailController extends GetxController {
  final RxInt selectedTopTab =
      (-1).obs; // -1: Vehicle Info Detail, 0: History, 1: Alerts, 2: Statistics
  final RxBool isMapDialogVisible = false.obs;
  final RxBool isHistoryMapDialogVisible = false.obs;

  // Live Tracking Motion & Real-Time Engine
  final Rxn<LatLng> liveMarkerPosition = Rxn<LatLng>();
  final RxDouble liveMarkerBearing = 0.0.obs;
  final RxBool isLiveMoving = false.obs;
  final RxBool isLiveTrackingConnected = false.obs;
  final RxBool isLiveLocked = true.obs;
  final RxList<LatLng> liveRoadPolyline = <LatLng>[].obs;
  final MapController liveMapController = MapController();

  final LiveTrackWebSocketService _liveTrackWs = LiveTrackWebSocketService();
  final DirectionsService _directionsService = DirectionsService();

  LiveWebsocketConfig? _wsConfig;
  LiveWebsocketInfo? _wsInfo;

  Timer? _liveAnimationTimer;
  DateTime? _lastLiveTickTime;

  // Live Tracking Waypoint Motion Engine
  final List<LatLng> _liveWaypoints = [];
  int _liveWaypointIndex = 0;
  double _liveWaypointFraction = 0.0;
  double _currentLiveSpeedMs = 0.0;
  LatLng? _lastAcceptedGps;
  DateTime? _lastGpsTime;
  double _lastReportedSpeedKmh = 0.0;
  double _expectedPingSec = 4.0;
  Timer? _livePollingTimer;
  DateTime _lastLiveUpdateReceivedAt = DateTime.now();
  bool _liveDisposed = false;
  bool _roadFetchInFlight = false;
  final List<LatLng> _lastRoadCorridor = [];

  // Live session guards (prevent restarts / stale async results from resetting motion)
  int _liveSessionId = 0;
  String? _liveTrackingImei;
  DateTime? _lastLiveFixTime;

  // A fix older than this is shown as not moving (speed 0) instead of
  // repeating the last reported speed while the device is silent.
  static const Duration _liveStaleAfter = Duration(minutes: 2);

  // History Playback Engine
  final RxDouble playbackProgress = 0.0.obs;
  final RxBool isPlaying = false.obs;
  final RxString playbackSpeed = '1x'.obs;
  final RxDouble playbackSpeedMultiplier = 1.0.obs;
  final Rxn<LatLng> movingMarkerPosition = Rxn<LatLng>();
  final Rxn<double> movingMarkerBearing = Rxn<double>();
  final MapController historyMapController = MapController();
  final RxList<LatLng> traveledRoutePoints = <LatLng>[].obs;
  Timer? _movingMarkerTimer;
  int _movingSegmentIndex = 0;
  double _movingSegmentFraction = 0.0;
  int _lastCameraUpdateMs = 0;
  List<LatLng> _playbackRoutePoints = [];
  List<double> _playbackSpeedSeries = <double>[];

  static const Duration _playbackFramePeriod = Duration(milliseconds: 16);
  static const double _playbackTickSeconds = 0.016;
  // History playback pace at 1x is defined on screen: the car moves about
  // this many pixels per second at whatever zoom the map is on, so it is
  // always visibly moving but never jumps. 1.5x / 2x multiply this.
  static const double _playbackScreenPxPerSec = 45.0;
  static const double _playbackMinMps = 8.0;
  static const double _playbackMaxMps = 600.0;
  DateTime? _lastPlaybackTickAt;
  static const double _bearingSmoothing = 0.35;
  static String _formatInitialDate(DateTime dt, {bool isStart = true}) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    if (isStart) {
      return '$day-$month-$year 12:00 AM';
    } else {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:$minute $period';
    }
  }

  late final RxString startDateStr = _formatInitialDate(
    DateTime.now(),
    isStart: true,
  ).obs;
  late final RxString endDateStr = _formatInitialDate(
    DateTime.now(),
    isStart: false,
  ).obs;

  final RxBool isLoading = false.obs;
  final RxBool isStatisticsLoading = false.obs;
  final historyPoints = <Map<String, dynamic>>[].obs;
  final liveTrackData = <String, dynamic>{}.obs;

  // Dynamic History Metadata & Trips
  final RxMap<String, dynamic> historyResponseData = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> historyTrips =
      <Map<String, dynamic>>[].obs;
  final RxDouble currentPlaybackSpeedKmph = 0.0.obs;

  String get historyDisplaySpeed {
    if (isPlaying.value) {
      return currentPlaybackSpeedKmph.value.toStringAsFixed(1);
    }
    if (_playbackSpeedSeries.isNotEmpty) {
      final validSpeeds = _playbackSpeedSeries.where((s) => s > 0).toList();
      if (validSpeeds.isNotEmpty) {
        final avg = validSpeeds.reduce((a, b) => a + b) / validSpeeds.length;
        return avg.toStringAsFixed(1);
      }
    }
    final metaAvg =
        historyResponseData['average_speed'] ??
        historyResponseData['avg_speed'] ??
        statisticsData['Average Speed'];
    if (metaAvg != null && metaAvg.toString().isNotEmpty) {
      final clean = metaAvg.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      if (clean.isNotEmpty) return clean;
    }
    return vehicleDetail.value.speedKmph.toString();
  }

  String get historyDisplayDuration {
    if (historyTrips.isNotEmpty) {
      final firstStart = historyTrips.first['startTime'];
      final lastEnd = historyTrips.last['endTime'];
      final sDt = _parseTimestamp(firstStart);
      final eDt = _parseTimestamp(lastEnd);
      if (sDt != null && eDt != null) {
        return _formatDuration(eDt.difference(sDt));
      }
      return historyTrips.first['duration'] ?? '00:00:00';
    }
    if (historyPoints.length >= 2) {
      final sDt = _parseTimestamp(
        historyPoints.first['device_time'] ?? historyPoints.first['created_at'],
      );
      final eDt = _parseTimestamp(
        historyPoints.last['device_time'] ?? historyPoints.last['created_at'],
      );
      if (sDt != null && eDt != null) {
        return _formatDuration(eDt.difference(sDt));
      }
    }
    final metaDur =
        historyResponseData['duration'] ??
        historyResponseData['total_duration'] ??
        statisticsData['Move Duration'];
    if (metaDur != null &&
        metaDur.toString().isNotEmpty &&
        metaDur.toString() != '00:00:00') {
      return metaDur.toString();
    }
    return vehicleDetail.value.runningDuration.isNotEmpty
        ? vehicleDetail.value.runningDuration
        : '00:00:00';
  }

  String get historyDisplayDistance {
    final route = getActiveRoutePoints();
    if (route.length >= 2) {
      final km = _getTotalDistanceKm(route);
      return '${km.toStringAsFixed(2)} Km';
    }
    final metaDist =
        historyResponseData['distance'] ??
        historyResponseData['total_distance'] ??
        statisticsData['Route Length'];
    if (metaDist != null &&
        metaDist.toString().isNotEmpty &&
        metaDist.toString() != '0 km') {
      return metaDist.toString().contains('Km')
          ? metaDist.toString()
          : '$metaDist Km';
    }
    return vehicleDetail.value.distanceKm.isNotEmpty
        ? vehicleDetail.value.distanceKm
        : '0.0 Km';
  }

  String get historyDialogDeviceTime {
    if (historyPoints.isNotEmpty) {
      final idx = _movingSegmentIndex.clamp(0, historyPoints.length - 1);
      final pt = historyPoints[idx];
      final val =
          pt['device_time'] ??
          pt['created_at'] ??
          pt['timestamp'] ??
          pt['time'];
      if (val != null && val.toString().trim().isNotEmpty) {
        return formatDisplayTime(val.toString());
      }
    }
    return vehicleDetail.value.deviceTime.isNotEmpty
        ? vehicleDetail.value.deviceTime
        : 'N/A';
  }

  String get historyDialogServerTime {
    if (historyPoints.isNotEmpty) {
      final idx = _movingSegmentIndex.clamp(0, historyPoints.length - 1);
      final pt = historyPoints[idx];
      final val = pt['server_time'] ?? pt['updated_at'];
      if (val != null && val.toString().trim().isNotEmpty) {
        return formatDisplayTime(val.toString());
      }
    }
    return vehicleDetail.value.serverTime.isNotEmpty
        ? vehicleDetail.value.serverTime
        : 'N/A';
  }

  String get historyDialogDuration {
    return historyDisplayDuration;
  }

  String get historyDialogAddress {
    if (historyPoints.isNotEmpty) {
      final idx = _movingSegmentIndex.clamp(0, historyPoints.length - 1);
      final pt = historyPoints[idx];
      final addr = pt['address'] ?? pt['location'];
      if (addr != null && addr.toString().trim().isNotEmpty && addr != 'null') {
        return addr.toString();
      }
    }
    return vehicleDetail.value.address.isNotEmpty
        ? vehicleDetail.value.address
        : 'Fetching location...';
  }

  DateTime? _parseTimestamp(dynamic timeVal) {
    if (timeVal == null) return null;
    final str = timeVal.toString().trim();
    if (str.isEmpty || str == '-' || str == 'N/A') return null;

    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    try {
      final parts = str.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          int p1 = int.parse(dateParts[0]);
          int p2 = int.parse(dateParts[1]);
          int p3 = int.parse(dateParts[2]);
          int year = p3 > 1000 ? p3 : p1;
          int day = p3 > 1000 ? p1 : p3;
          int month = p2;
          final timeParts = parts[1].split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          if (parts.length > 2 && parts[2].toUpperCase() == 'PM' && hour < 12) {
            hour += 12;
          } else if (parts.length > 2 &&
              parts[2].toUpperCase() == 'AM' &&
              hour == 12) {
            hour = 0;
          }
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (_) {}
    return null;
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) d = -d;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  String formatDisplayTime(String raw) {
    if (raw.trim().isEmpty || raw == '-' || raw == 'N/A') return '-';
    final dt = _parseTimestamp(raw);
    if (dt != null) {
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:$minute:$second $period';
    }
    return raw;
  }

  final RxMap<String, String> statisticsData = <String, String>{
    'Route Length': '0 km',
    'Move Duration': '00:00:00',
    'Idle Duration': '00:00:00',
    'Stop Duration': '00:00:00',
    'Stop Count': '0',
    'Average Speed': '0 kmph',
    'Top Speed': '0 kmph',
    'Over Speed Count': '0',
    'Engine Hours': '00:00:00',
    'Odometer': '0 km',
  }.obs;

  String activeImei = '';

  final Rx<VehicleDetailData> vehicleDetail = VehicleDetailData(
    vehicleNumber: 'Loading...',
    odometerDigits: '0000000',
    timestamp: 'N/A',
    distanceKm: '0 km',
    speedKmph: 0,
    coordinates: 'N/A',
    address: 'Fetching location...',
    deviceTime: 'N/A',
    serverTime: 'N/A',
    runningDuration: 'N/A',
    idleDuration: 'N/A',
    stoppedDuration: 'N/A',
    inactiveDuration: 'N/A',
    avgSpeedKmph: '0',
    maxSpeedKmph: '0',
    todayOdoKm: '0',
    sensors: [
      SensorReadingItem(label: 'Battery', value: '-', iconType: 'battery'),
      SensorReadingItem(
        label: 'Car Battery',
        value: '-',
        iconType: 'car_battery',
      ),
      SensorReadingItem(label: 'Satellite', value: '-', iconType: 'satellite'),
      SensorReadingItem(label: 'Fuel', value: '-', iconType: 'fuel'),
      SensorReadingItem(label: 'Accuracy', value: '-', iconType: 'accuracy'),
      SensorReadingItem(label: 'Temperature', value: '-', iconType: 'temp'),
      SensorReadingItem(label: 'Movement', value: '-', iconType: 'movement'),
      SensorReadingItem(label: 'Movement', value: '-', iconType: 'movement2'),
    ],
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _startLiveAnimationLoop();
    _bindToHomeController();
    placeMovingMarkerAtStart();
  }

  void _bindToHomeController() {
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      if (homeCtrl.vehicles.isNotEmpty) {
        final dashCtrl = Get.isRegistered<DashboardController>()
            ? Get.find<DashboardController>()
            : null;
        final idx =
            (dashCtrl != null &&
                dashCtrl.selectedVehicleIndex.value < homeCtrl.vehicles.length)
            ? dashCtrl.selectedVehicleIndex.value
            : 0;
        updateFromVehicle(homeCtrl.vehicles[idx]);
      }
      ever(homeCtrl.vehicles, (List<Vehicle> list) {
        if (list.isNotEmpty) {
          final dashCtrl = Get.isRegistered<DashboardController>()
              ? Get.find<DashboardController>()
              : null;
          final idx =
              (dashCtrl != null &&
                  dashCtrl.selectedVehicleIndex.value < list.length)
              ? dashCtrl.selectedVehicleIndex.value
              : 0;
          updateFromVehicle(list[idx]);
        }
      });
    }
  }

  String _extractOdometerDigits(dynamic val, {dynamic fallback}) {
    String? tryParse(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      if (str.isEmpty || str == '-' || str == 'N/A' || str == 'null')
        return null;
      final clean = str.split('.').first.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty && clean != '0' && clean != '0000000') {
        return clean.length >= 7 ? clean : clean.padLeft(7, '0');
      }
      return null;
    }

    final primary = tryParse(val);
    if (primary != null) return primary;

    final second = tryParse(fallback);
    if (second != null) return second;

    return '0000000';
  }

  List<SensorReadingItem> _buildDynamicSensors({
    LiveCurrentPosition? pos,
    Map<String, dynamic>? rawMap,
    Vehicle? vehicle,
    bool isStale = false,
  }) {
    final ignition =
        pos?.ignition ??
        (rawMap?['ignition'] is int
            ? rawMap!['ignition'] as int
            : int.tryParse(rawMap?['ignition']?.toString() ?? '')) ??
        (vehicle?.isIgnitionOn == true ? 1 : 0);

    final power =
        pos?.power ??
        (rawMap?['power'] is int
            ? rawMap!['power'] as int
            : int.tryParse(rawMap?['power']?.toString() ?? '')) ??
        1;

    final batteryRaw =
        rawMap?['battery'] ?? rawMap?['charge'] ?? rawMap?['battery_level'];
    final batteryVal =
        (batteryRaw != null &&
            batteryRaw.toString().trim().isNotEmpty &&
            batteryRaw != 'null')
        ? (batteryRaw.toString().contains('%')
              ? batteryRaw.toString()
              : '$batteryRaw%')
        : (power == 1 ? '100%' : '-');

    final carBatteryRaw =
        rawMap?['car_battery'] ??
        rawMap?['voltage'] ??
        rawMap?['external_power'];
    final carBatteryVal =
        (carBatteryRaw != null &&
            carBatteryRaw.toString().trim().isNotEmpty &&
            carBatteryRaw != 'null')
        ? (carBatteryRaw.toString().contains('V')
              ? carBatteryRaw.toString()
              : '$carBatteryRaw V')
        : '-';

    final gsm =
        pos?.gsmSignalStrength ??
        rawMap?['gsm_signal_strength']?.toString() ??
        rawMap?['satellites']?.toString() ??
        rawMap?['sat']?.toString();
    final satelliteVal = (gsm != null && gsm.isNotEmpty && gsm != 'null')
        ? (gsm.toLowerCase().contains('sat') ? gsm : '$gsm Sats')
        : '-';

    final fuelRaw =
        rawMap?['fuel'] ?? rawMap?['fuel_level'] ?? rawMap?['fuel_percent'];
    final fuelVal =
        (fuelRaw != null &&
            fuelRaw.toString().trim().isNotEmpty &&
            fuelRaw != 'null')
        ? (fuelRaw.toString().contains('%') ? fuelRaw.toString() : '$fuelRaw%')
        : '-';

    final alt =
        pos?.altitude ??
        rawMap?['altitude']?.toString() ??
        rawMap?['accuracy']?.toString();
    final accuracyVal = (alt != null && alt.isNotEmpty && alt != 'null')
        ? (alt.contains('m') ? alt : '${alt}m')
        : '-';

    final tempRaw = rawMap?['temp'] ?? rawMap?['temperature'];
    final tempVal =
        (tempRaw != null &&
            tempRaw.toString().trim().isNotEmpty &&
            tempRaw != 'null')
        ? (tempRaw.toString().contains('°') ? tempRaw.toString() : '$tempRaw°C')
        : '-';

    final speedVal = isStale
        ? 0.0
        : (pos?.speed ??
              double.tryParse(
                rawMap?['speed']?.toString() ?? vehicle?.speed ?? '0',
              ) ??
              0.0);
    final movement1 = speedVal > 0
        ? 'Moving'
        : (ignition == 1 ? 'Idle' : 'Stopped');

    final mode = pos?.mode ?? rawMap?['mode']?.toString();
    final movement2 = (mode != null && mode.isNotEmpty && mode != 'null')
        ? mode
        : (speedVal > 0
              ? 'GPS Fix'
              : (ignition == 1 ? 'Stationary' : 'Parked'));

    return [
      SensorReadingItem(
        label: 'Battery',
        value: batteryVal,
        iconType: 'battery',
      ),
      SensorReadingItem(
        label: 'Car Battery',
        value: carBatteryVal,
        iconType: 'car_battery',
      ),
      SensorReadingItem(
        label: 'Satellite',
        value: satelliteVal,
        iconType: 'satellite',
      ),
      SensorReadingItem(label: 'Fuel', value: fuelVal, iconType: 'fuel'),
      SensorReadingItem(
        label: 'Accuracy',
        value: accuracyVal,
        iconType: 'accuracy',
      ),
      SensorReadingItem(label: 'Temperature', value: tempVal, iconType: 'temp'),
      SensorReadingItem(
        label: 'Movement',
        value: movement1,
        iconType: 'movement',
      ),
      SensorReadingItem(
        label: 'Movement',
        value: movement2,
        iconType: 'movement2',
      ),
    ];
  }

  /// Update vehicle details from a selected [Vehicle] model
  void updateFromVehicle(Vehicle v) {
    activeImei = v.deviceId;
    final speed = double.tryParse(v.speed) ?? 0.0;
    final lat = v.latitude;
    final lng = v.longitude;
    final coordStr = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
        : 'Coordinates N/A';

    final initialSensors = _buildDynamicSensors(
      vehicle: v,
      rawMap: {'speed': v.speed, 'ignition': v.isIgnitionOn ? 1 : 0},
    );

    final initialOdo = _extractOdometerDigits(
      v.odometer,
      fallback: v.distance.isNotEmpty && v.distance != '0'
          ? v.distance
          : (v.todayKm.isNotEmpty && v.todayKm != '0' ? v.todayKm : null),
    );

    vehicleDetail.value = VehicleDetailData(
      vehicleNumber: v.plateNumber,
      odometerDigits: initialOdo,
      timestamp: v.lastUpdated.isNotEmpty ? v.lastUpdated : 'N/A',
      distanceKm: v.todayKm,
      speedKmph: speed.toInt(),
      coordinates: coordStr,
      latitude: lat,
      longitude: lng,
      address: v.locationLabel,
      deviceTime: v.lastUpdated,
      serverTime: v.lastUpdated,
      runningDuration: v.statusDuration.isNotEmpty
          ? v.statusDuration
          : '00:00:00',
      idleDuration: v.statusDuration.isNotEmpty ? v.statusDuration : '00:00:00',
      stoppedDuration: v.statusDuration.isNotEmpty
          ? v.statusDuration
          : '00:00:00',
      inactiveDuration: v.statusDuration.isNotEmpty
          ? v.statusDuration
          : '00:00:00',
      avgSpeedKmph: v.speed,
      maxSpeedKmph: v.speed,
      todayOdoKm: v.todayKm,
      sensors: initialSensors,
    );

    // FIX: when the same vehicle is already being live-tracked, a Home list
    // refresh must NOT snap the marker back to Home's (often older) position
    // or tear down the WebSocket. That was causing the jump-back / freeze.
    final bool isSameLiveSession =
        selectedTopTab.value == -1 &&
        _liveTrackingImei != null &&
        _liveTrackingImei == v.deviceId &&
        _liveWaypoints.isNotEmpty;

    if (!isSameLiveSession &&
        lat != null &&
        lng != null &&
        (lat != 0.0 || lng != 0.0)) {
      final loc = LatLng(lat, lng);
      _snapLiveMarkerTo(loc, speed);
      isLiveMoving.value = speed > 0 || v.status.toLowerCase() == 'running';
    }

    if (v.deviceId.isNotEmpty) {
      if (selectedTopTab.value == -1) {
        // Same API call as before; for an active session it only refreshes
        // the snapshot instead of resetting the whole live engine.
        startLiveTracking(v.deviceId, reconnectOnly: isSameLiveSession);
      } else {
        loadVehicleSnapshot(v.deviceId);
      }
      loadLiveTrack(v.deviceId);
      loadStatistics(imei: v.deviceId);
      loadVehicleHistory(imei: v.deviceId);
    }
  }

  /// Load live tracking snapshot for vehicle by IMEI (GET /live_track_snapshot)
  Future<void> loadVehicleSnapshot(String imei) async {
    if (imei.isEmpty) return;
    if (selectedTopTab.value == -1) {
      await startLiveTracking(imei);
      return;
    }
    try {
      isLoading.value = true;
      activeImei = imei;

      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final currentPos = data['current_position'] ?? data['vehicle_info'];
        final todayStats = data['today_statistics'] is Map
            ? Map<String, dynamic>.from(data['today_statistics'])
            : null;

        if (currentPos != null && currentPos is Map) {
          final lat = double.tryParse(currentPos['latitude']?.toString() ?? '');
          final lng = double.tryParse(
            currentPos['longitude']?.toString() ?? '',
          );
          final speed =
              double.tryParse(currentPos['speed']?.toString() ?? '0') ?? 0.0;
          final rawOdo =
              currentPos['odometer'] ??
              currentPos['total_distance'] ??
              currentPos['total_kilometers_traveled'] ??
              currentPos['kilometer'] ??
              data['vehicle_info']?['total_kilometers_traveled'] ??
              data['vehicle_info']?['odometer'] ??
              todayStats?['total_kilometers_today'] ??
              todayStats?['odometer'] ??
              data['odometer'];

          final dynSensors = _buildDynamicSensors(
            rawMap: Map<String, dynamic>.from(currentPos),
          );

          vehicleDetail.update((val) {
            if (val != null) {
              vehicleDetail.value = VehicleDetailData(
                vehicleNumber:
                    currentPos['vehicle_number']?.toString() ??
                    currentPos['name']?.toString() ??
                    val.vehicleNumber,
                odometerDigits: _extractOdometerDigits(
                  rawOdo,
                  fallback: val.odometerDigits,
                ),
                timestamp:
                    currentPos['device_time']?.toString() ?? val.timestamp,
                distanceKm: currentPos['kilometer'] != null
                    ? '${currentPos['kilometer']} km'
                    : (todayStats?['total_kilometers_today'] != null
                          ? '${todayStats!['total_kilometers_today']} km'
                          : val.distanceKm),
                speedKmph: speed.toInt(),
                coordinates: (lat != null && lng != null)
                    ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                    : val.coordinates,
                latitude: lat ?? val.latitude,
                longitude: lng ?? val.longitude,
                address:
                    currentPos['address']?.toString() ??
                    currentPos['location']?.toString() ??
                    val.address,
                deviceTime:
                    currentPos['device_time']?.toString() ?? val.deviceTime,
                serverTime:
                    currentPos['server_time']?.toString() ?? val.serverTime,
                runningDuration:
                    todayStats?['running_duration']?.toString() ??
                    todayStats?['display_running_duration']?.toString() ??
                    val.runningDuration,
                idleDuration:
                    todayStats?['idle_duration']?.toString() ??
                    todayStats?['display_idle_duration']?.toString() ??
                    val.idleDuration,
                stoppedDuration:
                    todayStats?['stopped_duration']?.toString() ??
                    todayStats?['display_stopped_duration']?.toString() ??
                    val.stoppedDuration,
                inactiveDuration:
                    todayStats?['inactive_duration']?.toString() ??
                    todayStats?['display_inactive_duration']?.toString() ??
                    val.inactiveDuration,
                avgSpeedKmph:
                    todayStats?['avg_speed']?.toString() ??
                    todayStats?['average_speed']?.toString() ??
                    val.avgSpeedKmph,
                maxSpeedKmph:
                    todayStats?['max_speed']?.toString() ??
                    todayStats?['top_speed']?.toString() ??
                    val.maxSpeedKmph,
                todayOdoKm:
                    todayStats?['total_kilometers_today']?.toString() ??
                    val.todayOdoKm,
                sensors: dynSensors,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading vehicle live snapshot: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load live track update by IMEI (GET /live_track)
  Future<void> loadLiveTrack(String imei) async {
    if (imei.isEmpty) return;
    try {
      final response = await DioClient().get(
        ApiEndPoints.liveTrack,
        queryParameters: {'imei': imei},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (data is Map) {
          liveTrackData.value = Map<String, dynamic>.from(data);
          final pos = data['current_position'] ?? data['position'] ?? data;
          if (pos is Map) {
            final rawOdo =
                pos['odometer'] ??
                pos['total_distance'] ??
                pos['total_kilometers_traveled'] ??
                pos['kilometer'] ??
                data['vehicle_info']?['total_kilometers_traveled'] ??
                data['vehicle_info']?['odometer'];
            final digits = _extractOdometerDigits(rawOdo);
            if (digits != '0000000') {
              vehicleDetail.update((val) {
                if (val != null) {
                  vehicleDetail.value = val.copyWith(odometerDigits: digits);
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching live track: $e');
    }
  }

  /// Update vehicle odometer reading (POST /update_odometer)
  Future<bool> updateOdometer(String imei, double odometer) async {
    try {
      isLoading.value = true;
      final response = await DioClient().post(
        ApiEndPoints.updateOdometer,
        body: {'imei': imei, 'odometer': odometer},
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ?? 'Odometer updated',
        );
        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber: val.vehicleNumber,
              odometerDigits: odometer.toInt().toString().padLeft(7, '0'),
              timestamp: val.timestamp,
              distanceKm: val.distanceKm,
              speedKmph: val.speedKmph,
              coordinates: val.coordinates,
              latitude: val.latitude,
              longitude: val.longitude,
              address: val.address,
              deviceTime: val.deviceTime,
              serverTime: val.serverTime,
              runningDuration: val.runningDuration,
              idleDuration: val.idleDuration,
              stoppedDuration: val.stoppedDuration,
              inactiveDuration: val.inactiveDuration,
              avgSpeedKmph: val.avgSpeedKmph,
              maxSpeedKmph: val.maxSpeedKmph,
              todayOdoKm: val.todayOdoKm,
              sensors: val.sensors,
            );
          }
        });
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ??
            'Failed to update odometer';
        AppToast.show(msg, isError: true);
        return false;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load vehicle history coordinates for route playback (GET /track_vehicle)
  Future<void> loadVehicleHistory({
    String? imei,
    String? fromDate,
    String? toDate,
  }) async {
    String targetImei = (imei != null && imei.isNotEmpty) ? imei : activeImei;
    if (targetImei.isEmpty) {
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        if (home.vehicles.isNotEmpty) {
          final dashCtrl = Get.isRegistered<DashboardController>()
              ? Get.find<DashboardController>()
              : null;
          final idx =
              (dashCtrl != null &&
                  dashCtrl.selectedVehicleIndex.value < home.vehicles.length)
              ? dashCtrl.selectedVehicleIndex.value
              : 0;
          targetImei = home.vehicles[idx].deviceId;
          activeImei = targetImei;
        }
      }
    }
    if (targetImei.isEmpty) return;

    final fDate = fromDate ?? startDateStr.value;
    final tDate = toDate ?? endDateStr.value;

    try {
      isLoading.value = true;
      final response = await DioClient().get(
        ApiEndPoints.vehicleHistory,
        queryParameters: {
          'imei': targetImei,
          'from_date': fDate,
          'to_date': tDate,
          'page': '1',
        },
      );

      if (response.data != null) {
        final resData = response.data['data'] ?? response.data;
        if (resData is Map) {
          historyResponseData.value = Map<String, dynamic>.from(resData);
        } else {
          historyResponseData.clear();
        }

        List<dynamic> raw = [];
        List<dynamic> rawTrips = [];
        if (resData is List) {
          raw = resData;
        } else if (resData is Map) {
          if (resData['trips'] is List) {
            rawTrips = resData['trips'];
          } else if (resData['trip_reports'] is List) {
            rawTrips = resData['trip_reports'];
          }

          if (resData['location_history'] is List) {
            raw = resData['location_history'];
          } else if (resData['history'] is List) {
            raw = resData['history'];
          } else if (resData['locations'] is List) {
            raw = resData['locations'];
          } else if (resData['track'] is List) {
            raw = resData['track'];
          } else if (resData['track_vehicle'] is List) {
            raw = resData['track_vehicle'];
          } else if (resData['points'] is List) {
            raw = resData['points'];
          } else if (resData['route'] is List) {
            raw = resData['route'];
          } else if (resData['items'] is List) {
            raw = resData['items'];
          } else if (resData['data'] is List) {
            raw = resData['data'];
          } else if (resData['list'] is List) {
            raw = resData['list'];
          }
        }

        historyPoints.value = raw
            .whereType<Map>()
            .map((j) => Map<String, dynamic>.from(j))
            .toList();

        _populateHistoryTrips(rawTrips);
        initPlaybackRoute();
      }
    } catch (e) {
      debugPrint('Error loading vehicle history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get dynamicHistoryTrips {
    if (historyTrips.isNotEmpty) return historyTrips;
    if (historyPoints.isEmpty) return [];
    return _generateTripsFromPoints();
  }

  void _populateHistoryTrips(List<dynamic> rawTrips) {
    if (rawTrips.isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      for (int i = 0; i < rawTrips.length; i++) {
        final item = rawTrips[i];
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final dist =
              m['distance'] ??
              m['trip_distance'] ??
              m['distance_km'] ??
              '0.00 Km';
          final spd =
              m['max_speed'] ?? m['speed'] ?? m['top_speed'] ?? '0.0 Kmph';
          final start =
              m['startTime'] ??
              m['start_time'] ??
              m['from_time'] ??
              m['created_at'] ??
              '-';
          final end =
              m['endTime'] ??
              m['end_time'] ??
              m['to_time'] ??
              m['updated_at'] ??
              '-';
          final dur =
              m['duration'] ??
              m['trip_duration'] ??
              m['time_duration'] ??
              _calculateDurationString(start.toString(), end.toString());
          list.add({
            'badge': m['badge']?.toString() ?? 'Trip ${i + 1}',
            'distance': dist.toString().toLowerCase().contains('km')
                ? dist.toString()
                : '$dist Km',
            'maxSpeed': spd.toString().toLowerCase().contains('km')
                ? spd.toString()
                : '$spd Kmph',
            'startTime': formatDisplayTime(start.toString()),
            'duration': dur.toString(),
            'endTime': formatDisplayTime(end.toString()),
          });
        }
      }
      historyTrips.value = list;
    } else {
      historyTrips.value = _generateTripsFromPoints();
    }
  }

  List<Map<String, dynamic>> _generateTripsFromPoints() {
    if (historyPoints.isEmpty) return [];

    if (historyPoints.length == 1) {
      final pt = historyPoints.first;
      final timeStr =
          pt['device_time']?.toString() ??
          pt['created_at']?.toString() ??
          pt['timestamp']?.toString() ??
          pt['time']?.toString() ??
          '-';
      final speedVal = double.tryParse(pt['speed']?.toString() ?? '') ?? 0.0;
      return [
        {
          'badge': 'Trip',
          'distance': '0.00 Km',
          'maxSpeed': '${speedVal.toStringAsFixed(1)} Kmph',
          'startTime': formatDisplayTime(timeStr),
          'duration': '00h 00m',
          'endTime': formatDisplayTime(timeStr),
        },
      ];
    }

    // Segment points into trips by detecting stops (> 5 mins stationary or > 15 mins timestamp gap)
    List<Map<String, dynamic>> trips = [];
    List<Map<String, dynamic>> currentTripPoints = [];

    for (int i = 0; i < historyPoints.length; i++) {
      final pt = historyPoints[i];
      if (currentTripPoints.isEmpty) {
        currentTripPoints.add(pt);
        continue;
      }

      final prevPt = currentTripPoints.last;
      final prevTime = _parseTimestamp(
        prevPt['device_time'] ??
            prevPt['created_at'] ??
            prevPt['timestamp'] ??
            prevPt['time'],
      );
      final currTime = _parseTimestamp(
        pt['device_time'] ?? pt['created_at'] ?? pt['timestamp'] ?? pt['time'],
      );

      final speed = double.tryParse(pt['speed']?.toString() ?? '') ?? 0.0;
      final prevSpeed =
          double.tryParse(prevPt['speed']?.toString() ?? '') ?? 0.0;

      bool isNewTrip = false;
      if (prevTime != null && currTime != null) {
        final gapSec = currTime.difference(prevTime).inSeconds.abs();
        if ((gapSec >= 300 && speed == 0 && prevSpeed == 0) || gapSec >= 900) {
          isNewTrip = true;
        }
      }

      if (isNewTrip && currentTripPoints.length >= 2) {
        trips.add(
          _buildTripSummaryMap(currentTripPoints, tripIndex: trips.length + 1),
        );
        currentTripPoints = [pt];
      } else {
        currentTripPoints.add(pt);
      }
    }

    if (currentTripPoints.isNotEmpty) {
      trips.add(
        _buildTripSummaryMap(currentTripPoints, tripIndex: trips.length + 1),
      );
    }

    if (trips.length == 1) {
      trips[0]['badge'] = 'Trip';
    }

    return trips;
  }

  Map<String, dynamic> _buildTripSummaryMap(
    List<Map<String, dynamic>> pts, {
    required int tripIndex,
  }) {
    if (pts.isEmpty) return {};

    final first = pts.first;
    final last = pts.last;

    final rawStart =
        first['device_time'] ??
        first['created_at'] ??
        first['timestamp'] ??
        first['time'] ??
        '-';
    final rawEnd =
        last['device_time'] ??
        last['created_at'] ??
        last['timestamp'] ??
        last['time'] ??
        '-';

    final startDt = _parseTimestamp(rawStart);
    final endDt = _parseTimestamp(rawEnd);

    String durationStr = '00h 00m';
    if (startDt != null && endDt != null) {
      final diff = endDt.difference(startDt);
      durationStr = _formatDuration(diff);
    }

    double distKm = 0.0;
    double maxSpeedKmph = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final s = double.tryParse(pts[i]['speed']?.toString() ?? '') ?? 0.0;
      if (s > maxSpeedKmph) maxSpeedKmph = s;

      if (i < pts.length - 1) {
        final lat1 = double.tryParse(
          pts[i]['latitude']?.toString() ?? pts[i]['lat']?.toString() ?? '',
        );
        final lon1 = double.tryParse(
          pts[i]['longitude']?.toString() ?? pts[i]['lng']?.toString() ?? '',
        );
        final lat2 = double.tryParse(
          pts[i + 1]['latitude']?.toString() ??
              pts[i + 1]['lat']?.toString() ??
              '',
        );
        final lon2 = double.tryParse(
          pts[i + 1]['longitude']?.toString() ??
              pts[i + 1]['lng']?.toString() ??
              '',
        );
        if (lat1 != null &&
            lon1 != null &&
            lat2 != null &&
            lon2 != null &&
            (lat1 != 0 || lon1 != 0) &&
            (lat2 != 0 || lon2 != 0)) {
          distKm += _distanceKm(LatLng(lat1, lon1), LatLng(lat2, lon2));
        }
      }
    }

    final firstDist = double.tryParse(first['distance']?.toString() ?? '');
    final lastDist = double.tryParse(last['distance']?.toString() ?? '');
    if (firstDist != null && lastDist != null && lastDist > firstDist) {
      distKm = lastDist - firstDist;
    }

    return {
      'badge': 'Trip $tripIndex',
      'distance': '${distKm.toStringAsFixed(2)} Km',
      'maxSpeed': '${maxSpeedKmph.toStringAsFixed(1)} Kmph',
      'startTime': formatDisplayTime(rawStart.toString()),
      'duration': durationStr,
      'endTime': formatDisplayTime(rawEnd.toString()),
    };
  }

  String _calculateDurationString(String startStr, String endStr) {
    final sDt = _parseTimestamp(startStr);
    final eDt = _parseTimestamp(endStr);
    if (sDt != null && eDt != null) {
      return _formatDuration(eDt.difference(sDt));
    }
    return '00h 00m';
  }

  /// Load vehicle statistics from API (GET /statistics)
  Future<void> loadStatistics({
    String? imei,
    String? fromDate,
    String? toDate,
    String? period,
  }) async {
    final targetImei = (imei != null && imei.isNotEmpty) ? imei : activeImei;
    if (targetImei.isEmpty) return;

    final fDate = (fromDate != null && fromDate.isNotEmpty)
        ? fromDate
        : startDateStr.value;
    final tDate = (toDate != null && toDate.isNotEmpty)
        ? toDate
        : endDateStr.value;

    final queryParams = <String, dynamic>{
      'imei': targetImei,
      'from_date': fDate,
      'to_date': tDate,
    };

    if (period != null &&
        period.isNotEmpty &&
        period.toLowerCase() != 'custom') {
      queryParams['period'] = period;
    }

    try {
      isStatisticsLoading.value = true;
      var response = await DioClient().get(
        ApiEndPoints.statistics,
        queryParameters: queryParams,
      );

      // If 422 or status false occurs due to period parameter, retry without period parameter
      if ((response.statusCode == 422 ||
              (response.data is Map && response.data['status'] == false)) &&
          queryParams.containsKey('period')) {
        queryParams.remove('period');
        response = await DioClient().get(
          ApiEndPoints.statistics,
          queryParameters: queryParams,
        );
      }

      if (response.data != null && response.data['data'] != null) {
        _parseAndSetStatisticsData(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error loading vehicle statistics: $e');
    } finally {
      isStatisticsLoading.value = false;
    }
  }

  void _parseAndSetStatisticsData(dynamic data) {
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);

    final routeLen =
        map['route_length']?.toString() ??
        map['route_distance']?.toString() ??
        map['distance']?.toString() ??
        map['total_distance']?.toString() ??
        '0 km';

    final moveDur =
        map['move_duration']?.toString() ??
        map['moving_duration']?.toString() ??
        map['moving_time']?.toString() ??
        '00:00:00';

    final idleDur =
        map['idle_duration']?.toString() ??
        map['idling_duration']?.toString() ??
        map['idle_time']?.toString() ??
        '00:00:00';

    final stopDur =
        map['stop_duration']?.toString() ??
        map['stopped_duration']?.toString() ??
        map['stop_time']?.toString() ??
        '00:00:00';

    final stopCnt =
        map['stop_count']?.toString() ??
        map['stops']?.toString() ??
        map['stopped_count']?.toString() ??
        '0';

    final avgSpd =
        map['average_speed']?.toString() ??
        map['avg_speed']?.toString() ??
        '0 kmph';

    final topSpd =
        map['top_speed']?.toString() ??
        map['max_speed']?.toString() ??
        '0 kmph';

    final overSpdCnt =
        map['over_speed_count']?.toString() ??
        map['overspeed_count']?.toString() ??
        map['overspeed_events']?.toString() ??
        '0';

    final engHrs =
        map['engine_hours']?.toString() ??
        map['engine_duration']?.toString() ??
        map['engine_on_time']?.toString() ??
        '00:00:00';

    final odo =
        map['odometer']?.toString() ??
        map['odo']?.toString() ??
        map['today_odo']?.toString() ??
        map['total_distance']?.toString() ??
        '0 km';

    statisticsData.value = {
      'Route Length': routeLen.contains('km') ? routeLen : '$routeLen km',
      'Move Duration': moveDur,
      'Idle Duration': idleDur,
      'Stop Duration': stopDur,
      'Stop Count': stopCnt,
      'Average Speed': avgSpd.contains('kmph') ? avgSpd : '$avgSpd kmph',
      'Top Speed': topSpd.contains('kmph') ? topSpd : '$topSpd kmph',
      'Over Speed Count': overSpdCnt,
      'Engine Hours': engHrs,
      'Odometer': odo.contains('km') ? odo : '$odo km',
    };

    final odoDigits = _extractOdometerDigits(odo);
    if (odoDigits != '0000000' ||
        vehicleDetail.value.odometerDigits == '0000000') {
      vehicleDetail.update((val) {
        if (val != null) {
          vehicleDetail.value = val.copyWith(
            odometerDigits: odoDigits,
            todayOdoKm:
                (val.todayOdoKm == '0' ||
                    val.todayOdoKm.isEmpty ||
                    val.todayOdoKm == '0 km')
                ? (odo.contains('km') ? odo : '$odo km')
                : val.todayOdoKm,
          );
        }
      });
    }
  }

  @override
  void onClose() {
    _liveDisposed = true;
    stopMovingMarker();
    stopLiveTracking();
    super.onClose();
  }

  void selectTab(int index) {
    selectedTopTab.value = index;
    if (index != 0) {
      stopMovingMarker();
    }
    if (index != -1) {
      stopLiveTracking();
    }

    // Trigger API calls when tab changes
    if (index == 0) {
      // History Tab
      loadVehicleHistory();
    } else if (index == 1) {
      // Alerts Tab
      if (Get.isRegistered<AlertsController>()) {
        Get.find<AlertsController>().loadAlerts();
      } else {
        Get.put(AlertsController()).loadAlerts();
      }
    } else if (index == 2) {
      // Statistics Tab
      if (activeImei.isNotEmpty) {
        loadStatistics(imei: activeImei);
      }
    } else if (index == -1) {
      if (activeImei.isNotEmpty) {
        startLiveTracking(activeImei);
      }
    }
  }

  void toggleMapDialog() {
    isMapDialogVisible.value = !isMapDialogVisible.value;
  }

  void hideMapDialog() {
    isMapDialogVisible.value = false;
  }

  void showMapDialog() {
    isMapDialogVisible.value = true;
  }

  void toggleHistoryMapDialog() {
    isHistoryMapDialogVisible.value = !isHistoryMapDialogVisible.value;
  }

  void hideHistoryMapDialog() {
    isHistoryMapDialogVisible.value = false;
  }

  List<LatLng> getActiveRoutePoints() {
    final dynamicRoutePoints = <LatLng>[];
    if (historyPoints.isNotEmpty) {
      for (final pt in historyPoints) {
        final pLat = double.tryParse(
          pt['latitude']?.toString() ?? pt['lat']?.toString() ?? '',
        );
        final pLng = double.tryParse(
          pt['longitude']?.toString() ?? pt['lng']?.toString() ?? '',
        );
        if (pLat != null && pLng != null && (pLat != 0 || pLng != 0)) {
          dynamicRoutePoints.add(LatLng(pLat, pLng));
        }
      }
    }
    return dynamicRoutePoints;
  }

  void _buildPlaybackSpeedSeries() {
    _playbackSpeedSeries = historyPoints.map((pt) {
      final s = pt['speed'];
      return double.tryParse(s?.toString() ?? '') ?? 0.0;
    }).toList();
  }

  void fitHistoryRoute() {
    final route = getActiveRoutePoints();
    if (route.isEmpty) return;
    try {
      if (route.length == 1) {
        historyMapController.move(route.first, 14.0);
      } else {
        historyMapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(route),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (e) {
      debugPrint('fitHistoryRoute error: $e');
    }
  }

  void zoomInHistoryMap() {
    try {
      historyMapController.move(
        historyMapController.camera.center,
        historyMapController.camera.zoom + 1,
      );
    } catch (_) {}
  }

  void zoomOutHistoryMap() {
    try {
      historyMapController.move(
        historyMapController.camera.center,
        historyMapController.camera.zoom - 1,
      );
    } catch (_) {}
  }

  void initPlaybackRoute() {
    _buildPlaybackSpeedSeries();

    // FIX: a Home list refresh re-fetches the same history. If playback is
    // running or paused mid-route and the new route is the same trip (same
    // start, old route is a prefix), keep the car where it is instead of
    // stopping it and sending it back to the start.
    final newPoints = getActiveRoutePoints();
    if (_canContinuePlayback(newPoints)) {
      _playbackRoutePoints = List<LatLng>.from(newPoints);
      return;
    }

    placeMovingMarkerAtStart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedTopTab.value == 0) {
        fitHistoryRoute();
      }
    });
  }

  bool _canContinuePlayback(List<LatLng> newPoints) {
    final old = _playbackRoutePoints;
    final inProgress =
        isPlaying.value ||
        (playbackProgress.value > 0.0 && playbackProgress.value < 1.0);
    if (!inProgress || old.length < 2 || newPoints.length < old.length) {
      return false;
    }
    bool same(LatLng a, LatLng b) =>
        (a.latitude - b.latitude).abs() < 1e-7 &&
        (a.longitude - b.longitude).abs() < 1e-7;
    return same(old.first, newPoints.first) &&
        same(old.last, newPoints[old.length - 1]);
  }

  void placeMovingMarkerAtStart() {
    stopMovingMarker();
    final points = getActiveRoutePoints();
    _playbackRoutePoints = List<LatLng>.from(points);
    _movingSegmentIndex = 0;
    _movingSegmentFraction = 0.0;
    playbackProgress.value = 0.0;
    currentPlaybackSpeedKmph.value = 0.0;
    _lastCameraUpdateMs = 0;
    if (points.isEmpty) {
      movingMarkerPosition.value = null;
      movingMarkerBearing.value = null;
      traveledRoutePoints.clear();
    } else {
      movingMarkerPosition.value = points.first;
      movingMarkerBearing.value = points.length >= 2
          ? _getBearing(points[0], points[1])
          : 0.0;
      traveledRoutePoints.assignAll([points.first]);
    }
  }

  void togglePlay() {
    if (isPlaying.value) {
      stopMovingMarker();
    } else {
      startMovingMarker();
    }
  }

  void startMovingMarker() {
    final points = getActiveRoutePoints();
    if (points.length < 2) {
      AppToast.showErrorMessage('No history route available for playback');
      return;
    }

    if (playbackProgress.value >= 1.0) {
      placeMovingMarkerAtStart();
    }

    _playbackRoutePoints = List<LatLng>.from(points);
    stopMovingMarker();

    if (movingMarkerPosition.value == null) {
      movingMarkerPosition.value = _playbackRoutePoints.first;
      movingMarkerBearing.value = _playbackRoutePoints.length > 1
          ? _getBearing(_playbackRoutePoints[0], _playbackRoutePoints[1])
          : 0.0;
      traveledRoutePoints.assignAll([_playbackRoutePoints.first]);
    }

    // Ensure vehicle position is visible when starting playback
    if (movingMarkerPosition.value != null) {
      try {
        final currentZoom = historyMapController.camera.zoom;
        historyMapController.move(
          movingMarkerPosition.value!,
          currentZoom < 12 ? 14.0 : currentZoom,
        );
      } catch (_) {}
    }

    isPlaying.value = true;
    _lastCameraUpdateMs = 0;
    _lastPlaybackTickAt = null;
    _movingMarkerTimer = Timer.periodic(_playbackFramePeriod, (_) {
      advanceFrame();
    });
  }

  void stopMovingMarker() {
    _movingMarkerTimer?.cancel();
    _movingMarkerTimer = null;
    isPlaying.value = false;
    currentPlaybackSpeedKmph.value = 0.0;
  }

  void replay() {
    seekToProgress(0.0);
    startMovingMarker();
  }

  void cyclePlaybackSpeed() {
    final current = playbackSpeedMultiplier.value;
    if (current < 1.25) {
      playbackSpeedMultiplier.value = 1.5;
      playbackSpeed.value = '1.5x';
    } else if (current < 1.75) {
      playbackSpeedMultiplier.value = 2.0;
      playbackSpeed.value = '2x';
    } else {
      playbackSpeedMultiplier.value = 1.0;
      playbackSpeed.value = '1x';
    }
  }

  void seekToProgress(double p) {
    final route = _playbackRoutePoints.isNotEmpty
        ? _playbackRoutePoints
        : getActiveRoutePoints();
    if (route.length < 2) return;

    final wasPlaying = isPlaying.value;
    stopMovingMarker();

    final clamped = p.clamp(0.0, 1.0);
    playbackProgress.value = clamped;

    if (clamped <= 0.0) {
      _movingSegmentIndex = 0;
      _movingSegmentFraction = 0.0;
      movingMarkerPosition.value = route.first;
      movingMarkerBearing.value = _getBearing(route[0], route[1]);
      traveledRoutePoints.assignAll([route.first]);
      try {
        historyMapController.move(
          route.first,
          historyMapController.camera.zoom,
        );
      } catch (_) {}
      if (wasPlaying) startMovingMarker();
      return;
    }
    if (clamped >= 1.0) {
      _movingSegmentIndex = route.length - 1;
      _movingSegmentFraction = 1.0;
      movingMarkerPosition.value = route.last;
      movingMarkerBearing.value = route.length >= 2
          ? _getBearing(route[route.length - 2], route.last)
          : 0.0;
      traveledRoutePoints.assignAll(List<LatLng>.from(route));
      try {
        historyMapController.move(route.last, historyMapController.camera.zoom);
      } catch (_) {}
      return;
    }
    final totalKm = _getTotalDistanceKm(route);
    final targetKm = clamped * totalKm;
    double cum = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      final segKm = _distanceKm(route[i], route[i + 1]);
      if (cum + segKm >= targetKm) {
        final t = segKm > 0 ? (targetKm - cum) / segKm : 0.0;
        _movingSegmentIndex = i;
        _movingSegmentFraction = t.clamp(0.0, 1.0);
        final a = route[i];
        final b = route[i + 1];
        final interpolated = LatLng(
          a.latitude + (b.latitude - a.latitude) * _movingSegmentFraction,
          a.longitude + (b.longitude - a.longitude) * _movingSegmentFraction,
        );
        movingMarkerPosition.value = interpolated;
        movingMarkerBearing.value = _getBearing(a, b);

        final passed = route.sublist(0, _movingSegmentIndex + 1);
        traveledRoutePoints.assignAll([...passed, interpolated]);

        try {
          historyMapController.move(
            interpolated,
            historyMapController.camera.zoom,
          );
        } catch (_) {}

        if (wasPlaying) startMovingMarker();
        return;
      }
      cum += segKm;
    }
    _movingSegmentIndex = route.length - 1;
    _movingSegmentFraction = 1.0;
    movingMarkerPosition.value = route.last;
    traveledRoutePoints.assignAll(List<LatLng>.from(route));
  }

  void advanceFrame() {
    final route = _playbackRoutePoints;
    if (route.length < 2) {
      stopMovingMarker();
      return;
    }

    // Real elapsed time per frame (web timers can fire late).
    final now = DateTime.now();
    final dt = _lastPlaybackTickAt == null
        ? _playbackTickSeconds
        : (now.difference(_lastPlaybackTickAt!).inMicroseconds / 1000000.0)
              .clamp(0.001, 0.1);
    _lastPlaybackTickAt = now;

    final baseMps = _playbackBaseMps(route);
    final effectiveMps = baseMps * playbackSpeedMultiplier.value;
    double distanceBudgetMeters = effectiveMps * dt;

    while (distanceBudgetMeters > 0) {
      if (_movingSegmentIndex >= route.length - 1) {
        movingMarkerPosition.value = route.last;
        final prevBearing = movingMarkerBearing.value ?? 0.0;
        final endBearing = route.length >= 2
            ? _getBearing(route[route.length - 2], route.last)
            : prevBearing;
        movingMarkerBearing.value = _lerpBearing(
          prevBearing,
          endBearing,
          _bearingSmoothing,
        );
        playbackProgress.value = 1.0;
        traveledRoutePoints.assignAll(List<LatLng>.from(route));
        currentPlaybackSpeedKmph.value = 0.0;
        stopMovingMarker();
        return;
      }

      final a = route[_movingSegmentIndex];
      final b = route[_movingSegmentIndex + 1];
      final segmentMeters = _distanceMeters(a, b);
      if (segmentMeters <= 1e-6) {
        _movingSegmentIndex++;
        _movingSegmentFraction = 0.0;
        continue;
      }

      final currentT = _movingSegmentFraction.clamp(0.0, 1.0);
      final remainingMeters = segmentMeters * (1.0 - currentT);
      if (distanceBudgetMeters >= remainingMeters) {
        distanceBudgetMeters -= remainingMeters;
        _movingSegmentIndex++;
        _movingSegmentFraction = 0.0;
      } else {
        final additionalT = distanceBudgetMeters / segmentMeters;
        _movingSegmentFraction = (currentT + additionalT).clamp(0.0, 1.0);
        distanceBudgetMeters = 0.0;
      }
    }

    if (_movingSegmentIndex >= route.length - 1) {
      movingMarkerPosition.value = route.last;
      playbackProgress.value = 1.0;
      traveledRoutePoints.assignAll(List<LatLng>.from(route));
      currentPlaybackSpeedKmph.value = 0.0;
      stopMovingMarker();
      return;
    }

    final a = route[_movingSegmentIndex];
    final b = route[_movingSegmentIndex + 1];
    final t = _movingSegmentFraction.clamp(0.0, 1.0);
    final interpolated = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
    movingMarkerPosition.value = interpolated;
    final targetBearing = _getBearing(a, b);
    final prevBearing = movingMarkerBearing.value ?? targetBearing;
    movingMarkerBearing.value = _lerpBearing(
      prevBearing,
      targetBearing,
      _bearingSmoothing,
    );
    playbackProgress.value = _getProgressFromMarkerPosition(route);

    // Update dynamic playback speed
    if (_playbackSpeedSeries.isNotEmpty &&
        _movingSegmentIndex < _playbackSpeedSeries.length) {
      // Show the speed the vehicle actually recorded at this point.
      final s = _playbackSpeedSeries[_movingSegmentIndex];
      currentPlaybackSpeedKmph.value = s > 0 ? s : 0.0;
    } else {
      currentPlaybackSpeedKmph.value = 0.0;
    }

    // Actively draw the route behind the moving vehicle!
    if (_movingSegmentIndex < route.length) {
      final passed = route.sublist(0, _movingSegmentIndex + 1);
      traveledRoutePoints.assignAll([...passed, interpolated]);
    }

    // Keep camera following vehicle smoothly every ~300ms
    _lastCameraUpdateMs += 16;
    if (_lastCameraUpdateMs >= 300) {
      _lastCameraUpdateMs = 0;
      try {
        historyMapController.move(
          interpolated,
          historyMapController.camera.zoom,
        );
      } catch (_) {}
    }
  }

  /// 1x playback speed in m/s, derived from the map's current zoom so the
  /// marker moves ~[_playbackScreenPxPerSec] px/s on screen.
  double _playbackBaseMps(List<LatLng> route) {
    double zoom = 14.0;
    try {
      zoom = historyMapController.camera.zoom;
    } catch (_) {}
    final lat = (movingMarkerPosition.value ?? route.first).latitude;
    final metersPerPixel =
        156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);
    return (metersPerPixel * _playbackScreenPxPerSec)
        .clamp(_playbackMinMps, _playbackMaxMps)
        .toDouble();
  }

  double _getProgressFromMarkerPosition([List<LatLng>? routePoints]) {
    final points = routePoints ?? _playbackRoutePoints;
    if (points.length < 2) return 0.0;
    final total = _getTotalDistanceKm(points);
    if (total <= 0) return 0.0;
    final covered = _getDistanceCoveredKm(
      points,
      _movingSegmentIndex,
      _movingSegmentFraction,
    );
    return (covered / total).clamp(0.0, 1.0);
  }

  double _getTotalDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceKm(points[i], points[i + 1]);
    }
    return total;
  }

  double _getDistanceCoveredKm(
    List<LatLng> points,
    int segmentIndex,
    double segmentFraction,
  ) {
    if (points.length < 2) return 0.0;
    double covered = 0.0;
    for (int i = 0; i < segmentIndex && i < points.length - 1; i++) {
      covered += _distanceKm(points[i], points[i + 1]);
    }
    if (segmentIndex < points.length - 1) {
      covered +=
          segmentFraction *
          _distanceKm(points[segmentIndex], points[segmentIndex + 1]);
    }
    return covered;
  }

  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lon2 = end.longitude * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  double _lerpBearing(double from, double to, double t) {
    final diff = ((to - from + 540) % 360) - 180;
    return (from + diff * t) % 360;
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final la1 = a.latitude * math.pi / 180;
    final la2 = b.latitude * math.pi / 180;
    final x =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return R * c;
  }

  double _distanceMeters(LatLng a, LatLng b) => _distanceKm(a, b) * 1000;

  // ---------------------------------------------------------------------
  // Live Tracking Real-Time Engine (WebSocket + Road Buffer + Motion Gliding)
  // ---------------------------------------------------------------------

  Future<void> startLiveTracking(
    String imei, {
    bool reconnectOnly = false,
  }) async {
    if (imei.isEmpty || _liveDisposed) return;
    activeImei = imei;

    // FIX: every full start opens a new session. Any older in-flight start /
    // poll / road request that finishes later is ignored instead of
    // overwriting the current motion state.
    final int session = reconnectOnly ? _liveSessionId : ++_liveSessionId;

    if (!reconnectOnly) {
      _liveTrackingImei = imei;
      _stopLiveAnimationLoop();
      _stopLivePollingTimer();
      await _liveTrackWs.disconnect();
      _liveWaypoints.clear();
      _liveWaypointIndex = 0;
      _liveWaypointFraction = 0.0;
      _currentLiveSpeedMs = 0.0;
      _lastAcceptedGps = null;
      _lastGpsTime = null;
      _lastReportedSpeedKmh = 0.0;
      _roadFetchInFlight = false;
      _lastLiveFixTime = null;
    }

    try {
      if (!reconnectOnly) isLoading.value = true;

      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei.trim()},
      );

      if (_liveDisposed || session != _liveSessionId) return;

      final rawBody = response.data;
      if (rawBody is! Map) return;
      final body = Map<String, dynamic>.from(rawBody);
      final snapshot = LiveTrackSnapshotModel.fromJson(body);
      final data = snapshot.data;
      if (data == null) return;

      _wsConfig = data.websocketConfig;
      _wsInfo = data.websocket;

      final pos = data.currentPosition;
      final todayStats = data.todayStatistics;
      if (pos != null) {
        final lat = double.tryParse(pos.latitude ?? '');
        final lng = double.tryParse(pos.longitude ?? '');
        final bool isStale = _isStaleFix(pos.deviceTime);
        final speed = isStale ? 0.0 : (pos.speed ?? 0.0);
        final rawOdo =
            pos.odometer ??
            data.vehicleInfo?.totalKilometersTraveled ??
            body['data']?['current_position']?['odometer'] ??
            body['data']?['current_position']?['total_distance'] ??
            body['data']?['current_position']?['kilometer'] ??
            body['data']?['vehicle_info']?['total_kilometers_traveled'] ??
            body['data']?['vehicle_info']?['odometer'] ??
            body['data']?['today_statistics']?['odometer'] ??
            body['data']?['today_statistics']?['total_kilometers_today'] ??
            todayStats?.totalKilometersToday ??
            pos.kilometer;

        final odoDigits = _extractOdometerDigits(
          rawOdo,
          fallback: vehicleDetail.value.odometerDigits,
        );

        final dynamicSensors = _buildDynamicSensors(
          pos: pos,
          rawMap: body['data'] is Map
              ? Map<String, dynamic>.from(body['data'])
              : null,
          isStale: isStale,
        );

        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber:
                  data.vehicleInfo?.vehicleNumber ?? val.vehicleNumber,
              odometerDigits: odoDigits,
              timestamp: pos.deviceTime ?? val.timestamp,
              distanceKm: pos.kilometer != null
                  ? '${pos.kilometer} km'
                  : (todayStats?.totalKilometersToday != null
                        ? '${todayStats!.totalKilometersToday!.toStringAsFixed(1)} km'
                        : val.distanceKm),
              speedKmph: speed.toInt(),
              coordinates: (lat != null && lng != null)
                  ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                  : val.coordinates,
              latitude: lat ?? val.latitude,
              longitude: lng ?? val.longitude,
              address: val.address,
              deviceTime: pos.deviceTime ?? val.deviceTime,
              serverTime: pos.lastUpdate ?? val.serverTime,
              runningDuration:
                  todayStats?.displayRunningDuration ?? val.runningDuration,
              idleDuration: todayStats?.displayIdleDuration ?? val.idleDuration,
              stoppedDuration:
                  todayStats?.displayStoppedDuration ?? val.stoppedDuration,
              inactiveDuration:
                  todayStats?.displayInactiveDuration ?? val.inactiveDuration,
              avgSpeedKmph: todayStats?.avgSpeed != null
                  ? todayStats!.avgSpeed!.toInt().toString()
                  : val.avgSpeedKmph,
              maxSpeedKmph: todayStats?.maxSpeed != null
                  ? todayStats!.maxSpeed!.toInt().toString()
                  : val.maxSpeedKmph,
              todayOdoKm: todayStats?.totalKilometersToday != null
                  ? todayStats!.totalKilometersToday!.toStringAsFixed(1)
                  : (pos.kilometer ?? val.todayOdoKm),
              sensors: dynamicSensors,
            );
          }
        });

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final location = LatLng(lat, lng);
          _lastLiveUpdateReceivedAt = DateTime.now();

          if (reconnectOnly && _liveWaypoints.isNotEmpty) {
            _onLiveDevicePosition(
              location,
              speed,
              status: isStale ? 'stale' : pos.derivedStatus,
              deviceTime: pos.deviceTime,
            );
          } else {
            _isOlderFix(pos.deviceTime); // records the fix time
            _snapLiveMarkerTo(location, speed);
            isLiveMoving.value =
                !isStale &&
                (speed > 0 || (pos.derivedStatus.toLowerCase() == 'running'));
            if (isLiveLocked.value) {
              recenterLiveMap();
            }
          }
        }
      }

      if (!reconnectOnly) {
        _startLiveAnimationLoop();
        _startLivePollingTimer(imei);
        await _connectLiveWebSocket(imei);
      }
    } catch (e) {
      debugPrint('[LiveTrack] Error starting live tracking: $e');
    } finally {
      if (!reconnectOnly) isLoading.value = false;
      // FIX: the animation loop was stopped at the top of a full start; if the
      // snapshot failed or returned early, it was never restarted and the
      // marker froze. Restart it (no API involved).
      if (!reconnectOnly &&
          !_liveDisposed &&
          session == _liveSessionId &&
          _liveAnimationTimer == null) {
        _startLiveAnimationLoop();
      }
    }
  }

  void _startLivePollingTimer(String imei) {
    _stopLivePollingTimer();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_liveDisposed || activeImei.isEmpty || selectedTopTab.value != -1) {
        return;
      }
      final elapsedSec = DateTime.now()
          .difference(_lastLiveUpdateReceivedAt)
          .inSeconds;
      if (elapsedSec >= 4) {
        await _pollLiveSnapshot(imei);
      }
    });
  }

  void _stopLivePollingTimer() {
    _livePollingTimer?.cancel();
    _livePollingTimer = null;
  }

  Future<void> _pollLiveSnapshot(String imei) async {
    final int session = _liveSessionId;
    try {
      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei.trim()},
      );

      if (_liveDisposed || session != _liveSessionId) return;

      final rawBody = response.data;
      if (rawBody is! Map) return;
      final body = Map<String, dynamic>.from(rawBody);
      final snapshot = LiveTrackSnapshotModel.fromJson(body);
      final data = snapshot.data;
      if (data == null) return;

      final pos = data.currentPosition;
      final todayStats = data.todayStatistics;
      if (pos != null) {
        final lat = double.tryParse(pos.latitude ?? '');
        final lng = double.tryParse(pos.longitude ?? '');
        final bool isStale = _isStaleFix(pos.deviceTime);
        final speed = isStale ? 0.0 : (pos.speed ?? 0.0);
        final odo = pos.odometer?.toString() ?? '0';

        final dynamicSensors = _buildDynamicSensors(
          pos: pos,
          rawMap: body['data'] is Map
              ? Map<String, dynamic>.from(body['data'])
              : null,
          isStale: isStale,
        );

        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber:
                  data.vehicleInfo?.vehicleNumber ?? val.vehicleNumber,
              odometerDigits: odo
                  .replaceAll(RegExp(r'[^0-9]'), '')
                  .padLeft(7, '0'),
              timestamp: pos.deviceTime ?? val.timestamp,
              distanceKm: pos.kilometer != null
                  ? '${pos.kilometer} km'
                  : (todayStats?.totalKilometersToday != null
                        ? '${todayStats!.totalKilometersToday!.toStringAsFixed(1)} km'
                        : val.distanceKm),
              speedKmph: speed.toInt(),
              coordinates: (lat != null && lng != null)
                  ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                  : val.coordinates,
              latitude: lat ?? val.latitude,
              longitude: lng ?? val.longitude,
              address: val.address,
              deviceTime: pos.deviceTime ?? val.deviceTime,
              serverTime: pos.lastUpdate ?? val.serverTime,
              runningDuration:
                  todayStats?.displayRunningDuration ?? val.runningDuration,
              idleDuration: todayStats?.displayIdleDuration ?? val.idleDuration,
              stoppedDuration:
                  todayStats?.displayStoppedDuration ?? val.stoppedDuration,
              inactiveDuration:
                  todayStats?.displayInactiveDuration ?? val.inactiveDuration,
              avgSpeedKmph: todayStats?.avgSpeed != null
                  ? todayStats!.avgSpeed!.toInt().toString()
                  : val.avgSpeedKmph,
              maxSpeedKmph: todayStats?.maxSpeed != null
                  ? todayStats!.maxSpeed!.toInt().toString()
                  : val.maxSpeedKmph,
              todayOdoKm: todayStats?.totalKilometersToday != null
                  ? todayStats!.totalKilometersToday!.toStringAsFixed(1)
                  : (pos.kilometer ?? val.todayOdoKm),
              sensors: dynamicSensors,
            );
          }
        });

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final location = LatLng(lat, lng);
          _lastLiveUpdateReceivedAt = DateTime.now();
          _onLiveDevicePosition(
            location,
            speed,
            status: isStale ? 'stale' : pos.derivedStatus,
            deviceTime: pos.deviceTime,
          );
        }
      }
    } catch (e) {
      debugPrint('[LiveTrack] Fallback polling error: $e');
    }
  }

  Future<void> _connectLiveWebSocket(String imei) async {
    if (_wsConfig == null) {
      debugPrint('[LiveTrack] WebSocket config missing from API snapshot');
      return;
    }

    final int session = _liveSessionId;
    final connected = await _liveTrackWs.connect(
      imei: imei,
      websocketConfig: _wsConfig,
      websocket: _wsInfo,
      onDeviceUpdate: _handleLiveDeviceUpdate,
      onReconnected: () {
        if (_liveDisposed || activeImei.isEmpty) return;
        debugPrint('[LiveTrack] WS reconnected, refreshing snapshot');
        startLiveTracking(activeImei, reconnectOnly: true);
      },
    );

    if (session != _liveSessionId) return;
    isLiveTrackingConnected.value = connected;
  }

  (double, double)? _readLatLngFromMap(Map<String, dynamic> data) {
    Map<String, dynamic> map = data;
    if (data['current_position'] is Map) {
      map = Map<String, dynamic>.from(data['current_position']);
    } else if (data['position'] is Map) {
      map = Map<String, dynamic>.from(data['position']);
    } else if (data['data'] is Map) {
      map = Map<String, dynamic>.from(data['data']);
    } else if (data['vehicle'] is Map) {
      map = Map<String, dynamic>.from(data['vehicle']);
    }

    final lat = double.tryParse(
      (map['latitude'] ?? map['lat'] ?? map['Latitude'])?.toString() ?? '',
    );
    final lng = double.tryParse(
      (map['longitude'] ?? map['lng'] ?? map['lon'] ?? map['Longitude'])
              ?.toString() ??
          '',
    );
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) return null;
    return (lat, lng);
  }

  num? _readSpeedFromMap(Map<String, dynamic> data) {
    Map<String, dynamic> map = data;
    if (data['current_position'] is Map) {
      map = Map<String, dynamic>.from(data['current_position']);
    } else if (data['position'] is Map) {
      map = Map<String, dynamic>.from(data['position']);
    } else if (data['data'] is Map) {
      map = Map<String, dynamic>.from(data['data']);
    }
    final raw = map['speed'] ?? map['Speed'] ?? map['spd'];
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }

  double? _readCourseFromMap(Map<String, dynamic> data) {
    Map<String, dynamic> map = data;
    if (data['current_position'] is Map) {
      map = Map<String, dynamic>.from(data['current_position']);
    } else if (data['position'] is Map) {
      map = Map<String, dynamic>.from(data['position']);
    } else if (data['data'] is Map) {
      map = Map<String, dynamic>.from(data['data']);
    }
    final raw =
        map['course'] ??
        map['angle'] ??
        map['heading'] ??
        map['direction'] ??
        map['bearing'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  void _handleLiveDeviceUpdate(Map<String, dynamic> data) {
    if (_liveDisposed) return;
    try {
      final coords = _readLatLngFromMap(data);
      if (coords == null) {
        debugPrint('[LiveTrack] device update missing valid coords: $data');
        return;
      }

      final lat = coords.$1;
      final lng = coords.$2;
      var speed = _readSpeedFromMap(data)?.toDouble() ?? 0.0;
      final course = _readCourseFromMap(data);

      debugPrint(
        '[LiveTrack] Device Update -> Lat: $lat, Lng: $lng, Speed: $speed km/h, Course: $course',
      );

      _lastLiveUpdateReceivedAt = DateTime.now();

      Map<String, dynamic> map = data;
      if (data['current_position'] is Map) {
        map = Map<String, dynamic>.from(data['current_position']);
      } else if (data['data'] is Map) {
        map = Map<String, dynamic>.from(data['data']);
      }

      final todayMap = (data['today_statistics'] is Map)
          ? Map<String, dynamic>.from(data['today_statistics'])
          : ((data['todayStatistics'] is Map)
                ? Map<String, dynamic>.from(data['todayStatistics'])
                : null);

      final rawOdo =
          map['odometer'] ??
          map['total_distance'] ??
          map['total_kilometers_traveled'] ??
          map['kilometer'] ??
          todayMap?['total_kilometers_today'] ??
          todayMap?['odometer'];
      final odo = _extractOdometerDigits(
        rawOdo,
        fallback: vehicleDetail.value.odometerDigits,
      );
      final rawDevTime =
          map['devicetime']?.toString() ?? map['device_time']?.toString();
      final devTime = rawDevTime ?? vehicleDetail.value.deviceTime;
      final bool isStale = _isStaleFix(rawDevTime);
      if (isStale) speed = 0.0;
      final srvTime =
          map['last_update']?.toString() ??
          map['server_time']?.toString() ??
          vehicleDetail.value.serverTime;
      final km = map['kilometer']?.toString();

      final dynamicSensors = _buildDynamicSensors(
        rawMap: map,
        isStale: isStale,
      );

      vehicleDetail.update((val) {
        if (val != null) {
          vehicleDetail.value = VehicleDetailData(
            vehicleNumber: val.vehicleNumber,
            odometerDigits: odo,
            timestamp: devTime.isNotEmpty ? devTime : val.timestamp,
            distanceKm: km != null
                ? '$km km'
                : (todayMap?['total_kilometers_today'] != null
                      ? '${todayMap!['total_kilometers_today']} km'
                      : val.distanceKm),
            speedKmph: speed.toInt(),
            coordinates:
                '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E',
            latitude: lat,
            longitude: lng,
            address: val.address,
            deviceTime: devTime,
            serverTime: srvTime,
            runningDuration:
                todayMap?['running_duration']?.toString() ??
                todayMap?['display_running_duration']?.toString() ??
                val.runningDuration,
            idleDuration:
                todayMap?['idle_duration']?.toString() ??
                todayMap?['display_idle_duration']?.toString() ??
                val.idleDuration,
            stoppedDuration:
                todayMap?['stopped_duration']?.toString() ??
                todayMap?['display_stopped_duration']?.toString() ??
                val.stoppedDuration,
            inactiveDuration:
                todayMap?['inactive_duration']?.toString() ??
                todayMap?['display_inactive_duration']?.toString() ??
                val.inactiveDuration,
            avgSpeedKmph:
                todayMap?['avg_speed']?.toString() ??
                todayMap?['average_speed']?.toString() ??
                val.avgSpeedKmph,
            maxSpeedKmph:
                todayMap?['max_speed']?.toString() ??
                todayMap?['top_speed']?.toString() ??
                val.maxSpeedKmph,
            todayOdoKm:
                todayMap?['total_kilometers_today']?.toString() ??
                km ??
                val.todayOdoKm,
            sensors: dynamicSensors,
          );
        }
      });

      final statusStr = isStale
          ? 'stale'
          : (speed > 0
                ? 'Running'
                : (map['status']?.toString() ??
                      (map['ignition'] == 1 || map['ignition'] == '1'
                          ? 'Idle'
                          : 'Stopped')));

      _onLiveDevicePosition(
        LatLng(lat, lng),
        speed,
        status: statusStr,
        courseDeg: course,
        deviceTime: rawDevTime,
      );
    } catch (e) {
      debugPrint('[LiveTrack] Error handling live update: $e');
    }
  }

  void _onLiveDevicePosition(
    LatLng location,
    double speedKmH, {
    String? status,
    double? courseDeg,
    String? deviceTime,
  }) {
    // FIX: WebSocket, fallback polling and snapshot refreshes can deliver the
    // same trip out of order. An older fix queued after a newer one makes the
    // marker go backwards and then jump forward. Drop out-of-order fixes.
    if (_isOlderFix(deviceTime)) {
      debugPrint('[LiveTrack] Ignoring out-of-order fix ($deviceTime)');
      return;
    }

    final now = DateTime.now();
    final previousGps = _lastAcceptedGps;
    final previousGpsTime = _lastGpsTime;

    _lastReportedSpeedKmh = speedKmH;
    if (previousGpsTime != null) {
      final interval = now.difference(previousGpsTime).inMilliseconds / 1000.0;
      if (interval >= 0.8 && interval < 60.0) {
        _expectedPingSec = _expectedPingSec * 0.7 + interval * 0.3;
      }
    }

    final movedM = previousGps == null
        ? 0.0
        : _calculateDistance(previousGps, location);
    final isMoving =
        speedKmH > 0 ||
        (status != null && status.toLowerCase() == 'running') ||
        movedM > 1.5;
    isLiveMoving.value = isMoving;

    _lastAcceptedGps = location;
    _lastGpsTime = now;

    if (_liveWaypoints.isEmpty || liveMarkerPosition.value == null) {
      _snapLiveMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }

    final anchor = _liveWaypoints.last;
    final dist = _calculateDistance(anchor, location);

    if (dist > 3000.0) {
      _snapLiveMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }

    if (dist >= 0.5) {
      _liveWaypoints.add(location);
      _requestRoadPath(anchor, location);
    }
  }

  /// Returns true when [deviceTime] is older than the newest fix already
  /// accepted. Otherwise records it as the newest fix. Unparseable or missing
  /// times are never treated as stale.
  bool _isOlderFix(String? deviceTime) {
    final t = _parseFixTime(deviceTime);
    if (t == null) return false;
    final last = _lastLiveFixTime;
    if (last != null && t.isBefore(last)) return true;
    _lastLiveFixTime = t;
    return false;
  }

  /// True when the device time is older than [_liveStaleAfter].
  /// Missing / unparseable times and future times are treated as fresh.
  bool _isStaleFix(String? deviceTime) {
    final t = _parseFixTime(deviceTime);
    if (t == null) return false;
    final age = DateTime.now().difference(t);
    return age > _liveStaleAfter;
  }

  DateTime? _parseFixTime(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty || s == 'null' || s == 'N/A') return null;

    // Epoch seconds / milliseconds
    if (RegExp(r'^\d{9,13}$').hasMatch(s)) {
      final n = int.tryParse(s);
      if (n == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(s.length >= 12 ? n : n * 1000);
    }

    // ISO style: 2026-09-29 13:01:05 / 2026-09-29T13:01:05Z
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // dd-MM-yyyy HH:mm[:ss] [AM/PM]
    final m = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    ).firstMatch(s);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final year = int.parse(m.group(3)!);
    var hour = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    final second = int.tryParse(m.group(6) ?? '0') ?? 0;
    final ampm = m.group(7)?.toUpperCase();
    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return DateTime(year, month, day, hour, minute, second);
  }

  void _snapLiveMarkerTo(
    LatLng location,
    double speedKmH, {
    double? courseDeg,
  }) {
    _liveWaypoints
      ..clear()
      ..add(location);
    _liveWaypointIndex = 0;
    _liveWaypointFraction = 0.0;
    _currentLiveSpeedMs = speedKmH > 0 ? (speedKmH / 3.6) : 0.0;
    _lastReportedSpeedKmh = speedKmH;
    _lastAcceptedGps = location;
    _lastGpsTime = DateTime.now();
    final isMoving = speedKmH > 0;
    isLiveMoving.value = isMoving;
    liveMarkerPosition.value = location;
    if (courseDeg != null && courseDeg >= 0) {
      liveMarkerBearing.value = courseDeg;
    }
    if (isLiveLocked.value) {
      _followLiveCamera(location);
    }
  }

  void _startLiveAnimationLoop() {
    _stopLiveAnimationLoop();
    _lastLiveTickTime = DateTime.now();
    _liveAnimationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_liveDisposed) return;
      final now = DateTime.now();
      final dt = _lastLiveTickTime == null
          ? 0.016
          : (now.difference(_lastLiveTickTime!).inMicroseconds / 1000000.0)
                .clamp(0.001, 0.1);
      _lastLiveTickTime = now;
      _advanceLiveFrame(dt);
    });
  }

  void _stopLiveAnimationLoop() {
    _liveAnimationTimer?.cancel();
    _liveAnimationTimer = null;
    _lastLiveTickTime = null;
  }

  void _advanceLiveFrame(double dt) {
    if (_liveWaypoints.isEmpty) return;

    if (_liveWaypoints.length == 1) {
      liveMarkerPosition.value = _liveWaypoints.first;
      if (isLiveLocked.value) {
        _followLiveCamera(_liveWaypoints.first);
      }
      return;
    }

    if (_liveWaypointIndex >= _liveWaypoints.length - 1) {
      final dest = _liveWaypoints.last;
      liveMarkerPosition.value = dest;
      _currentLiveSpeedMs = 0.0;
      if (isLiveLocked.value) {
        _followLiveCamera(dest);
      }
      return;
    }

    // Compute remaining distance in waypoints
    double remainingMeters = 0.0;
    final a0 = _liveWaypoints[_liveWaypointIndex];
    final b0 = _liveWaypoints[_liveWaypointIndex + 1];
    final segDist0 = _calculateDistance(a0, b0);
    final t0 = _liveWaypointFraction.clamp(0.0, 1.0);
    remainingMeters += segDist0 * (1.0 - t0);
    for (int i = _liveWaypointIndex + 1; i < _liveWaypoints.length - 1; i++) {
      remainingMeters += _calculateDistance(
        _liveWaypoints[i],
        _liveWaypoints[i + 1],
      );
    }

    // Determine target speed
    final reportedMps = _lastReportedSpeedKmh > 0
        ? (_lastReportedSpeedKmh / 3.6)
        : 0.0;
    final horizon = _expectedPingSec.clamp(1.5, 5.0);
    final intervalMps = remainingMeters / horizon;

    double targetMps;
    if (reportedMps > 0.5) {
      targetMps = math.max(reportedMps, intervalMps);
    } else if (isLiveMoving.value || remainingMeters > 0.5) {
      targetMps = math.max(3.0, intervalMps);
    } else {
      targetMps = math.max(0.5, remainingMeters);
    }
    targetMps = targetMps.clamp(0.5, 45.0);

    // Smooth speed change
    final alpha = 1.0 - math.exp(-dt / 0.25);
    _currentLiveSpeedMs += (targetMps - _currentLiveSpeedMs) * alpha;
    if (_currentLiveSpeedMs < 0.5 && remainingMeters > 0.1) {
      _currentLiveSpeedMs = 0.5;
    }

    double distanceBudget = _currentLiveSpeedMs * dt;

    // Advance along waypoint queue
    while (distanceBudget > 0 &&
        _liveWaypointIndex < _liveWaypoints.length - 1) {
      final a = _liveWaypoints[_liveWaypointIndex];
      final b = _liveWaypoints[_liveWaypointIndex + 1];
      final segMeters = _calculateDistance(a, b);
      if (segMeters <= 1e-4) {
        _liveWaypointIndex++;
        _liveWaypointFraction = 0.0;
        continue;
      }
      final currentT = _liveWaypointFraction.clamp(0.0, 1.0);
      final remainingSeg = segMeters * (1.0 - currentT);
      if (distanceBudget >= remainingSeg) {
        distanceBudget -= remainingSeg;
        _liveWaypointIndex++;
        _liveWaypointFraction = 0.0;
      } else {
        _liveWaypointFraction = (currentT + distanceBudget / segMeters).clamp(
          0.0,
          1.0,
        );
        distanceBudget = 0.0;
      }
    }

    // Interpolate marker position & bearing
    if (_liveWaypointIndex >= _liveWaypoints.length - 1) {
      final dest = _liveWaypoints.last;
      liveMarkerPosition.value = dest;
      if (isLiveLocked.value) {
        _followLiveCamera(dest);
      }
    } else {
      final a = _liveWaypoints[_liveWaypointIndex];
      final b = _liveWaypoints[_liveWaypointIndex + 1];
      final t = _liveWaypointFraction.clamp(0.0, 1.0);
      final interpolated = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      liveMarkerPosition.value = interpolated;

      final targetBearing = _getBearing(a, b);
      final prevBearing = liveMarkerBearing.value ?? targetBearing;
      liveMarkerBearing.value = _lerpBearing(prevBearing, targetBearing, 0.25);

      if (isLiveLocked.value) {
        _followLiveCamera(interpolated);
      }
    }

    // Memory cleanup: trim passed waypoints
    if (_liveWaypointIndex > 30) {
      final keepFrom = _liveWaypointIndex;
      _liveWaypoints.removeRange(0, keepFrom);
      _liveWaypointIndex = 0;
    }
  }

  void _followLiveCamera(LatLng point) {
    if (!isLiveLocked.value) return;
    try {
      var zoom = 16.0;
      try {
        zoom = liveMapController.camera.zoom;
      } catch (_) {}
      if (zoom < 13.0) zoom = 16.0;

      liveMapController.move(point, zoom);
    } catch (_) {}
  }

  Future<void> _requestRoadPath(LatLng from, LatLng to) async {
    if (_calculateDistance(from, to) < 3.0 || _roadFetchInFlight) return;
    _roadFetchInFlight = true;
    final int session = _liveSessionId;
    try {
      final road = await _directionsService.getRoute(from, to, smooth: false);
      if (_liveDisposed || session != _liveSessionId || road.length < 2) return;

      // Reject detours (one-way / wrong-side snapping) that would send the
      // marker far away and back, which looks like a jump.
      final straight = _calculateDistance(from, to);
      if (_polylineLengthMeters(road) > straight * 2.5 + 150.0) return;

      // FIX: locate the exact from→to segment still in the queue. The old
      // code replaced the whole queue from the marker's current index and
      // kept the old fraction on a different segment, so the marker skipped
      // ahead to the new road start.
      int seg = -1;
      for (int i = _liveWaypoints.length - 2; i >= 0; i--) {
        if (_calculateDistance(_liveWaypoints[i], from) < 1.0 &&
            _calculateDistance(_liveWaypoints[i + 1], to) < 1.0) {
          seg = i;
          break;
        }
      }
      if (seg < 0 || seg < _liveWaypointIndex) return; // already passed

      // Road geometry between the two fixes (endpoints are the fixes themselves).
      final interior = <LatLng>[];
      for (int i = 1; i < road.length - 1; i++) {
        final p = road[i];
        if (_calculateDistance(p, from) < 1.0 ||
            _calculateDistance(p, to) < 1.0) {
          continue;
        }
        if (interior.isEmpty || _calculateDistance(interior.last, p) >= 0.6) {
          interior.add(p);
        }
      }

      if (seg > _liveWaypointIndex) {
        // Marker hasn't reached this segment yet: splice road in place.
        // Index and fraction stay valid, so there is no visual jump.
        if (interior.isNotEmpty) {
          _liveWaypoints.insertAll(seg + 1, interior);
        }
        return;
      }

      // Marker is currently on this segment: continue from where it is now.
      final currentPos = liveMarkerPosition.value ?? from;
      final roadNoEnd = road.length > 2
          ? road.sublist(0, road.length - 1)
          : road;
      final ahead = _trimRouteAhead(
        currentPos,
        roadNoEnd,
      ).where((p) => _calculateDistance(p, to) >= 1.0).toList();
      final head = _liveWaypoints.sublist(0, seg);
      final tail = _liveWaypoints.sublist(seg + 1); // starts with `to`
      _liveWaypoints
        ..clear()
        ..addAll([...head, currentPos, ...ahead, ...tail]);
      _liveWaypointIndex = head.length;
      _liveWaypointFraction = 0.0;
    } catch (e) {
      debugPrint('[LiveTrack] Road fetch error: $e');
    } finally {
      _roadFetchInFlight = false;
    }
  }

  double _polylineLengthMeters(List<LatLng> pts) {
    double total = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += _calculateDistance(pts[i], pts[i + 1]);
    }
    return total;
  }

  List<LatLng> _trimRouteAhead(LatLng from, List<LatLng> route) {
    if (route.isEmpty) return route;
    if (route.length == 1) return List<LatLng>.from(route);

    // FIX: pick the closest point on any segment (not just the segment after
    // the closest vertex), so the projected start never lands ahead of the car.
    var bestSeg = 0;
    var bestDist = double.infinity;
    var bestPoint = route.first;
    for (var i = 0; i < route.length - 1; i++) {
      final p = _projectOnSegment(from, route[i], route[i + 1]);
      final d = _calculateDistance(from, p);
      if (d < bestDist) {
        bestDist = d;
        bestSeg = i;
        bestPoint = p;
      }
    }

    final out = <LatLng>[bestPoint];
    for (var i = bestSeg + 1; i < route.length; i++) {
      if (_calculateDistance(out.last, route[i]) >= 0.6) {
        out.add(route[i]);
      }
    }
    return out;
  }

  LatLng _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;
    final dx = bx - ax;
    final dy = by - ay;
    if (dx == 0 && dy == 0) return a;
    final t = (((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)).clamp(
      0.0,
      1.0,
    );
    return LatLng(ay + dy * t, ax + dx * t);
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const radius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180) *
            math.cos(p2.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radius * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  void recenterLiveMap() {
    isLiveLocked.value = true;
    final pt =
        liveMarkerPosition.value ??
        (vehicleDetail.value.latitude != null &&
                vehicleDetail.value.longitude != null
            ? LatLng(
                vehicleDetail.value.latitude!,
                vehicleDetail.value.longitude!,
              )
            : null);
    if (pt != null) {
      _followLiveCamera(pt);
    }
  }

  void zoomInLiveMap() {
    try {
      final cam = liveMapController.camera;
      liveMapController.move(cam.center, (cam.zoom + 1.0).clamp(3.0, 19.0));
    } catch (_) {}
  }

  void zoomOutLiveMap() {
    try {
      final cam = liveMapController.camera;
      liveMapController.move(cam.center, (cam.zoom - 1.0).clamp(3.0, 19.0));
    } catch (_) {}
  }

  void stopLiveTracking() {
    // Invalidate any in-flight start/poll/road request so it can't restart
    // timers or the socket after the user left the live tab.
    _liveSessionId++;
    _liveTrackingImei = null;
    _stopLiveAnimationLoop();
    _stopLivePollingTimer();
    unawaited(_liveTrackWs.disconnect());
    isLiveTrackingConnected.value = false;
  }
}
