import 'dart:developer';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/alert_model.dart';

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

  Future<void> loadAlerts() async {
    log("AlertsController: loadAlerts started");
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        DioClient().updateToken(token.trim());
      }

      // Strictly following the provided API request structure: imei=&limit=100
      final Map<String, dynamic> queryParams = {
        'imei': Get.parameters['imei'] ?? '',
        'limit': '100',
      };

      final response = await DioClient().get(
        ApiEndPoints.alerts,
        queryParameters: queryParams,
        options: Options(
          headers: {"Accept": "application/json"},
          validateStatus: (status) => true,
        ),
      );

      // Diagnostic Logging
      log("[Alerts] Debug - Status: ${response.statusCode}");
      log("[Alerts] Debug - Data: ${response.data}");
      log(
        "[Alerts] Token (start): ${token != null ? token.substring(0, math.min(10, token.length)) : 'NO TOKEN'}...",
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] != null &&
          response.data['data']['alerts'] != null) {
        final List<dynamic> data = response.data['data']['alerts'];
        alerts.assignAll(
          data.map((json) => AlertModel.fromJson(json)).toList(),
        );

        if (data.isEmpty) {
          log("[Alerts] Notice: List is empty (Matching Postman).");
        }

        if (data.length < 100) {
          hasMore.value = false;
        }
      } else {
        log(
          "[Alerts] API Request failed or list not found. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      log("Error loading alerts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreAlerts() async {
    // Basic pagination if supported, assuming similar structure
    if (isLoading.value || !hasMore.value) return;

    try {
      isLoading.value = true;
      currentPage++;

      final Map<String, dynamic> queryParams = {
        'imei': Get.parameters['imei'] ?? '',
        'limit': '100',
        'page': currentPage.toString(),
      };

      final response = await DioClient().get(
        ApiEndPoints.alerts,
        queryParameters: queryParams,
        options: Options(
          headers: {"Content-Type": null, "X-Requested-With": "XMLHttpRequest"},
          validateStatus: (status) => true,
        ),
      );

      if (response.data != null &&
          response.data['data'] != null &&
          response.data['data']['alerts'] != null) {
        final List<dynamic> data = response.data['data']['alerts'];
        if (data.isEmpty) {
          hasMore.value = false;
        } else {
          alerts.addAll(data.map((json) => AlertModel.fromJson(json)).toList());
          if (data.length < 100) {
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
