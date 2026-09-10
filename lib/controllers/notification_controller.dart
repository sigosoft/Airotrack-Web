import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/notification_model.dart';

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

  /// Load live notifications/alerts from API (GET /alerts)
  Future<void> loadNotifications({String limit = '25'}) async {
    try {
      isLoading.value = true;
      var response = await DioClient().get(
        ApiEndPoints.alerts,
        queryParameters: {'limit': limit, 'page': currentPage.value.toString()},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final List<dynamic> alertList = (data is Map && data['alerts'] is List)
            ? data['alerts']
            : (data is List ? data : []);

        final List<NotificationItemData> items = [];
        for (final item in alertList) {
          if (item is Map) {
            final isIgn =
                item['is_ignition_on'] == true ||
                item['ignition'] == true ||
                item['status'] == '1' ||
                item['type']?.toString().toLowerCase().contains('on') == true;

            final typeStr =
                item['type']?.toString() ??
                item['alert_type']?.toString() ??
                (isIgn ? 'Ignition On' : 'Ignition Off');

            items.add(
              NotificationItemData(
                vehicleNumber:
                    item['vehicle_number']?.toString() ??
                    item['name']?.toString() ??
                    item['imei']?.toString() ??
                    'Vehicle N/A',
                ignitionStatus: typeStr,
                isIgnitionOn: isIgn,
                locationAddress:
                    item['address']?.toString() ??
                    item['location']?.toString() ??
                    'Location N/A',
                timestamp:
                    item['created_at']?.toString() ??
                    item['device_time']?.toString() ??
                    item['date_time']?.toString() ??
                    'N/A',
              ),
            );
          }
        }

        rawNotifications.value = items;
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading notifications from API (limit: $limit): $e');
      if (limit == '25') {
        // Fallback retry with smaller limit if server was slow
        await loadNotifications(limit: '10');
      }
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
