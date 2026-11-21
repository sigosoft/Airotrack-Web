import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/reminder_model.dart';
import '../services/lookups_service.dart';
import '../utils/app_toast.dart';
import '../views/reminder/widgets/create_reminder_dialog.dart';
import 'home_controller.dart';
import 'vehicle_detail_controller.dart';

/// Vehicle reminders: reminder_types, vehicle_reminders (list),
/// add / view / update / delete_vehicle_reminder.
class ReminderController extends GetxController {
  static const int pageSize = 10;

  final RxInt currentPage = 1.obs;
  final RxInt lastPage = 1.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxList<ReminderItem> reminders = <ReminderItem>[].obs;
  final RxList<LookupOption> reminderTypes = <LookupOption>[].obs;
  final RxList<VehicleOption> vehicles = <VehicleOption>[].obs;

  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce(
      searchQuery,
      (_) => loadReminders(page: 1),
      time: const Duration(milliseconds: 400),
    );
    loadReminderTypes();
    loadVehicles();
    loadReminders(page: 1);
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> loadReminderTypes() async {
    try {
      final response = await DioClient().get(ApiEndPoints.reminderTypes);
      final data = LookupsService.dataOf(response);
      reminderTypes.assignAll(
        LookupOption.listFrom(data is Map ? data['types'] : null),
      );
    } catch (e) {
      debugPrint('[Reminders] reminder_types failed: $e');
    }
  }

  Future<void> loadVehicles() async {
    vehicles.assignAll(await LookupsService.vehicles());
  }

  /// Vehicle number of the vehicle open on the tracking screen, used as the
  /// default vehicle for a new reminder.
  String? get currentVehicleNumber {
    try {
      if (!Get.isRegistered<VehicleDetailController>()) return null;
      final imei = Get.find<VehicleDetailController>().activeImei;
      if (imei.isEmpty) return null;
      for (final v in vehicles) {
        if (v.imei == imei) return v.vehicleNumber;
      }
      if (Get.isRegistered<HomeController>()) {
        for (final v in Get.find<HomeController>().vehicles) {
          if (v.deviceId == imei && v.plateNumber.isNotEmpty) {
            return v.plateNumber;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> loadReminders({int? page}) async {
    final p = page ?? currentPage.value;
    isLoading.value = true;
    try {
      final query = <String, dynamic>{'limit': pageSize, 'page': p};
      final keyword = searchQuery.value.trim();
      if (keyword.isNotEmpty) query['keyword'] = keyword;
      final response = await DioClient().get(
        ApiEndPoints.vehicleReminders,
        queryParameters: query,
      );
      if (!LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: 'Could not load reminders',
          ),
          isError: true,
        );
        return;
      }
      final data = LookupsService.dataOf(response);
      final list = data is Map ? data['reminders'] : null;
      reminders.assignAll(
        list is List
            ? list.whereType<Map>().map(ReminderItem.fromJson).toList()
            : <ReminderItem>[],
      );
      final pagination = data is Map ? data['pagination'] : null;
      if (pagination is Map) {
        currentPage.value = int.tryParse('${pagination['current_page']}') ?? p;
        lastPage.value = int.tryParse('${pagination['last_page']}') ?? 1;
      } else {
        currentPage.value = p;
        lastPage.value = 1;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void changePage(int page) {
    if (page == currentPage.value) return;
    loadReminders(page: page);
  }

  void nextPage() {
    if (currentPage.value < lastPage.value) {
      loadReminders(page: currentPage.value + 1);
    }
  }

  void addReminder() {
    final context = Get.context;
    if (context == null) return;
    showDialog(context: context, builder: (_) => const CreateReminderDialog());
  }

  /// Loads the reminder with view_vehicle_reminder, then opens the dialog
  /// filled with it.
  Future<void> editReminder(ReminderItem item) async {
    ReminderItem current = item;
    try {
      final response = await DioClient().get(
        ApiEndPoints.viewVehicleReminder,
        queryParameters: {'id': item.id},
      );
      final data = LookupsService.dataOf(response);
      if (LookupsService.isOk(response) &&
          data is Map &&
          data['reminder'] is Map) {
        current = ReminderItem.fromJson(data['reminder'] as Map);
      }
    } catch (e) {
      debugPrint('[Reminders] view failed, using list data: $e');
    }
    final context = Get.context;
    if (context == null || !context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => CreateReminderDialog(existing: current),
    );
  }

  /// Add (when [id] is null) or update a reminder. Returns true on success.
  Future<bool> saveReminder({
    String? id,
    required String vehicleNumber,
    required String type,
    required String startOdometer,
    required String period,
    String remarks = '',
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final form = FormData.fromMap({
        'id': ?id,
        'vehicle_number': vehicleNumber,
        'type': type,
        'start_odometer': startOdometer,
        'period': period,
        'remarks': remarks,
      });
      final response = await DioClient().post(
        id == null
            ? ApiEndPoints.addVehicleReminder
            : ApiEndPoints.updateVehicleReminder,
        body: form,
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: id == null ? 'Reminder created' : 'Reminder updated',
          ),
        );
        await loadReminders(page: id == null ? 1 : currentPage.value);
        return true;
      }
      AppToast.show(
        LookupsService.messageOf(response, fallback: 'Could not save reminder'),
        isError: true,
      );
      return false;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteReminder(ReminderItem item) async {
    final context = Get.context;
    if (context == null) return;
    final vehicle = item.vehicleNumber.isNotEmpty
        ? ' for ${item.vehicleNumber}'
        : '';
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Reminder',
      message: 'Delete the ${item.typeLabel} reminder$vehicle?',
    );
    if (confirmed != true) return;
    try {
      final response = await DioClient().post(
        ApiEndPoints.deleteVehicleReminder,
        body: FormData.fromMap({'id': item.id}),
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(response, fallback: 'Reminder deleted'),
        );
        // Step back a page if this was the last row on it.
        final page = reminders.length == 1 && currentPage.value > 1
            ? currentPage.value - 1
            : currentPage.value;
        await loadReminders(page: page);
      } else {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: 'Could not delete reminder',
          ),
          isError: true,
        );
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
    }
  }
}

/// Small Cancel / Delete confirmation used by reminders and expenses.
Future<bool?> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D2939),
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF344054)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF344054)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Delete',
            style: TextStyle(
              color: Color(0xFFF04438),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
