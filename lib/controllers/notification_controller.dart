import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/notification_model.dart';
import 'dashboard_controller.dart';
import 'home_controller.dart';
import 'vehicle_detail_controller.dart';

class NotificationController extends GetxController {
  final RxInt selectedTab = 0.obs; // 0: Alerts, 1: Announcements, 2: Reminders
  final RxInt currentPage = 1.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  final Rx<NotificationModel> notificationData = NotificationModel(
    notifications: [],
  ).obs;

  final rawNotifications = <NotificationItemData>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  String _resolveImei(String? imei) {
    String selectedImei = imei ?? Get.parameters['imei'] ?? '';
    if (selectedImei.isNotEmpty) return selectedImei;

    if (Get.isRegistered<VehicleDetailController>()) {
      selectedImei = Get.find<VehicleDetailController>().activeImei;
      if (selectedImei.isNotEmpty) return selectedImei;
    }

    if (Get.isRegistered<DashboardController>()) {
      final dashController = Get.find<DashboardController>();
      if (dashController.homeController.vehicles.isNotEmpty) {
        final idx = dashController.selectedVehicleIndex.value <
                dashController.homeController.vehicles.length
            ? dashController.selectedVehicleIndex.value
            : 0;
        selectedImei = dashController.homeController.vehicles[idx].deviceId;
        if (selectedImei.isNotEmpty) return selectedImei;
      }
    }

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      if (homeController.vehicles.isNotEmpty) {
        selectedImei = homeController.vehicles.first.deviceId;
        if (selectedImei.isNotEmpty) return selectedImei;
      }
    }

    return selectedImei;
  }

  /// Load live notifications/alerts from API (GET /reports/alerts)
  Future<void> loadNotifications({
    String? imei,
    String? period,
    String? fromDate,
    String? toDate,
    String limit = '25',
  }) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'page': currentPage.value.toString(),
      };

      String selectedImei = _resolveImei(imei);
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqPeriod = period ?? Get.parameters['period'] ?? '';
      if (reqPeriod.isNotEmpty) queryParams['period'] = reqPeriod;

      String reqFromDate = fromDate ?? Get.parameters['from_date'] ?? '';
      if (reqFromDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqFromDate = Get.find<DashboardController>().reportStartDate.value;
      }
      if (reqFromDate.isNotEmpty) queryParams['from_date'] = reqFromDate;

      String reqToDate = toDate ?? Get.parameters['to_date'] ?? '';
      if (reqToDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqToDate = Get.find<DashboardController>().reportEndDate.value;
      }
      if (reqToDate.isNotEmpty) queryParams['to_date'] = reqToDate;

      var response = await DioClient().get(
        ApiEndPoints.alertsReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List alertList = [];

        if (resData is List) {
          alertList = resData;
        } else if (resData is Map) {
          if (resData['items'] is List) {
            alertList = resData['items'];
          } else if (resData['alerts'] is List) {
            alertList = resData['alerts'];
          } else if (resData['reports'] is List) {
            alertList = resData['reports'];
          } else if (resData['data'] is List) {
            alertList = resData['data'];
          } else if (resData['list'] is List) {
            alertList = resData['list'];
          }
        }

        final List<NotificationItemData> items = [];
        for (final item in alertList) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);

            final vehMap = map['vehicle'];
            String vehNum = '';
            if (vehMap is Map) {
              vehNum = vehMap['vehicle_number']?.toString() ??
                  vehMap['plate_number']?.toString() ??
                  vehMap['name']?.toString() ??
                  '';
            }
            if (vehNum.isEmpty) {
              vehNum = map['vehicle_number']?.toString() ??
                  map['vehicle_name']?.toString() ??
                  map['plate_number']?.toString() ??
                  map['name']?.toString() ??
                  map['imei']?.toString() ??
                  'Vehicle N/A';
            }

            final isIgn = map['ignition'] == 1 ||
                map['ignition'] == true ||
                map['is_ignition_on'] == true ||
                map['status'] == '1' ||
                map['type']?.toString().toLowerCase().contains('on') == true;

            final typeStr = map['alert_description']?.toString() ??
                map['alert_type']?.toString() ??
                map['type']?.toString() ??
                map['event']?.toString() ??
                map['title']?.toString() ??
                (isIgn ? 'Ignition On' : 'Ignition Off');

            final locStr = map['address']?.toString() ??
                map['location']?.toString() ??
                map['start_address']?.toString() ??
                (map['latitude'] != null
                    ? "${map['latitude']}, ${map['longitude']}"
                    : 'Location N/A');

            final timeStr = map['datetime']?.toString() ??
                map['created_at']?.toString() ??
                map['device_time']?.toString() ??
                map['time']?.toString() ??
                map['timestamp']?.toString() ??
                map['date_time']?.toString() ??
                'N/A';

            items.add(
              NotificationItemData(
                vehicleNumber: vehNum,
                ignitionStatus: typeStr,
                isIgnitionOn: isIgn,
                locationAddress: locStr,
                timestamp: timeStr,
              ),
            );
          }
        }

        rawNotifications.value = items;
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading notifications from API (limit: $limit): $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) {
    selectedTab.value = index;
    _applyFilters();
  }

  void selectPage(int page) {
    currentPage.value = page;
    loadNotifications();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<NotificationItemData>.from(rawNotifications);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((item) {
        return item.vehicleNumber.toLowerCase().contains(q) ||
            item.ignitionStatus.toLowerCase().contains(q) ||
            item.locationAddress.toLowerCase().contains(q);
      }).toList();
    }

    notificationData.value = NotificationModel(notifications: list);
  }
}
