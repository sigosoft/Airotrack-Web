import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/vehicle_detail_model.dart';
import '../models/vehicle_model.dart';
import '../utils/app_toast.dart';
import 'alerts_controller.dart';
import 'dashboard_controller.dart';
import 'home_controller.dart';

class VehicleDetailController extends GetxController {
  final RxInt selectedTopTab = (-1).obs; // -1: Vehicle Info Detail, 0: History, 1: Alerts, 2: Statistics
  final RxBool isMapDialogVisible = false.obs;
  final RxBool isHistoryMapDialogVisible = false.obs;
  final RxDouble playbackProgress = 0.3.obs;
  final RxBool isPlaying = false.obs;
  final RxString playbackSpeed = '1x'.obs;
  final RxString startDateStr = '28-08-2025 12:00 AM'.obs;
  final RxString endDateStr = '28-08-2025 12:00 AM'.obs;

  final RxBool isLoading = false.obs;
  final historyPoints = <Map<String, dynamic>>[].obs;
  final liveTrackData = <String, dynamic>{}.obs;

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
      SensorReadingItem(label: 'Battery', value: 'ON', iconType: 'battery'),
      SensorReadingItem(label: 'Car Battery', value: '12V', iconType: 'car_battery'),
      SensorReadingItem(label: 'Satellite', value: '15', iconType: 'satellite'),
      SensorReadingItem(label: 'Fuel', value: 'N/A', iconType: 'fuel'),
      SensorReadingItem(label: 'Accuracy', value: '0.0', iconType: 'accuracy'),
      SensorReadingItem(label: 'Temperature', value: 'N/A', iconType: 'temp'),
      SensorReadingItem(label: 'Movement', value: 'False', iconType: 'movement'),
      SensorReadingItem(label: 'Movement', value: 'N/A', iconType: 'movement2'),
    ],
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _bindToHomeController();
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
      loadVehicleSnapshot(v.deviceId);
      loadLiveTrack(v.deviceId);
    }
  }

  /// Load live tracking snapshot for vehicle by IMEI (GET /live_track_snapshot)
  Future<void> loadVehicleSnapshot(String imei) async {
    if (imei.isEmpty) return;
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
    final targetImei = (imei != null && imei.isNotEmpty) ? imei : activeImei;
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

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['location_history'] is List) {
          final List<dynamic> raw = data['location_history'];
          historyPoints.value = raw.map((j) => Map<String, dynamic>.from(j as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading vehicle history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) {
    selectedTopTab.value = index;

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
    } else if (index == 2 || index == -1) {
      // Statistics / Info Details Tab
      if (activeImei.isNotEmpty) {
        loadVehicleSnapshot(activeImei);
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

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
  }
}
