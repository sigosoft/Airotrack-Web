import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final RxString startDateStr = ''.obs;
  final RxString endDateStr = ''.obs;

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

    return '';
  }

  String _getFallbackVehicleImei() {
    if (Get.isRegistered<DashboardController>()) {
      final dashController = Get.find<DashboardController>();
      if (dashController.homeController.vehicles.isNotEmpty) {
        final idx = dashController.selectedVehicleIndex.value <
                dashController.homeController.vehicles.length
            ? dashController.selectedVehicleIndex.value
            : 0;
        final imei = dashController.homeController.vehicles[idx].deviceId;
        if (imei.isNotEmpty) return imei;
      }
    }

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      if (homeController.vehicles.isNotEmpty) {
        final imei = homeController.vehicles.first.deviceId;
        if (imei.isNotEmpty) return imei;
      }
    }

    return '';
  }

  /// Load live notifications/alerts from API (GET /alerts)
  Future<void> loadNotifications({
    String? imei,
    String? period,
    String? fromDate,
    String? toDate,
    String limit = '100',
  }) async {
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        DioClient().updateToken(token.trim());
      }

      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'page': '1',
      };

      String selectedImei = _resolveImei(imei);
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqPeriod = period ?? Get.parameters['period'] ?? '';
      if (reqPeriod.isNotEmpty) queryParams['period'] = reqPeriod;

      String reqFromDate = fromDate ?? startDateStr.value;
      if (reqFromDate.isEmpty) {
        reqFromDate = Get.parameters['from_date'] ?? '';
      }
      if (reqFromDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqFromDate = Get.find<DashboardController>().reportStartDate.value;
      }
      if (reqFromDate.isNotEmpty) queryParams['from_date'] = reqFromDate;

      String reqToDate = toDate ?? endDateStr.value;
      if (reqToDate.isEmpty) {
        reqToDate = Get.parameters['to_date'] ?? '';
      }
      if (reqToDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqToDate = Get.find<DashboardController>().reportEndDate.value;
      }
      if (reqToDate.isNotEmpty) queryParams['to_date'] = reqToDate;

      var response = await DioClient().get(
        ApiEndPoints.alerts,
        queryParameters: queryParams,
      );

      // If call failed or returned status false without imei, fallback to primary vehicle
      if ((response.data == null ||
              (response.data is Map && response.data['status'] == false)) &&
          selectedImei.isEmpty) {
        final fallbackImei = _getFallbackVehicleImei();
        if (fallbackImei.isNotEmpty) {
          queryParams['imei'] = fallbackImei;
          response = await DioClient().get(
            ApiEndPoints.alerts,
            queryParameters: queryParams,
          );
        }
      }

      if (response.data != null) {
        final resData = response.data['alerts'] ??
            response.data['data'] ??
            response.data['reports'] ??
            response.data;
        List alertList = [];

        if (resData is List) {
          alertList = resData;
        } else if (resData is Map) {
          if (resData['alerts'] is List) {
            alertList = resData['alerts'];
          } else if (resData['items'] is List) {
            alertList = resData['items'];
          } else if (resData['data'] is List) {
            alertList = resData['data'];
          } else if (resData['reports'] is List) {
            alertList = resData['reports'];
          } else if (resData['list'] is List) {
            alertList = resData['list'];
          }
        }

        final List<NotificationItemData> items = [];
        for (final item in alertList) {
          if (item is Map) {
            items.add(
              NotificationItemData.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }

        rawNotifications.value = items;
        currentPage.value = 1;
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading alerts into notifications from API: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) {
    selectedTab.value = index;
    currentPage.value = 1;
    _applyFilters();
  }

  void selectPage(int page) {
    currentPage.value = page;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    _applyFilters();
  }

  void _applyFilters() {
    if (selectedTab.value != 0) {
      // Announcements (1) or Reminders (2)
      notificationData.value = NotificationModel(notifications: []);
      return;
    }

    var list = List<NotificationItemData>.from(rawNotifications);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((item) {
        return item.vehicleNumber.toLowerCase().contains(q) ||
            item.ignitionStatus.toLowerCase().contains(q) ||
            item.locationAddress.toLowerCase().contains(q) ||
            item.timestamp.toLowerCase().contains(q);
      }).toList();
    }

    notificationData.value = NotificationModel(notifications: list);
  }
}
