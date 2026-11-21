import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/notification_model.dart';
import '../services/app_settings.dart';

/// Notifications page, like the mobile app: alerts for every vehicle
/// (GET alerts without imei, paged), filtered here by event type, vehicle
/// and date (the API ignores dates when no vehicle is given).
class NotificationController extends GetxController {
  final RxInt selectedTab = 0.obs; // 0: Alerts, 1: Announcements, 2: Reminders
  final RxInt currentPage = 1.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = false.obs;

  /// 'dd-MM-yyyy', '' = no limit.
  final RxString startDateStr = ''.obs;
  final RxString endDateStr = ''.obs;

  /// Empty = every event type / every vehicle.
  final selectedEventTypes = <String>{}.obs;
  final selectedVehicles = <String>{}.obs;

  final Rx<NotificationModel> notificationData = NotificationModel(
    notifications: [],
  ).obs;

  final rawNotifications = <NotificationItemData>[].obs;

  static const int _pageLimit = 200; // the API's maximum
  int _serverPage = 0;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  /// Event types and vehicles found in the loaded alerts (filter choices).
  List<String> get eventTypeOptions =>
      (rawNotifications.map((n) => n.ignitionStatus).toSet().toList()
        ..sort());
  List<String> get vehicleOptions =>
      (rawNotifications.map((n) => n.vehicleNumber).toSet().toList()..sort());

  bool get hasActiveFilters =>
      selectedEventTypes.isNotEmpty ||
      selectedVehicles.isNotEmpty ||
      startDateStr.value.isNotEmpty ||
      endDateStr.value.isNotEmpty;

  Future<List<NotificationItemData>?> _fetchPage(int page) async {
    try {
      final imei = Get.parameters['imei'] ?? '';
      final response = await DioClient().get(
        ApiEndPoints.alerts,
        queryParameters: {
          'limit': '$_pageLimit',
          'page': '$page',
          if (imei.isNotEmpty) 'imei': imei,
        },
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final list = data is Map ? data['alerts'] : null;
      if (list is! List) return null;
      final pagination = data is Map ? data['pagination'] : null;
      if (pagination is Map) {
        final current = int.tryParse('${pagination['current_page']}') ?? page;
        final last = int.tryParse('${pagination['last_page']}') ?? page;
        hasMore.value = current < last;
      } else {
        hasMore.value = list.length >= _pageLimit;
      }
      return list
          .whereType<Map>()
          .map((e) => NotificationItemData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      return null;
    }
  }

  /// First page of alerts (newest first).
  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      _serverPage = 1;
      final items = await _fetchPage(1);
      rawNotifications.assignAll(items ?? const []);
      if (items == null) hasMore.value = false;
      currentPage.value = 1;
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  /// Next page of alerts from the server, added to the list.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final items = await _fetchPage(_serverPage + 1);
      if (items == null || items.isEmpty) {
        hasMore.value = false;
      } else {
        _serverPage++;
        rawNotifications.addAll(items);
        _applyFilters();
      }
    } finally {
      isLoadingMore.value = false;
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

  void setDateRange({String? start, String? end}) {
    if (start != null) startDateStr.value = start;
    if (end != null) endDateStr.value = end;
    currentPage.value = 1;
    _applyFilters();
  }

  void applyFilters({
    required Set<String> eventTypes,
    required Set<String> vehicles,
  }) {
    // Everything ticked is the same as no filter.
    selectedEventTypes.assignAll(
      eventTypes.length == eventTypeOptions.length ? <String>{} : eventTypes,
    );
    selectedVehicles.assignAll(
      vehicles.length == vehicleOptions.length ? <String>{} : vehicles,
    );
    currentPage.value = 1;
    _applyFilters();
  }

  void clearFilters() {
    selectedEventTypes.clear();
    selectedVehicles.clear();
    startDateStr.value = '';
    endDateStr.value = '';
    currentPage.value = 1;
    _applyFilters();
  }

  static DateTime? _day(String ddMMyyyy) {
    final p = ddMMyyyy.split('-');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  void _applyFilters() {
    if (selectedTab.value != 0) {
      // Announcements (1) or Reminders (2)
      notificationData.value = NotificationModel(notifications: []);
      return;
    }

    var list = List<NotificationItemData>.from(rawNotifications);

    if (selectedEventTypes.isNotEmpty) {
      list = list
          .where((n) => selectedEventTypes.contains(n.ignitionStatus))
          .toList();
    }
    if (selectedVehicles.isNotEmpty) {
      list = list
          .where((n) => selectedVehicles.contains(n.vehicleNumber))
          .toList();
    }

    final from = _day(startDateStr.value);
    final to = _day(endDateStr.value);
    if (from != null || to != null) {
      list = list.where((n) {
        final t = AppSettings.parseDateTime(n.timestamp);
        if (t == null) return true;
        final day = DateTime(t.year, t.month, t.day);
        if (from != null && day.isBefore(from)) return false;
        if (to != null && day.isAfter(to)) return false;
        return true;
      }).toList();
    }

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
