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
  final RxInt selectedTopTab = (-1).obs; // -1: Vehicle Info Detail, 0: History, 1: Alerts, 2: Statistics
  final RxBool isMapDialogVisible = false.obs;
  final RxBool isHistoryMapDialogVisible = false.obs;

  // Live Tracking Motion & Real-Time Engine
  final Rxn<LatLng> liveMarkerPosition = Rxn<LatLng>();
  final RxDouble liveMarkerBearing = 0.0.obs;
  final RxBool isLiveTrackingConnected = false.obs;
  final RxBool isLiveLocked = true.obs;
  final RxList<LatLng> liveRoadPolyline = <LatLng>[].obs;
  final MapController liveMapController = MapController();

  final LiveTrackWebSocketService _liveTrackWs = LiveTrackWebSocketService();
  final DirectionsService _directionsService = DirectionsService();

  LiveWebsocketConfig? _wsConfig;
  LiveWebsocketInfo? _wsInfo;

  Ticker? _liveTicker;
  Duration _lastLiveTickStamp = Duration.zero;

  double _pathLat = 0.0;
  double _pathLng = 0.0;
  double _corrLat = 0.0;
  double _corrLng = 0.0;
  double _lockedBearing = 0.0;
  double _uiHeading = 0.0;
  bool _hasLiveHeading = false;

  LatLng? _liveTarget;
  LatLng? _lastAcceptedGps;
  DateTime? _lastGpsTime;
  double _lastReportedSpeedKmh = 0.0;
  double _lastInferredSpeedKmh = 0.0;
  bool _isMovingVehicle = false;
  double _glideSpeedMs = 0.0;
  double _expectedPingSec = 6.0;

  int _routeRequestId = 0;
  final List<LatLng> _roadQueue = [];
  final List<LatLng> _gpsTrace = [];
  final List<LatLng> _lastRoadCorridor = [];
  bool _roadFetchInFlight = false;
  LatLng? _pendingRoadTarget;
  DateTime? _lastRoadFetchAt;
  bool _liveDisposed = false;

  static const double _speedTau = 0.50;
  static const double _correctionTau = 0.40;
  static const double _maxCorrectionM = 30.0;
  static const double _teleportCorrectionM = 90.0;
  static const double _maxGlideSpeedMs = 45.0;
  static const double _minRollSpeedMs = 0.6;
  static const double _stoppedCreepMs = 0.35;
  static const double _stoppedGpsDeadbandM = 6.0;
  static const double _headingLookAheadM = 14.0;
  static const double _maxUiHeadingDegPerSec = 60.0;
  static const double _roadWaypointMinM = 4.0;
  static const double _minRoadRouteMeters = 8.0;
  static const double _maxBackwardBearingDeg = 95.0;
  static const double _snapBackMinLagMeters = 4.0;
  static const double _reverseGpsStepMeters = 4.0;
  static const double _reconnectSnapMeters = 150.0;
  static const double _minGpsBearingMoveM = 10.0;
  static const int _gpsTraceMaxPoints = 8;

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

  late final RxString startDateStr =
      _formatInitialDate(DateTime.now(), isStart: true).obs;
  late final RxString endDateStr =
      _formatInitialDate(DateTime.now(), isStart: false).obs;

  final RxBool isLoading = false.obs;
  final RxBool isStatisticsLoading = false.obs;
  final historyPoints = <Map<String, dynamic>>[].obs;
  final liveTrackData = <String, dynamic>{}.obs;

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
      SensorReadingItem(label: 'Car Battery', value: '-', iconType: 'car_battery'),
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
    _bindToHomeController();
    placeMovingMarkerAtStart();
  }

  void _bindToHomeController() {
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      if (homeCtrl.vehicles.isNotEmpty) {
        final dashCtrl = Get.isRegistered<DashboardController>() ? Get.find<DashboardController>() : null;
        final idx = (dashCtrl != null && dashCtrl.selectedVehicleIndex.value < homeCtrl.vehicles.length)
            ? dashCtrl.selectedVehicleIndex.value
            : 0;
        updateFromVehicle(homeCtrl.vehicles[idx]);
      }
      ever(homeCtrl.vehicles, (List<Vehicle> list) {
        if (list.isNotEmpty) {
          final dashCtrl = Get.isRegistered<DashboardController>() ? Get.find<DashboardController>() : null;
          final idx = (dashCtrl != null && dashCtrl.selectedVehicleIndex.value < list.length)
              ? dashCtrl.selectedVehicleIndex.value
              : 0;
          updateFromVehicle(list[idx]);
        }
      });
    }
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

    vehicleDetail.value = VehicleDetailData(
      vehicleNumber: v.plateNumber,
      odometerDigits: '0000000',
      timestamp: v.lastUpdated.isNotEmpty ? v.lastUpdated : 'N/A',
      distanceKm: v.todayKm,
      speedKmph: speed.toInt(),
      coordinates: coordStr,
      latitude: lat,
      longitude: lng,
      address: v.locationLabel,
      deviceTime: v.lastUpdated,
      serverTime: v.lastUpdated,
      runningDuration: v.statusDuration,
      idleDuration: v.statusDuration,
      stoppedDuration: v.statusDuration,
      inactiveDuration: v.statusDuration,
      avgSpeedKmph: v.speed,
      maxSpeedKmph: v.speed,
      todayOdoKm: v.todayKm,
      sensors: vehicleDetail.value.sensors,
    );

    if (v.deviceId.isNotEmpty) {
      if (selectedTopTab.value == -1) {
        startLiveTracking(v.deviceId);
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

        if (currentPos != null && currentPos is Map) {
          final lat = double.tryParse(currentPos['latitude']?.toString() ?? '');
          final lng = double.tryParse(currentPos['longitude']?.toString() ?? '');
          final speed = double.tryParse(currentPos['speed']?.toString() ?? '0') ?? 0.0;
          final odo = currentPos['odometer']?.toString() ?? '0';

          vehicleDetail.update((val) {
            if (val != null) {
              vehicleDetail.value = VehicleDetailData(
                vehicleNumber: currentPos['vehicle_number']?.toString() ?? currentPos['name']?.toString() ?? val.vehicleNumber,
                odometerDigits: odo.padLeft(7, '0'),
                timestamp: currentPos['device_time']?.toString() ?? val.timestamp,
                distanceKm: val.distanceKm,
                speedKmph: speed.toInt(),
                coordinates: (lat != null && lng != null)
                    ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                    : val.coordinates,
                latitude: lat ?? val.latitude,
                longitude: lng ?? val.longitude,
                address: currentPos['address']?.toString() ?? currentPos['location']?.toString() ?? val.address,
                deviceTime: currentPos['device_time']?.toString() ?? val.deviceTime,
                serverTime: currentPos['server_time']?.toString() ?? val.serverTime,
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
        body: {
          'imei': imei,
          'odometer': odometer,
        },
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(response.data['message']?.toString() ?? 'Odometer updated');
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
        final msg = response.data?['message']?.toString() ?? 'Failed to update odometer';
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
          final idx = (dashCtrl != null &&
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
        List<dynamic> raw = [];
        if (resData is List) {
          raw = resData;
        } else if (resData is Map) {
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
        initPlaybackRoute();
      }
    } catch (e) {
      debugPrint('Error loading vehicle history: $e');
    } finally {
      isLoading.value = false;
    }
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

    final fDate = (fromDate != null && fromDate.isNotEmpty) ? fromDate : startDateStr.value;
    final tDate = (toDate != null && toDate.isNotEmpty) ? toDate : endDateStr.value;

    final queryParams = <String, dynamic>{
      'imei': targetImei,
      'from_date': fDate,
      'to_date': tDate,
    };

    if (period != null && period.isNotEmpty && period.toLowerCase() != 'custom') {
      queryParams['period'] = period;
    }

    try {
      isStatisticsLoading.value = true;
      var response = await DioClient().get(
        ApiEndPoints.statistics,
        queryParameters: queryParams,
      );

      // If 422 or status false occurs due to period parameter, retry without period parameter
      if ((response.statusCode == 422 || (response.data is Map && response.data['status'] == false)) &&
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

    final routeLen = map['route_length']?.toString() ??
        map['route_distance']?.toString() ??
        map['distance']?.toString() ??
        map['total_distance']?.toString() ??
        '0 km';

    final moveDur = map['move_duration']?.toString() ??
        map['moving_duration']?.toString() ??
        map['moving_time']?.toString() ??
        '00:00:00';

    final idleDur = map['idle_duration']?.toString() ??
        map['idling_duration']?.toString() ??
        map['idle_time']?.toString() ??
        '00:00:00';

    final stopDur = map['stop_duration']?.toString() ??
        map['stopped_duration']?.toString() ??
        map['stop_time']?.toString() ??
        '00:00:00';

    final stopCnt = map['stop_count']?.toString() ??
        map['stops']?.toString() ??
        map['stopped_count']?.toString() ??
        '0';

    final avgSpd = map['average_speed']?.toString() ??
        map['avg_speed']?.toString() ??
        '0 kmph';

    final topSpd = map['top_speed']?.toString() ??
        map['max_speed']?.toString() ??
        '0 kmph';

    final overSpdCnt = map['over_speed_count']?.toString() ??
        map['overspeed_count']?.toString() ??
        map['overspeed_events']?.toString() ??
        '0';

    final engHrs = map['engine_hours']?.toString() ??
        map['engine_duration']?.toString() ??
        map['engine_on_time']?.toString() ??
        '00:00:00';

    final odo = map['odometer']?.toString() ??
        map['odo']?.toString() ??
        map['today_odo']?.toString() ??
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
    placeMovingMarkerAtStart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitHistoryRoute();
    });
  }

  void placeMovingMarkerAtStart() {
    stopMovingMarker();
    final points = getActiveRoutePoints();
    _playbackRoutePoints = List<LatLng>.from(points);
    _movingSegmentIndex = 0;
    _movingSegmentFraction = 0.0;
    playbackProgress.value = 0.0;
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
    _movingMarkerTimer = Timer.periodic(_playbackFramePeriod, (_) {
      advanceFrame();
    });
  }

  void stopMovingMarker() {
    _movingMarkerTimer?.cancel();
    _movingMarkerTimer = null;
    isPlaying.value = false;
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
        historyMapController.move(route.first, historyMapController.camera.zoom);
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
          historyMapController.move(interpolated, historyMapController.camera.zoom);
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

    final totalKm = _getTotalDistanceKm(route);
    final calculatedMps = (totalKm * 1000.0) / 30.0;
    final baseMps = math.max(60.0, calculatedMps);
    final effectiveMps = baseMps * playbackSpeedMultiplier.value;
    double distanceBudgetMeters = effectiveMps * _playbackTickSeconds;

    while (distanceBudgetMeters > 0) {
      if (_movingSegmentIndex >= route.length - 1) {
        movingMarkerPosition.value = route.last;
        final prevBearing = movingMarkerBearing.value ?? 0.0;
        final endBearing = route.length >= 2
            ? _getBearing(route[route.length - 2], route.last)
            : prevBearing;
        movingMarkerBearing.value =
            _lerpBearing(prevBearing, endBearing, _bearingSmoothing);
        playbackProgress.value = 1.0;
        traveledRoutePoints.assignAll(List<LatLng>.from(route));
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
    movingMarkerBearing.value =
        _lerpBearing(prevBearing, targetBearing, _bearingSmoothing);
    playbackProgress.value = _getProgressFromMarkerPosition(route);

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
      covered += segmentFraction *
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
    final x = math.cos(lat1) * math.sin(lat2) -
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
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return R * c;
  }

  double _distanceMeters(LatLng a, LatLng b) => _distanceKm(a, b) * 1000;

  // ---------------------------------------------------------------------
  // Live Tracking Real-Time Engine (WebSocket + Road Buffer + Motion Gliding)
  // ---------------------------------------------------------------------

  Future<void> startLiveTracking(String imei, {bool reconnectOnly = false}) async {
    if (imei.isEmpty || _liveDisposed) return;
    activeImei = imei;

    if (!reconnectOnly) {
      _stopLiveAnimationLoop();
      await _liveTrackWs.disconnect();
      _roadQueue.clear();
      _gpsTrace.clear();
      _lastRoadCorridor.clear();
      _roadFetchInFlight = false;
      _pendingRoadTarget = null;
      _pathLat = 0.0;
      _pathLng = 0.0;
      _corrLat = 0.0;
      _corrLng = 0.0;
      _lockedBearing = 0.0;
      _uiHeading = 0.0;
      _hasLiveHeading = false;
      _liveTarget = null;
      _lastAcceptedGps = null;
      _lastGpsTime = null;
      _lastReportedSpeedKmh = 0.0;
      _lastInferredSpeedKmh = 0.0;
      _isMovingVehicle = false;
      _glideSpeedMs = 0.0;
    }

    try {
      if (!reconnectOnly) isLoading.value = true;

      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei.trim()},
      );

      final rawBody = response.data;
      if (rawBody is! Map) return;
      final body = Map<String, dynamic>.from(rawBody);
      final snapshot = LiveTrackSnapshotModel.fromJson(body);
      final data = snapshot.data;
      if (data == null) return;

      _wsConfig = data.websocketConfig;
      _wsInfo = data.websocket;

      final pos = data.currentPosition;
      if (pos != null) {
        final lat = double.tryParse(pos.latitude ?? '');
        final lng = double.tryParse(pos.longitude ?? '');
        final speed = pos.speed ?? 0.0;
        final odo = pos.odometer?.toString() ?? '0';

        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber: data.vehicleInfo?.vehicleNumber ?? val.vehicleNumber,
              odometerDigits: odo.replaceAll(RegExp(r'[^0-9]'), '').padLeft(7, '0'),
              timestamp: pos.deviceTime ?? val.timestamp,
              distanceKm: pos.kilometer != null ? '${pos.kilometer} km' : val.distanceKm,
              speedKmph: speed.toInt(),
              coordinates: (lat != null && lng != null)
                  ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                  : val.coordinates,
              latitude: lat ?? val.latitude,
              longitude: lng ?? val.longitude,
              address: val.address,
              deviceTime: pos.deviceTime ?? val.deviceTime,
              serverTime: pos.lastUpdate ?? val.serverTime,
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

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final location = LatLng(lat, lng);
          if (reconnectOnly && _pathLat != 0.0) {
            final current = LatLng(_pathLat + _corrLat, _pathLng + _corrLng);
            final lag = _calculateDistance(current, location);
            if (lag > _reconnectSnapMeters && _isForwardOf(location, current)) {
              _snapLiveMarkerTo(location, speed);
            } else if (lag > 1.0) {
              _onLiveDevicePosition(location, speed, status: pos.derivedStatus);
            }
          } else {
            _setPathPosition(location);
            _liveTarget = location;
            _lastAcceptedGps = location;
            _lastGpsTime = DateTime.now();
            _lastReportedSpeedKmh = speed;
            _lastInferredSpeedKmh = speed;
            _isMovingVehicle = speed > 0;
            _glideSpeedMs = speed > 0 ? (speed / 3.6).clamp(0.0, _maxGlideSpeedMs) : 0.0;
            _gpsTrace
              ..clear()
              ..add(location);

            _requestRoadPath(location, force: true);
            _publishLiveFrame(force: true);

            if (isLiveLocked.value) {
              recenterLiveMap();
            }
          }
        }
      }

      if (!reconnectOnly) {
        _startLiveAnimationLoop();
        await _connectLiveWebSocket(imei);
      }
    } catch (e) {
      debugPrint('[LiveTrack] Error starting live tracking: $e');
    } finally {
      if (!reconnectOnly) isLoading.value = false;
    }
  }

  Future<void> _connectLiveWebSocket(String imei) async {
    if (_wsConfig == null) {
      debugPrint('[LiveTrack] WebSocket config missing from API snapshot');
      return;
    }

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

    isLiveTrackingConnected.value = connected;
  }

  void _handleLiveDeviceUpdate(Map<String, dynamic> data) {
    if (_liveDisposed) return;
    try {
      final pos = LiveCurrentPosition.fromJson(data);
      final lat = double.tryParse(pos.latitude ?? '');
      final lng = double.tryParse(pos.longitude ?? '');
      if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) return;

      final speed = pos.speed ?? 0.0;
      final odo = pos.odometer?.toString() ?? vehicleDetail.value.odometerDigits;
      final status = pos.derivedStatus;

      vehicleDetail.update((val) {
        if (val != null) {
          vehicleDetail.value = VehicleDetailData(
            vehicleNumber: val.vehicleNumber,
            odometerDigits: odo.replaceAll(RegExp(r'[^0-9]'), '').padLeft(7, '0'),
            timestamp: pos.deviceTime ?? val.timestamp,
            distanceKm: pos.kilometer != null ? '${pos.kilometer} km' : val.distanceKm,
            speedKmph: speed.toInt(),
            coordinates: '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E',
            latitude: lat,
            longitude: lng,
            address: val.address,
            deviceTime: pos.deviceTime ?? val.deviceTime,
            serverTime: pos.lastUpdate ?? val.serverTime,
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

      _onLiveDevicePosition(
        LatLng(lat, lng),
        speed,
        status: status,
        courseDeg: pos.course,
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
  }) {
    final now = DateTime.now();
    final previousGps = _lastAcceptedGps;
    final previousGpsTime = _lastGpsTime;

    final reportedKmH = speedKmH;
    final inferredKmH = _inferSpeedKmh(location, speedKmH, now);
    _lastReportedSpeedKmh = reportedKmH;
    _lastInferredSpeedKmh = inferredKmH;

    if (previousGpsTime != null) {
      final interval = now.difference(previousGpsTime).inMilliseconds / 1000.0;
      if (interval >= 0.8 && interval < 60.0) {
        _expectedPingSec = _expectedPingSec * 0.7 + interval * 0.3;
      }
    }

    _isMovingVehicle = reportedKmH > 0;

    if (!_isMovingVehicle) {
      final gpsDeltaM =
          previousGps == null ? 0.0 : _calculateDistance(previousGps, location);
      if (previousGps != null && gpsDeltaM < _stoppedGpsDeadbandM) {
        _lastGpsTime = now;
        return;
      }
      if (!_hasLiveHeading &&
          courseDeg != null &&
          courseDeg >= 0 &&
          courseDeg <= 360) {
        _setLockedBearing(courseDeg % 360);
      }
      _lastAcceptedGps = location;
      _lastGpsTime = now;
      _liveTarget = location;
      _requestRoadPath(location, force: true);
      return;
    }

    if (previousGps != null && _isLikelySnapBack(location, previousGps)) {
      _lastGpsTime = now;
      return;
    }

    _updateHeadingFromMovement(
      location,
      previousGps: previousGps,
      courseDeg: courseDeg,
    );

    _lastAcceptedGps = location;
    _lastGpsTime = now;
    _liveTarget = location;

    _requestRoadPath(location, force: _roadQueue.length < 2);
  }

  void _snapLiveMarkerTo(LatLng location, double speedKmH) {
    _roadQueue.clear();
    _gpsTrace.clear();
    _setPathPosition(location);
    _liveTarget = location;
    _lastAcceptedGps = location;
    _lastGpsTime = DateTime.now();
    _lastReportedSpeedKmh = speedKmH;
    _lastInferredSpeedKmh = speedKmH;
    _isMovingVehicle = speedKmH > 0;
    _requestRoadPath(location, force: true);
    _publishLiveFrame(force: true);
  }

  void _setPathPosition(LatLng p) {
    _pathLat = p.latitude;
    _pathLng = p.longitude;
    _corrLat = 0.0;
    _corrLng = 0.0;
  }

  void _startLiveAnimationLoop() {
    _stopLiveAnimationLoop();
    _lastLiveTickStamp = Duration.zero;
    _liveTicker = Ticker(_onLiveTick)..start();
  }

  void _stopLiveAnimationLoop() {
    final t = _liveTicker;
    _liveTicker = null;
    if (t != null) {
      t.stop(canceled: true);
      t.dispose();
    }
  }

  void _onLiveTick(Duration elapsed) {
    if (_liveDisposed) return;

    var dt = _lastLiveTickStamp == Duration.zero
        ? 1 / 60
        : (elapsed - _lastLiveTickStamp).inMicroseconds / 1000000.0;
    _lastLiveTickStamp = elapsed;
    dt = dt.clamp(1 / 240, 0.1);
    _glide(dt);
  }

  void _glide(double dt) {
    if (_pathLat == 0.0 && _pathLng == 0.0) return;
    if (_liveTarget == null) return;

    _decayCorrection(dt);

    if (_isMovingVehicle) {
      final pos = LatLng(_pathLat, _pathLng);
      final remaining = _remainingPathMeters(pos);
      final target = _targetSpeedMs(remaining);

      final alpha = 1.0 - math.exp(-dt / _speedTau);
      _glideSpeedMs += (target - _glideSpeedMs) * alpha;
      if (_glideSpeedMs < _minRollSpeedMs && remaining > 1.0) {
        _glideSpeedMs = _minRollSpeedMs;
      }
      if (_glideSpeedMs < 0) _glideSpeedMs = 0;

      var step = _glideSpeedMs * dt;
      if (step > remaining) step = remaining;

      if (step > 0.0005) {
        if (_roadQueue.isNotEmpty) {
          _advanceAlongRoad(step);
        } else {
          _bridgeForward(step);
        }
      }

      _maybePrefetchRoad(remaining);
    } else {
      _creepWhileStopped(dt);
    }

    _updateLiveHeading(dt);
    _publishLiveFrame();
  }

  void _decayCorrection(double dt) {
    if (_corrLat == 0.0 && _corrLng == 0.0) return;
    final k = math.exp(-dt / _correctionTau);
    _corrLat *= k;
    _corrLng *= k;
    if (_corrLat.abs() < 1e-9) _corrLat = 0.0;
    if (_corrLng.abs() < 1e-9) _corrLng = 0.0;
  }

  double _targetSpeedMs(double remaining) {
    final reported =
        math.max(_lastReportedSpeedKmh, _lastInferredSpeedKmh) / 3.6;
    final horizon = _expectedPingSec.clamp(1.5, 8.0);

    var v = remaining / horizon;

    if (reported > 0.4) {
      v = v.clamp(reported * 0.6, reported * 1.8);
    } else {
      v = v.clamp(0.0, 14.0);
    }

    if (remaining < 2.0) {
      v = math.min(v, math.max(remaining * 1.2, _minRollSpeedMs));
    }

    return v.clamp(0.0, _maxGlideSpeedMs);
  }

  void _advanceAlongRoad(double step) {
    var pos = LatLng(_pathLat, _pathLng);
    var remaining = step;

    while (remaining > 0.001 && _roadQueue.isNotEmpty) {
      final next = _roadQueue.first;
      final dist = _calculateDistance(pos, next);

      if (dist < 0.05) {
        _roadQueue.removeAt(0);
        continue;
      }

      if (dist <= remaining) {
        pos = next;
        remaining -= dist;
        _roadQueue.removeAt(0);
      } else {
        final f = remaining / dist;
        pos = LatLng(
          pos.latitude + (next.latitude - pos.latitude) * f,
          pos.longitude + (next.longitude - pos.longitude) * f,
        );
        remaining = 0;
      }
    }

    _pathLat = pos.latitude;
    _pathLng = pos.longitude;
  }

  void _bridgeForward(double step) {
    final t = _liveTarget;
    if (t == null) return;

    final pos = LatLng(_pathLat, _pathLng);
    final dist = _calculateDistance(pos, t);
    if (dist < 1.0) return;
    if (_isBehind(pos, t)) return;

    final bearing = _hasLiveHeading ? _lockedBearing : _getBearing(pos, t);
    final s = math.min(step, dist * 0.6);
    final next = _offsetMeters(pos, bearing, s);
    _pathLat = next.latitude;
    _pathLng = next.longitude;
  }

  void _creepWhileStopped(double dt) {
    _glideSpeedMs = 0.0;
    if (_roadQueue.isEmpty) return;

    final pos = LatLng(_pathLat, _pathLng);
    final remaining = _remainingPathMeters(pos);
    if (remaining <= 1.5) return;

    _advanceAlongRoad(math.min(_stoppedCreepMs * dt, remaining));
  }

  void _maybePrefetchRoad(double remaining) {
    final t = _liveTarget;
    if (t == null) return;

    final threshold = math.max(25.0, _glideSpeedMs * 3.0);
    if (remaining < threshold || _roadQueue.length < 2) {
      _requestRoadPath(t, force: _roadQueue.length < 2);
    }
  }

  void _updateLiveHeading(double dt) {
    if (_roadQueue.isNotEmpty) {
      final ahead = _bearingLookAhead(
        LatLng(_pathLat, _pathLng),
        _headingLookAheadM,
      );
      if (ahead != null) _lockedBearing = ahead;
    }

    if (!_hasLiveHeading) return;

    final delta = _shortestBearingDelta(_uiHeading, _lockedBearing);
    final maxStep = _maxUiHeadingDegPerSec * dt;
    final step = delta.clamp(-maxStep, maxStep);
    if (step.abs() < 0.02) return;

    _uiHeading = _normalizeBearing(_uiHeading + step);
  }

  double? _bearingLookAhead(LatLng from, double meters) {
    if (_roadQueue.isEmpty) return null;

    var traveled = 0.0;
    var prev = from;
    LatLng? pick;

    for (final p in _roadQueue) {
      traveled += _calculateDistance(prev, p);
      prev = p;
      pick = p;
      if (traveled >= meters) break;
    }

    if (pick == null) return null;
    if (_calculateDistance(from, pick) < 1.5) return null;
    return _getBearing(from, pick);
  }

  void _setLockedBearing(double bearing) {
    bearing = _normalizeBearing(bearing);
    if (!_hasLiveHeading) {
      _lockedBearing = bearing;
      _uiHeading = bearing;
      _hasLiveHeading = true;
      return;
    }
    _lockedBearing = bearing;
  }

  void _updateHeadingFromMovement(
    LatLng location, {
    LatLng? previousGps,
    double? courseDeg,
  }) {
    if (_roadQueue.length >= 2 && _hasLiveHeading) return;

    double? movementBearing;
    var movedM = 0.0;

    if (previousGps != null) {
      movedM = _calculateDistance(previousGps, location);
      if (movedM >= _minGpsBearingMoveM) {
        movementBearing = _getBearing(previousGps, location);
      }
    }

    if (movementBearing == null && _pathLat != 0.0) {
      final current = LatLng(_pathLat, _pathLng);
      movedM = _calculateDistance(current, location);
      if (movedM >= _minGpsBearingMoveM * 1.5) {
        movementBearing = _getBearing(current, location);
      }
    }

    if (movementBearing != null) {
      if (_hasLiveHeading) {
        final flip =
            _shortestBearingDelta(_lockedBearing, movementBearing).abs();
        if (flip > 55.0 && movedM < 25.0) return;
      }
      _setLockedBearing(movementBearing);
      return;
    }

    if (!_hasLiveHeading &&
        courseDeg != null &&
        courseDeg >= 0 &&
        courseDeg <= 360) {
      _setLockedBearing(courseDeg % 360);
    }
  }

  void _publishLiveFrame({bool force = false}) {
    if (_pathLat == 0.0 && _pathLng == 0.0) return;
    final point = LatLng(_pathLat + _corrLat, _pathLng + _corrLng);

    liveMarkerPosition.value = point;
    liveMarkerBearing.value = _uiHeading;

    if (isLiveLocked.value) {
      _followLiveCamera(point);
    }
  }

  void _followLiveCamera(LatLng point) {
    try {
      var zoom = 15.0;
      try {
        zoom = liveMapController.camera.zoom;
      } catch (_) {}
      liveMapController.move(point, zoom);
    } catch (_) {}
  }

  void _requestRoadPath(LatLng to, {bool force = false}) {
    _pushGpsTrace(to);
    _pendingRoadTarget = to;

    if (_pathLat == 0.0 && _pathLng == 0.0) return;
    if (_roadFetchInFlight) return;

    final now = DateTime.now();
    final queueEmpty = _roadQueue.length < 2;
    final minGapMs = queueEmpty ? 250 : 700;
    if (!force &&
        !queueEmpty &&
        _lastRoadFetchAt != null &&
        now.difference(_lastRoadFetchAt!).inMilliseconds < minGapMs) {
      return;
    }

    final from = LatLng(_pathLat, _pathLng);
    final straightM = _calculateDistance(from, to);

    if (straightM < _minRoadRouteMeters) return;
    if (!queueEmpty && straightM < 15.0 && _remainingPathMeters(from) > 20.0) {
      return;
    }
    if (_hasLiveHeading && _isBehind(from, to) && straightM < 50.0) return;

    _lastRoadFetchAt = now;
    _roadFetchInFlight = true;
    final requestId = ++_routeRequestId;
    final fromPt = from;
    final toPt = to;
    final traceCopy = <LatLng>[..._gpsTrace];

    () async {
      try {
        List<LatLng> road = const [];

        road = await _directionsService.getRoute(fromPt, toPt, smooth: false);

        if (road.length < 2 && traceCopy.length >= 2) {
          road = await _directionsService.matchTrace(
            traceCopy,
            radiusMeters: 25,
          );
        }

        if (_liveDisposed) return;
        if (requestId != _routeRequestId && _roadQueue.length >= 2) return;
        if (road.length < 2) return;

        final routeLenM = _pathLengthMeters(road);
        if (straightM > 0.5 &&
            routeLenM > straightM * 4.5 &&
            routeLenM > 40.0) {
          return;
        }

        _lastRoadCorridor
          ..clear()
          ..addAll(road);

        var prepared = _orientPathWithTravel(road);
        prepared = _decimatePath(prepared, _roadWaypointMinM);
        final trimmed = _trimRouteToUpdate(prepared, toPt);
        if (trimmed.length >= 2) prepared = trimmed;
        if (prepared.length < 2) return;

        liveRoadPolyline.assignAll(prepared);
        _adoptRoadQueue(prepared);
      } catch (e) {
        debugPrint('[LiveTrack] Mapbox road fetch error: $e');
      } finally {
        _roadFetchInFlight = false;
        final pending = _pendingRoadTarget;
        if (!_liveDisposed &&
            pending != null &&
            _calculateDistance(pending, toPt) > _minRoadRouteMeters) {
          _requestRoadPath(pending, force: _roadQueue.length < 2);
        }
      }
    }();
  }

  void _adoptRoadQueue(List<LatLng> path) {
    if (path.length < 2) return;

    final published = LatLng(_pathLat + _corrLat, _pathLng + _corrLng);
    final onNew = _closestPointOnPolyline(published, path);
    final ahead = _trimRouteAhead(onNew, path);
    if (ahead.length < 2) return;

    if (_roadQueue.length >= 2) {
      final remainingNow = _remainingPathMeters(LatLng(_pathLat, _pathLng));
      final newRemaining = _pathLengthMeters(ahead);
      if (remainingNow > 20.0 &&
          newRemaining + 1.0 < remainingNow &&
          _calculateDistance(published, onNew) < 3.0) {
        return;
      }
    }

    final offsetM = _calculateDistance(published, onNew);

    _roadQueue
      ..clear()
      ..addAll(ahead);

    _pathLat = onNew.latitude;
    _pathLng = onNew.longitude;

    if (offsetM > _teleportCorrectionM) {
      _corrLat = 0.0;
      _corrLng = 0.0;
      return;
    }

    var dLat = published.latitude - onNew.latitude;
    var dLng = published.longitude - onNew.longitude;
    if (offsetM > _maxCorrectionM && offsetM > 0) {
      final k = _maxCorrectionM / offsetM;
      dLat *= k;
      dLng *= k;
    }
    _corrLat = dLat;
    _corrLng = dLng;
  }

  double _pathLengthMeters(List<LatLng> path) {
    if (path.length < 2) return 0.0;
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += _calculateDistance(path[i - 1], path[i]);
    }
    return total;
  }

  double _remainingPathMeters(LatLng current) {
    if (_roadQueue.isEmpty) {
      if (_liveTarget == null) return 0.0;
      return _calculateDistance(current, _liveTarget!);
    }
    var total = _calculateDistance(current, _roadQueue.first);
    for (var i = 1; i < _roadQueue.length; i++) {
      total += _calculateDistance(_roadQueue[i - 1], _roadQueue[i]);
    }
    return total;
  }

  List<LatLng> _decimatePath(List<LatLng> path, double minMeters) {
    if (path.length <= 2) return path;
    final out = <LatLng>[path.first];
    for (var i = 1; i < path.length - 1; i++) {
      if (_calculateDistance(out.last, path[i]) >= minMeters) {
        out.add(path[i]);
      }
    }
    if (_calculateDistance(out.last, path.last) >= 1.0 || out.length < 2) {
      out.add(path.last);
    } else {
      out[out.length - 1] = path.last;
    }
    return out;
  }

  List<LatLng> _trimRouteToUpdate(List<LatLng> path, LatLng update) {
    if (path.length < 2) return path;

    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < path.length; i++) {
      final d = _calculateDistance(path[i], update);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }

    final onSeg = bestIdx < path.length - 1
        ? _projectOnSegment(update, path[bestIdx], path[bestIdx + 1])
        : (bestIdx > 0
            ? _projectOnSegment(update, path[bestIdx - 1], path[bestIdx])
            : path[bestIdx]);

    final out = <LatLng>[];
    final endIdx =
        bestIdx < path.length - 1 ? bestIdx : math.max(0, bestIdx - 1);
    for (var i = 0; i <= endIdx; i++) {
      out.add(path[i]);
    }
    if (out.isEmpty || _calculateDistance(out.last, onSeg) >= 0.5) {
      out.add(onSeg);
    } else {
      out[out.length - 1] = onSeg;
    }
    return out.length >= 2 ? out : path;
  }

  void _pushGpsTrace(LatLng point) {
    if (_gpsTrace.isNotEmpty &&
        _calculateDistance(_gpsTrace.last, point) < 1.5) {
      _gpsTrace[_gpsTrace.length - 1] = point;
      return;
    }
    _gpsTrace.add(point);
    while (_gpsTrace.length > _gpsTraceMaxPoints) {
      _gpsTrace.removeAt(0);
    }
  }

  List<LatLng> _orientPathWithTravel(List<LatLng> path) {
    if (path.length < 2) return path;

    final pathBearing = _pathBearingOverMeters(path, 30.0);
    if (pathBearing == null) return path;

    double? travelBearing;
    if (_gpsTrace.length >= 2) {
      final prev = _gpsTrace[_gpsTrace.length - 2];
      final curr = _gpsTrace.last;
      if (_calculateDistance(prev, curr) >= 5.0) {
        travelBearing = _getBearing(prev, curr);
      }
    }
    travelBearing ??= _hasLiveHeading ? _lockedBearing : null;
    if (travelBearing == null) return path;

    final vsTravel = _shortestBearingDelta(travelBearing, pathBearing).abs();
    if (vsTravel <= 100.0) return path;

    final reversed = path.reversed.toList();
    final revBearing = _pathBearingOverMeters(reversed, 30.0);
    if (revBearing == null) return path;

    final vsRev = _shortestBearingDelta(travelBearing, revBearing).abs();
    if (vsRev + 25.0 < vsTravel) return reversed;
    return path;
  }

  double? _pathBearingOverMeters(List<LatLng> path, double meters) {
    if (path.length < 2) return null;
    var traveled = 0.0;
    var i = 1;
    while (i < path.length && traveled < meters) {
      traveled += _calculateDistance(path[i - 1], path[i]);
      i++;
    }
    final end = path[math.min(i - 1, path.length - 1)];
    if (_calculateDistance(path.first, end) < 2.0) {
      return _getBearing(path[path.length - 2], path.last);
    }
    return _getBearing(path.first, end);
  }

  LatLng _closestPointOnPolyline(LatLng p, List<LatLng> poly) {
    if (poly.isEmpty) return p;
    if (poly.length == 1) return poly.first;

    var best = poly.first;
    var bestDist = _calculateDistance(p, best);

    for (var i = 0; i < poly.length - 1; i++) {
      final projected = _projectOnSegment(p, poly[i], poly[i + 1]);
      final d = _calculateDistance(p, projected);
      if (d < bestDist) {
        bestDist = d;
        best = projected;
      }
    }
    return best;
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
    final t = (((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy))
        .clamp(0.0, 1.0);
    return LatLng(ay + dy * t, ax + dx * t);
  }

  List<LatLng> _trimRouteAhead(LatLng from, List<LatLng> route) {
    if (route.isEmpty) return route;

    var closestIdx = 0;
    var closestDist = double.infinity;
    for (var i = 0; i < route.length; i++) {
      final d = _calculateDistance(from, route[i]);
      if (d < closestDist) {
        closestDist = d;
        closestIdx = i;
      }
    }

    final out = <LatLng>[];
    var start = closestIdx;

    if (closestIdx < route.length - 1) {
      final projected = _projectOnSegment(
        from,
        route[closestIdx],
        route[closestIdx + 1],
      );
      out.add(projected);
      start = closestIdx + 1;
    } else if (closestDist < 3.0) {
      start = closestIdx + 1;
    }

    for (var i = start; i < route.length; i++) {
      if (out.isEmpty || _calculateDistance(out.last, route[i]) >= 0.6) {
        out.add(route[i]);
      }
    }
    return out;
  }

  LatLng _offsetMeters(LatLng from, double bearingDeg, double meters) {
    const metersPerLat = 111320.0;
    final latRad = from.latitude * math.pi / 180;
    final metersPerLng = 111320.0 * math.cos(latRad);
    final rad = bearingDeg * math.pi / 180;
    return LatLng(
      from.latitude + (meters * math.cos(rad)) / metersPerLat,
      from.longitude + (meters * math.sin(rad)) / metersPerLng,
    );
  }

  bool _isForwardOf(LatLng point, LatLng origin) {
    if (!_hasLiveHeading) return true;
    final bearing = _getBearing(origin, point);
    return _shortestBearingDelta(_lockedBearing, bearing).abs() <=
        _maxBackwardBearingDeg;
  }

  bool _isBehind(LatLng current, LatLng point) {
    if (!_hasLiveHeading) return false;
    final bearing = _getBearing(current, point);
    return _shortestBearingDelta(_lockedBearing, bearing).abs() >
        _maxBackwardBearingDeg;
  }

  bool _isLikelySnapBack(LatLng location, LatLng previousGps) {
    if (!_hasLiveHeading || _pathLat == 0.0) return false;

    final animated = LatLng(_pathLat, _pathLng);
    if (!_isBehind(animated, location)) return false;

    final lagM = _calculateDistance(animated, location);
    if (lagM < _snapBackMinLagMeters) return false;

    final gpsStepM = _calculateDistance(previousGps, location);
    if (gpsStepM < 1.0) return true;

    final gpsMovingBackward = !_isForwardOf(location, previousGps) &&
        gpsStepM >= _reverseGpsStepMeters;
    return !gpsMovingBackward;
  }

  double _shortestBearingDelta(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  double _inferSpeedKmh(LatLng location, double reportedKmh, DateTime now) {
    if (_lastAcceptedGps == null || _lastGpsTime == null) return reportedKmh;

    final deltaM = _calculateDistance(_lastAcceptedGps!, location);
    if (deltaM < 1.0) return reportedKmh;

    final seconds = now.difference(_lastGpsTime!).inMilliseconds / 1000.0;
    if (seconds <= 0) return reportedKmh;

    final inferred = (deltaM / seconds) * 3.6;
    return math.max(reportedKmh, inferred);
  }

  double _normalizeBearing(double bearing) => (bearing % 360 + 360) % 360;

  double _calculateDistance(LatLng p1, LatLng p2) {
    const radius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180) *
            math.cos(p2.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radius * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  void recenterLiveMap() {
    isLiveLocked.value = true;
    final pt = liveMarkerPosition.value ??
        (vehicleDetail.value.latitude != null && vehicleDetail.value.longitude != null
            ? LatLng(vehicleDetail.value.latitude!, vehicleDetail.value.longitude!)
            : null);
    if (pt != null) {
      try {
        var zoom = 15.0;
        try {
          zoom = liveMapController.camera.zoom;
        } catch (_) {}
        liveMapController.move(pt, zoom);
      } catch (_) {}
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
    _stopLiveAnimationLoop();
    unawaited(_liveTrackWs.disconnect());
    isLiveTrackingConnected.value = false;
  }
}
