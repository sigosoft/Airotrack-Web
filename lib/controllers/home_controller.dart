import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/vehicle_model.dart';

class HomeController extends GetxController {
  final vehicles = <Vehicle>[].obs;
  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;
  final RxInt selectedIndex = 1.obs;
  final ScrollController scrollController = ScrollController();
  int currentPage = 1;
  Timer? _autoUpdateTimer;

  // Status counts
  final totalCount = "0".obs;
  final runningCount = "0".obs;
  final idleCount = "0".obs;
  final stoppedCount = "0".obs;
  final expiredCount = "0".obs;
  final inactiveCount = "0".obs;

  /// Search query for filtering vehicles (plate number, address, device id).
  final searchQuery = ''.obs;

  /// API type → status: 1 Stopped, 2 Running, 3 Idle, 4 Expired.
  String? get _selectedStatusFilter {
    switch (selectedType.value) {
      case 1:
        return 'Stopped';
      case 2:
        return 'Running';
      case 3:
        return 'Idle';
      case 4:
        return 'Expired';
      default:
        return null;
    }
  }

  /// Vehicles for the selected tab (+ search). Always status-filtered on device
  /// so Stopped never appears under Running even if the API mix is wrong.
  List<Vehicle> get filteredVehicles {
    var list = vehicles.toList();
    final status = _selectedStatusFilter;
    if (status != null) {
      if (status == 'Expired') {
        list = list
            .where((v) => v.status == 'Expired' || v.status == 'Inactive')
            .toList();
      } else if (status == 'Stopped') {
        list = list
            .where((v) => v.status == 'Stopped' || v.status == 'Stop')
            .toList();
      } else {
        list = list.where((v) => v.status == status).toList();
      }
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (v) =>
              v.plateNumber.toLowerCase().contains(q) ||
              v.address.toLowerCase().contains(q) ||
              v.deviceId.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAndFetch();
    _startAutoUpdate();
    scrollController.addListener(() {
      try {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        if (position.pixels >= position.maxScrollExtent - 200) {
          if (!isLoading.value && !isMoreLoading.value && hasMore.value) {
            loadMoreVehicles();
          }
        }
      } catch (_) {
        // ScrollController not attached or has multiple clients (e.g. during rebuild)
      }
    });
  }

  void _startAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!isLoading.value && !isMoreLoading.value) {
        fetchVehicles(type: selectedType.value, isSilent: true);
      }
    });
  }

  Future<void> _initializeAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      DioClient().updateToken(token);
    }
    await fetchVehicles();
  }

  final selectedType = RxnInt();

  Future<void> fetchVehicles({int? type, bool isSilent = false}) async {
    try {
      selectedType.value = type;
      if (!isSilent) {
        currentPage = 1;
        hasMore.value = true;
        isLoading.value = true;
        errorMessage.value = '';
      }

      final response = await DioClient().get(
        ApiEndPoints.home,
        queryParameters: {
          'type': type != null ? type.toString() : '',
          'page': '1',
          'limit': '20',
        },
      );
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['vehicles_data'] != null) {
          final List<dynamic> vehiclesList = data['vehicles_data'];
          vehicles.value = _uniqueVehicles(
            vehiclesList.map((json) => Vehicle.fromJson(json)).toList(),
          );
          // No more pages when first page is shorter than the page size.
          hasMore.value = vehiclesList.length >= 20;
        } else {
          vehicles.clear();
          hasMore.value = false;
        }
        final rawStats = data['statistics'] ??
            data['stats'] ??
            data['vehicle_statistics'] ??
            data['summary'];

        if (rawStats is Map) {
          int? extract(List<String> keys) {
            for (final k in keys) {
              if (rawStats.containsKey(k) && rawStats[k] != null) {
                final str = rawStats[k].toString().trim();
                final val = int.tryParse(str);
                if (val != null) return val;
              }
            }
            return null;
          }

          final total = extract(['total_vehicles', 'total', 'all_vehicles', 'all', 'total_count']);
          final running = extract(['running_vehicles', 'running', 'moving_vehicles', 'moving', 'run']);
          final stopped = extract(['stopped_vehicles', 'stopped', 'stop_vehicles', 'stop', 'parked_vehicles', 'parked']);
          final idle = extract(['idle_vehicles', 'idle', 'idling_vehicles', 'idling']);
          final expired = extract(['expired_vehicles', 'expired']);
          final inactive = extract(['inactive_vehicles', 'inactive', 'offline_vehicles', 'offline']);

          if (total != null) totalCount.value = total.toString();
          if (running != null) runningCount.value = running.toString();
          if (stopped != null) stoppedCount.value = stopped.toString();
          if (idle != null) idleCount.value = idle.toString();
          final exp = expired ?? inactive;
          if (exp != null) {
            expiredCount.value = exp.toString();
            inactiveCount.value = exp.toString();
          }
        } else if (rawStats is List) {
          int total = 0, running = 0, stopped = 0, idle = 0, exp = 0;
          for (final item in rawStats) {
            if (item is Map) {
              final label = (item['status'] ?? item['name'] ?? item['title'] ?? item['key'] ?? '').toString().toLowerCase();
              final cnt = int.tryParse((item['count'] ?? item['value'] ?? item['total'] ?? '').toString()) ?? 0;
              if (label.startsWith('run') || label == 'moving') running = cnt;
              else if (label.startsWith('stop') || label == 'parked') stopped = cnt;
              else if (label.startsWith('idl')) idle = cnt;
              else if (label.startsWith('exp') || label.startsWith('inact')) exp = cnt;
              else if (label.startsWith('tot') || label == 'all') total = cnt;
            }
          }
          if (total == 0) total = running + stopped + idle + exp;
          totalCount.value = total.toString();
          runningCount.value = running.toString();
          stoppedCount.value = stopped.toString();
          idleCount.value = idle.toString();
          expiredCount.value = exp.toString();
          inactiveCount.value = exp.toString();
        } else if (selectedType.value == null && (totalCount.value.isEmpty || totalCount.value == '0')) {
          totalCount.value = vehicles.length.toString();
          runningCount.value = vehicles
              .where((v) => v.status == 'Running')
              .length
              .toString();
          idleCount.value = vehicles
              .where((v) => v.status == 'Idle')
              .length
              .toString();
          stoppedCount.value = vehicles
              .where((v) => v.status == 'Stopped' || v.status == 'Stop')
              .length
              .toString();
          final exp = vehicles
              .where((v) => v.status == 'Expired' || v.status == 'Inactive')
              .length
              .toString();
          expiredCount.value = exp;
          inactiveCount.value = exp;
        }
      }
    } catch (e) {
      errorMessage.value = "An error occurred: $e";
      debugPrint('==================== [HOME API ERROR] ====================');
      debugPrint("Error loading data: $e");
      debugPrint('==========================================================');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreVehicles() async {
    if (isLoading.value || isMoreLoading.value || !hasMore.value) return;
    try {
      isMoreLoading.value = true;
      final nextPage = currentPage + 1;

      final response = await DioClient().get(
        ApiEndPoints.home,
        queryParameters: {
          'type': selectedType.value != null
              ? selectedType.value.toString()
              : '',
          'page': nextPage.toString(),
          'limit': '20',
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];

        if (data['vehicles_data'] != null) {
          final List<dynamic> vehiclesList = data['vehicles_data'];
          if (vehiclesList.isEmpty) {
            hasMore.value = false;
          } else {
            final newVehicles = vehiclesList
                .map((json) => Vehicle.fromJson(json))
                .toList();
            final unique = _dedupeVehicles(newVehicles);
            if (unique.isEmpty) {
              // API repeated page-1 vehicles — stop paging.
              hasMore.value = false;
            } else {
              vehicles.addAll(unique);
              currentPage = nextPage;
              if (newVehicles.length < 20) {
                hasMore.value = false;
              }
            }
          }
        } else {
          hasMore.value = false;
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      hasMore.value = false;
    } finally {
      isMoreLoading.value = false;
    }
  }

  /// Keeps only vehicles not already in [vehicles] (by id, else IMEI/plate).
  List<Vehicle> _dedupeVehicles(List<Vehicle> incoming) {
    final existingKeys = <String>{};
    for (final v in vehicles) {
      existingKeys.add(_vehicleKey(v));
    }
    return incoming.where((v) => existingKeys.add(_vehicleKey(v))).toList();
  }

  /// Dedupes within a single page response.
  List<Vehicle> _uniqueVehicles(List<Vehicle> incoming) {
    final seen = <String>{};
    return incoming.where((v) => seen.add(_vehicleKey(v))).toList();
  }

  String _vehicleKey(Vehicle v) {
    if (v.id != 0) return 'id:${v.id}';
    if (v.deviceId.trim().isNotEmpty) return 'imei:${v.deviceId.trim()}';
    return 'plate:${v.plateNumber.trim().toLowerCase()}';
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  @override
  void onClose() {
    _autoUpdateTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
