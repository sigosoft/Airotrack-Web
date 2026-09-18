import 'dart:developer';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/alert_model.dart';
import 'dashboard_controller.dart';
import 'home_controller.dart';
import 'vehicle_detail_controller.dart';

class AlertsController extends GetxController {
  final ScrollController scrollController = ScrollController();
  var alerts = <AlertModel>[].obs;
  var isLoading = false.obs;
  var hasMore = true.obs;
  var currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    log("AlertsController: onInit called");
    loadAlerts();
    scrollController.addListener(() {
      try {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        if (position.pixels >= position.maxScrollExtent - 100) {
          if (!isLoading.value && hasMore.value) {
            loadMoreAlerts();
          }
        }
      } catch (_) {
        // ScrollController not yet attached or detached during rebuild
      }
    });
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

  Future<void> loadAlerts({
    String? imei,
    String? period,
    String? fromDate,
    String? toDate,
    String limit = '100',
  }) async {
    log("AlertsController: loadAlerts started");
    try {
      isLoading.value = true;
      currentPage = 1;
      hasMore.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        DioClient().updateToken(token.trim());
      }

      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'page': currentPage.toString(),
      };

      String selectedImei = _resolveImei(imei);
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqPeriod = period ?? Get.parameters['period'] ?? '';
      if (reqPeriod.isNotEmpty) queryParams['period'] = reqPeriod;

      String reqFromDate = fromDate ?? Get.parameters['from_date'] ?? '';
      if (reqFromDate.isEmpty && Get.isRegistered<VehicleDetailController>()) {
        reqFromDate = Get.find<VehicleDetailController>().startDateStr.value;
      }
      if (reqFromDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqFromDate = Get.find<DashboardController>().reportStartDate.value;
      }
      if (reqFromDate.isNotEmpty) queryParams['from_date'] = reqFromDate;

      String reqToDate = toDate ?? Get.parameters['to_date'] ?? '';
      if (reqToDate.isEmpty && Get.isRegistered<VehicleDetailController>()) {
        reqToDate = Get.find<VehicleDetailController>().endDateStr.value;
      }
      if (reqToDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqToDate = Get.find<DashboardController>().reportEndDate.value;
      }
      if (reqToDate.isNotEmpty) queryParams['to_date'] = reqToDate;

      final response = await DioClient().get(
        ApiEndPoints.alertsReport,
        queryParameters: queryParams,
        options: Options(
          headers: {"Accept": "application/json"},
          validateStatus: (status) => true,
        ),
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          if (resData['items'] is List) {
            rawList = resData['items'];
          } else if (resData['alerts'] is List) {
            rawList = resData['alerts'];
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
          } else if (resData['data'] is List) {
            rawList = resData['data'];
          } else if (resData['list'] is List) {
            rawList = resData['list'];
          }
        }

        final parsedList = rawList
            .whereType<Map>()
            .map((json) => AlertModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        alerts.assignAll(parsedList);

        if (parsedList.length < (int.tryParse(limit) ?? 100)) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      log("Error loading alerts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreAlerts({
    String? imei,
    String? period,
    String? fromDate,
    String? toDate,
    String limit = '100',
  }) async {
    if (isLoading.value || !hasMore.value) return;

    try {
      isLoading.value = true;
      currentPage++;

      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'page': currentPage.toString(),
      };

      String selectedImei = _resolveImei(imei);
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqPeriod = period ?? Get.parameters['period'] ?? '';
      if (reqPeriod.isNotEmpty) queryParams['period'] = reqPeriod;

      String reqFromDate = fromDate ?? Get.parameters['from_date'] ?? '';
      if (reqFromDate.isEmpty && Get.isRegistered<VehicleDetailController>()) {
        reqFromDate = Get.find<VehicleDetailController>().startDateStr.value;
      }
      if (reqFromDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqFromDate = Get.find<DashboardController>().reportStartDate.value;
      }
      if (reqFromDate.isNotEmpty) queryParams['from_date'] = reqFromDate;

      String reqToDate = toDate ?? Get.parameters['to_date'] ?? '';
      if (reqToDate.isEmpty && Get.isRegistered<VehicleDetailController>()) {
        reqToDate = Get.find<VehicleDetailController>().endDateStr.value;
      }
      if (reqToDate.isEmpty && Get.isRegistered<DashboardController>()) {
        reqToDate = Get.find<DashboardController>().reportEndDate.value;
      }
      if (reqToDate.isNotEmpty) queryParams['to_date'] = reqToDate;

      final response = await DioClient().get(
        ApiEndPoints.alertsReport,
        queryParameters: queryParams,
        options: Options(
          headers: {"Accept": "application/json"},
          validateStatus: (status) => true,
        ),
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          if (resData['items'] is List) {
            rawList = resData['items'];
          } else if (resData['alerts'] is List) {
            rawList = resData['alerts'];
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
          } else if (resData['data'] is List) {
            rawList = resData['data'];
          } else if (resData['list'] is List) {
            rawList = resData['list'];
          }
        }

        final parsedList = rawList
            .whereType<Map>()
            .map((json) => AlertModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        if (parsedList.isEmpty) {
          hasMore.value = false;
        } else {
          alerts.addAll(parsedList);
          if (parsedList.length < (int.tryParse(limit) ?? 100)) {
            hasMore.value = false;
          }
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      log("Error loading more alerts: $e");
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
