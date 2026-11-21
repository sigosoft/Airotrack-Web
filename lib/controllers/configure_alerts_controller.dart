import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../services/lookups_service.dart';
import '../utils/app_toast.dart';

/// Profile > Configure Alerts.
/// GET alert_types, GET vehicles, GET vehicle_alerts?imei=,
/// POST update_vehicle_alerts (imei + alerts[]).
class ConfigureAlertsController extends GetxController {
  final alertOptions = <LookupOption>[].obs;
  final vehicles = <VehicleOption>[].obs;
  final searchQuery = ''.obs;

  final isLoading = false.obs;
  final isLoadingAlerts = false.obs;
  final isSaving = false.obs;

  /// Vehicle whose checklist is open (null = none selected).
  final selectedVehicle = Rxn<VehicleOption>();

  /// Alert keys switched on for the selected vehicle.
  final selectedAlerts = <String>{}.obs;

  List<VehicleOption> get filteredVehicles {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return vehicles.toList();
    return vehicles
        .where(
          (v) =>
              v.vehicleNumber.toLowerCase().contains(q) ||
              v.imei.toLowerCase().contains(q),
        )
        .toList();
  }

  bool get allSelected =>
      alertOptions.isNotEmpty &&
      alertOptions.every((o) => selectedAlerts.contains(o.key));

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await Future.wait([_loadAlertTypes(), _loadVehicles()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAlertTypes() async {
    try {
      final response = await DioClient().get(ApiEndPoints.alertTypes);
      final data = LookupsService.dataOf(response);
      alertOptions.assignAll(
        LookupOption.listFrom(data is Map ? data['alerts'] : null),
      );
    } catch (e) {
      debugPrint('[ConfigureAlerts] alert_types failed: $e');
      AppToast.showErrorMessage(e);
    }
  }

  Future<void> _loadVehicles() async {
    vehicles.assignAll(await LookupsService.vehicles(refresh: true));
  }

  /// Opens the checklist for [vehicle] with the alerts already switched on.
  Future<void> selectVehicle(VehicleOption vehicle) async {
    selectedVehicle.value = vehicle;
    selectedAlerts.clear();
    isLoadingAlerts.value = true;
    try {
      final response = await DioClient().get(
        ApiEndPoints.vehicleAlerts,
        queryParameters: {'imei': vehicle.imei},
      );
      if (selectedVehicle.value?.imei != vehicle.imei) return;
      if (!LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: 'Could not load the vehicle alerts',
          ),
          isError: true,
        );
        return;
      }
      final data = LookupsService.dataOf(response);
      final list = data is Map ? data['alerts'] : null;
      final onKeys = <String>{};
      if (list is List) {
        for (final item in list) {
          if (item is Map && item['key'] != null) {
            onKeys.add(item['key'].toString());
          } else if (item != null) {
            onKeys.add(item.toString());
          }
        }
      }
      selectedAlerts.assignAll(onKeys);
    } catch (e) {
      AppToast.showErrorMessage(e);
    } finally {
      isLoadingAlerts.value = false;
    }
  }

  void toggleAlert(String key) {
    if (!selectedAlerts.remove(key)) selectedAlerts.add(key);
  }

  void toggleAll() {
    if (allSelected) {
      selectedAlerts.clear();
    } else {
      selectedAlerts.assignAll(alertOptions.map((o) => o.key));
    }
  }

  /// POST update_vehicle_alerts with imei and the ticked alerts[].
  Future<void> save() async {
    final vehicle = selectedVehicle.value;
    if (vehicle == null || isSaving.value) return;
    isSaving.value = true;
    try {
      final form = FormData();
      form.fields.add(MapEntry('imei', vehicle.imei));
      for (final key in selectedAlerts) {
        form.fields.add(MapEntry('alerts[]', key));
      }
      final response = await DioClient().post(
        ApiEndPoints.updateVehicleAlerts,
        body: form,
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(response, fallback: 'Alerts updated'),
        );
      } else {
        AppToast.show(
          LookupsService.messageOf(response, fallback: 'Could not save alerts'),
          isError: true,
        );
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
    } finally {
      isSaving.value = false;
    }
  }
}
