import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/dashboard_model.dart';
import 'home_controller.dart';
import 'vehicle_detail_controller.dart';

class DashboardController extends GetxController {
  final RxInt selectedMenuIndex = 0.obs;
  final RxInt selectedVehicleIndex = 0.obs;
  final RxBool isLoading = false.obs;
  Timer? _dashboardAutoUpdateTimer;

  final RxBool isReportsExpanded = false.obs;
  final RxInt selectedReportSubIndex = 0.obs;
  static String _formatInitialReportDate(DateTime dt, {bool isStart = true}) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    if (isStart) {
      return '$day-$month-$year 12:00 AM';
    } else {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:$minute $period';
    }
  }

  late final RxString reportStartDate = _formatInitialReportDate(
    DateTime.now().subtract(const Duration(days: 7)),
    isStart: true,
  ).obs;
  late final RxString reportEndDate = _formatInitialReportDate(
    DateTime.now(),
    isStart: false,
  ).obs;

  final RxList<Map<String, dynamic>> ignitionReports =
      <Map<String, dynamic>>[].obs;
  final RxBool isIgnitionReportLoading = false.obs;

  final RxList<Map<String, dynamic>> stoppageReports =
      <Map<String, dynamic>>[].obs;
  final RxBool isStoppageReportLoading = false.obs;

  final RxList<Map<String, dynamic>> tripReports = <Map<String, dynamic>>[].obs;
  final RxBool isTripReportLoading = false.obs;

  final RxList<Map<String, dynamic>> dailyReports =
      <Map<String, dynamic>>[].obs;
  final RxBool isDailyReportLoading = false.obs;

  final RxList<Map<String, dynamic>> summaryReports =
      <Map<String, dynamic>>[].obs;
  final RxBool isSummaryReportLoading = false.obs;

  final RxList<Map<String, dynamic>> overSpeedReports =
      <Map<String, dynamic>>[].obs;
  final RxBool isOverSpeedReportLoading = false.obs;

  final RxList<Map<String, dynamic>> geofenceReports =
      <Map<String, dynamic>>[].obs;
  final RxBool isGeofenceReportLoading = false.obs;

  late final HomeController homeController;

  /// Fleet status from the dashboard API, one entry per status:
  /// {'key': running|idle|stopped|inactive|expired|nodata,
  ///  'title': String, 'count': int, 'color': int? (ARGB, from backend)}
  final RxList<Map<String, dynamic>> fleetStatus = <Map<String, dynamic>>[].obs;
  final RxInt fleetTotal = 0.obs;

  /// True once a dashboard API response has been read. Until then the
  /// Fleet Status chart shows a loader instead of any placeholder numbers.
  final RxBool fleetLoaded = false.obs;

  static const List<String> _fleetOrder = [
    'running',
    'idle',
    'stopped',
    'inactive',
    'expired',
    'nodata',
  ];

  /// Maps any backend status name to one of the keys above.
  static String? _fleetKey(String raw) {
    final s = raw.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (s.startsWith('run') || s == 'moving') return 'running';
    if (s.startsWith('idl')) return 'idle';
    if (s.startsWith('stop') || s == 'parked') return 'stopped';
    if (s.startsWith('inactive') || s == 'offline') return 'inactive';
    if (s.startsWith('expir')) return 'expired';
    if (s.startsWith('nodata') || s == 'nogps' || s == 'nosignal') {
      return 'nodata';
    }
    if (s.startsWith('total') || s.startsWith('all')) return 'total';
    return null;
  }

  /// Colour sent by the backend: '#RRGGBB', '#AARRGGBB', 'RRGGBB',
  /// '0xFFRRGGBB', 'rgb(r,g,b)', an int, or a basic colour name.
  static int? _parseBackendColor(dynamic v) {
    if (v == null) return null;
    if (v is int) return v <= 0xFFFFFF ? (0xFF000000 | v) : v;
    var s = v.toString().trim().toLowerCase();
    if (s.isEmpty || s == 'null') return null;
    final rgb = RegExp(
      r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',
    ).firstMatch(s);
    if (rgb != null) {
      final r = int.parse(rgb.group(1)!).clamp(0, 255);
      final g = int.parse(rgb.group(2)!).clamp(0, 255);
      final b = int.parse(rgb.group(3)!).clamp(0, 255);
      return 0xFF000000 | (r << 16) | (g << 8) | b;
    }
    const named = {
      'green': 0xFF2E7D32,
      'red': 0xFFD32F2F,
      'orange': 0xFFF57C00,
      'yellow': 0xFFFBC02D,
      'blue': 0xFF0288D1,
      'grey': 0xFF757575,
      'gray': 0xFF757575,
      'black': 0xFF212121,
      'purple': 0xFF7B1FA2,
    };
    if (named.containsKey(s)) return named[s];
    s = s.replaceFirst('#', '').replaceFirst('0x', '');
    if (!RegExp(r'^[0-9a-f]{6}([0-9a-f]{2})?$').hasMatch(s)) return null;
    final n = int.parse(s, radix: 16);
    return s.length == 6 ? (0xFF000000 | n) : n;
  }

  /// Reads the fleet status from the dashboard response. Supports a list of
  /// {status, count, color} items or a map of counts (+ optional colours).
  void _parseFleetStatus(Map data) {
    final raw =
        data['fleet_status'] ??
        data['fleetStatus'] ??
        data['statistics'] ??
        data['summary'];
    final byKey = <String, Map<String, dynamic>>{};
    int total = 0;

    int toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final label =
            (item['status'] ??
                    item['name'] ??
                    item['title'] ??
                    item['label'] ??
                    item['key'] ??
                    '')
                .toString();
        final key = _fleetKey(label);
        if (key == null) continue;
        final count = toInt(
          item['count'] ?? item['value'] ?? item['total'] ?? item['vehicles'],
        );
        if (key == 'total') {
          total = count;
          continue;
        }
        byKey[key] = {
          'key': key,
          'title': label,
          'count': count,
          'color': _parseBackendColor(
            item['color'] ??
                item['colour'] ??
                item['color_code'] ??
                item['colorCode'] ??
                item['hex'] ??
                item['bg_color'],
          ),
        };
      }
    } else if (raw is Map) {
      final colors = raw['colors'] ?? raw['colours'] ?? data['status_colors'];
      raw.forEach((k, v) {
        if (v is Map || v is List) return;
        final name = k.toString();
        if (name.toLowerCase().contains('color') ||
            name.toLowerCase().contains('colour')) {
          return;
        }
        final key = _fleetKey(name.replaceAll('_vehicles', ''));
        if (key == null) return;
        if (key == 'total') {
          total = toInt(v);
          return;
        }
        dynamic c;
        if (colors is Map) {
          c =
              colors[name] ??
              colors[name.replaceAll('_vehicles', '')] ??
              colors[key];
        }
        c ??=
            raw['${name.replaceAll('_vehicles', '')}_color'] ??
            raw['${key}_color'];
        byKey[key] = {
          'key': key,
          'title': null,
          'count': toInt(v),
          'color': _parseBackendColor(c),
        };
      });
    }

    fleetLoaded.value = true;
    if (byKey.isEmpty) {
      // The response has no per-status counts: show exactly that.
      fleetStatus.clear();
      fleetTotal.value = total;
      return;
    }
    fleetStatus.assignAll([
      for (final k in _fleetOrder)
        if (byKey[k] != null) byKey[k]!,
    ]);
    fleetTotal.value = total > 0
        ? total
        : byKey.values.fold<int>(0, (a, e) => a + (e['count'] as int));
  }

  @override
  void onInit() {
    super.onInit();
    homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    ever(homeController.vehicles, (_) {
      _updateDashboardData();
      fetchDashboardApi();
    });
    ever(homeController.totalCount, (_) => _updateDashboardData());
    ever(homeController.runningCount, (_) => _updateDashboardData());
    ever(homeController.stoppedCount, (_) => _updateDashboardData());
    ever(homeController.idleCount, (_) => _updateDashboardData());
    ever(homeController.inactiveCount, (_) => _updateDashboardData());

    _loadUserName();
    fetchDashboardApi();
    _startDashboardAutoUpdate();
  }

  void _startDashboardAutoUpdate() {
    _dashboardAutoUpdateTimer?.cancel();
    _dashboardAutoUpdateTimer = Timer.periodic(const Duration(seconds: 15), (
      _,
    ) {
      if (selectedMenuIndex.value == 0 && !isLoading.value) {
        fetchDashboardApi(isSilent: true);
      }
    });
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var savedName = prefs.getString('username');
      if (savedName != null &&
          savedName.isNotEmpty &&
          savedName.toLowerCase() != 'user') {
        updateUserName(savedName);
      } else {
        debugPrint('==================== [GET PROFILE API CALL (DASHBOARD)] ====================');
        debugPrint('URL: ${ApiConfig.baseUrl}${ApiEndPoints.profile}');
        final response = await DioClient().get(ApiEndPoints.profile);
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Data: ${response.data}');
        debugPrint('============================================================================');
        if (response.data != null) {
          final res = response.data;
          String? name;
          if (res is Map) {
            final data = res['data'] ?? res;
            if (data is Map) {
              final user =
                  data['user'] ?? data['details'] ?? data['profile'] ?? data;
              if (user is Map) {
                name =
                    user['name']?.toString() ??
                    user['username']?.toString() ??
                    user['user_name']?.toString();
              }
            }
          }
          if (name != null && name.isNotEmpty && name != 'User') {
            await prefs.setString('username', name);
            updateUserName(name);
          }
        }
      }
    } catch (e) {
      debugPrint('==================== [GET PROFILE ERROR (DASHBOARD)] ====================');
      debugPrint('Error loading user name: $e');
      debugPrint('=========================================================================');
    }
  }

  void updateUserName(String name) {
    if (name.isEmpty || name == 'User') return;
    dashboardData.value = DashboardModel(
      userName: name,
      summaryList: dashboardData.value.summaryList,
      vehicleList: dashboardData.value.vehicleList,
      engineHoursData: dashboardData.value.engineHoursData,
      travelDistanceData: dashboardData.value.travelDistanceData,
    );
  }

  void _updateDashboardData({bool forceIndexSelection = false}) {
    final total =
        int.tryParse(homeController.totalCount.value) ??
        homeController.vehicles.length;
    final running =
        int.tryParse(homeController.runningCount.value) ??
        homeController.vehicles.where((v) => v.status == 'Running').length;
    final stopped =
        int.tryParse(homeController.stoppedCount.value) ??
        homeController.vehicles.where((v) => v.status == 'Stopped').length;
    final idle =
        int.tryParse(homeController.idleCount.value) ??
        homeController.vehicles.where((v) => v.status == 'Idle').length;
    final inactive =
        int.tryParse(homeController.inactiveCount.value) ??
        homeController.vehicles.where((v) => v.status == 'Inactive').length;
    // Expired count; the Home list may not send one, then inactive vehicles
    // are the expired ones (same rule the Fleet Status chart used).
    final expired = int.tryParse(homeController.expiredCount.value) ?? inactive;

    List<VehicleItem> items = [];

    for (int i = 0; i < homeController.vehicles.length; i++) {
      final v = homeController.vehicles[i];
      final reg = v.plateNumber.isNotEmpty ? v.plateNumber : v.deviceId;
      items.add(
        VehicleItem(
          registrationNumber: reg,
          status: v.status,
          isSelected: i == selectedVehicleIndex.value,
        ),
      );
    }

    dashboardData.value = DashboardModel(
      userName: dashboardData.value.userName,
      summaryList: _buildSummaryList(
        total: total,
        running: running,
        idle: idle,
        stopped: stopped,
        expired: expired,
        inactive: inactive,
        noData: 0,
      ),
      vehicleList: items.isNotEmpty ? items : dashboardData.value.vehicleList,
      engineHoursData: dashboardData.value.engineHoursData,
      travelDistanceData: dashboardData.value.travelDistanceData,
    );

    // Sync selected vehicle to VehicleDetailController
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      var selectedVeh = homeController.vehicles[idx];
      if (Get.isRegistered<VehicleDetailController>()) {
        final detailCtrl = Get.find<VehicleDetailController>();
        // FIX: a periodic refresh must keep the vehicle that is already open
        // on the detail page (matched by IMEI) instead of replacing it with
        // the vehicle at selectedVehicleIndex. Only an explicit selectVehicle()
        // on the dashboard switches the detail page to the indexed vehicle.
        if (!forceIndexSelection && detailCtrl.activeImei.isNotEmpty) {
          for (final v in homeController.vehicles) {
            if (v.deviceId == detailCtrl.activeImei) {
              selectedVeh = v;
              break;
            }
          }
        }
        detailCtrl.updateFromVehicle(selectedVeh);
      }
    }
  }

  /// Dashboard status cards, in this order:
  /// All Vehicles, Running, Stopped, Idle, Expired.
  /// "In Active" and "No Data" are hidden (kept here, not shown) - set
  /// [_hiddenStatusCards] to show them again.
  static const Set<String> _hiddenStatusCards = {'In Active', 'No Data'};

  static List<VehicleStatusSummary> _buildSummaryList({
    required int total,
    required int running,
    required int idle,
    required int stopped,
    required int expired,
    required int inactive,
    required int noData,
  }) {
    final all = [
      VehicleStatusSummary(
        title: 'All Vehicles',
        count: total,
        colorHex: 0xFF0288D1,
        lightBgHex: 0xFFE1F5FE,
      ),
      VehicleStatusSummary(
        title: 'Running',
        count: running,
        colorHex: 0xFF2E7D32,
        lightBgHex: 0xFFE8F5E9,
      ),
      VehicleStatusSummary(
        title: 'Stopped',
        count: stopped,
        colorHex: 0xFFD32F2F,
        lightBgHex: 0xFFFFEBEE,
      ),
      VehicleStatusSummary(
        title: 'Idle',
        count: idle,
        colorHex: 0xFFF57C00,
        lightBgHex: 0xFFFFF8E1,
      ),
      VehicleStatusSummary(
        title: 'Expired',
        count: expired,
        colorHex: 0xFFE65100,
        lightBgHex: 0xFFFBE9E7,
      ),
      VehicleStatusSummary(
        title: 'In Active',
        count: inactive,
        colorHex: 0xFF0288D1,
        lightBgHex: 0xFFE1F5FE,
      ),
      VehicleStatusSummary(
        title: 'No Data',
        count: noData,
        colorHex: 0xFF757575,
        lightBgHex: 0xFFF5F5F5,
      ),
    ];
    return all.where((c) => !_hiddenStatusCards.contains(c.title)).toList();
  }

  /// Rounds a chart maximum up to a clean number (e.g. 360.6 -> 400,
  /// 117 -> 120, 0 -> 10).
  static double _niceCeil(double v) {
    if (v <= 0) return 10;
    final mag = pow(10, (log(v) / ln10).floor()).toDouble();
    for (final step in [
      1.0,
      1.2,
      1.5,
      2.0,
      2.5,
      3.0,
      4.0,
      5.0,
      6.0,
      8.0,
      10.0,
    ]) {
      if (step * mag >= v) return step * mag;
    }
    return 10 * mag;
  }

  void toggleReportsExpand() {
    isReportsExpanded.value = !isReportsExpanded.value;
  }

  void selectReportSub(int index) {
    selectedReportSubIndex.value = index;
    selectedMenuIndex.value = 2; // Reports menu
    if (index == 0) {
      fetchIgnitionReports();
    } else if (index == 1) {
      fetchStoppageReports();
    } else if (index == 2) {
      fetchTripReports();
    } else if (index == 3) {
      fetchDailyReports();
    } else if (index == 4) {
      fetchSummaryReports();
    } else if (index == 5) {
      fetchOverSpeedReports();
    } else if (index == 6) {
      fetchGeofenceReports();
    }
  }

  static List<EngineHourDataPoint> _getInitialEngineHours() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return EngineHourDataPoint(
        date:
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
        hours: 0.0,
      );
    });
  }

  static List<TravelDistanceDataPoint> _getInitialTravelDistance() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return TravelDistanceDataPoint(
        date:
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
        distanceKm: 0.0,
        maxKm: 144.0,
      );
    });
  }

  final Rx<DashboardModel> dashboardData = DashboardModel(
    userName: 'User',
    summaryList: _buildSummaryList(
      total: 0,
      running: 0,
      idle: 0,
      stopped: 0,
      expired: 0,
      inactive: 0,
      noData: 0,
    ),
    vehicleList: [],
    engineHoursData: _getInitialEngineHours(),
    travelDistanceData: _getInitialTravelDistance(),
  ).obs;

  void selectMenu(int index) {
    selectedMenuIndex.value = index;
    if (index == 0) {
      fetchDashboardApi();
    }
  }

  void selectVehicle(int index) {
    selectedVehicleIndex.value = index;
    _updateDashboardData(forceIndexSelection: true);
    fetchDashboardApi();
  }

  /// Call GET /dashboard API with query parameters (imei, from_date, to_date, days)
  Future<void> fetchDashboardApi({
    String? imei,
    String? fromDate,
    String? toDate,
    String? days,
    bool isSilent = false,
  }) async {
    try {
      if (!isSilent) isLoading.value = true;

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        final veh = homeController.vehicles[idx];
        selectedImei = veh.deviceId;
      }

      final now = DateTime.now();
      final defaultToDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final defaultFromDate =
          "${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}";

      final reqImei = selectedImei;
      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : (reportStartDate.value.isNotEmpty
                ? reportStartDate.value
                : defaultFromDate);
      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : (reportEndDate.value.isNotEmpty
                ? reportEndDate.value
                : defaultToDate);
      final reqDays = (days != null && days.isNotEmpty) ? days : '7';

      final response = await DioClient().get(
        ApiEndPoints.dashboard,
        queryParameters: {
          'imei': reqImei,
          'from_date': reqFromDate,
          'to_date': reqToDate,
          'days': reqDays,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        _parseAndSetDashboardData(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (!isSilent) isLoading.value = false;
    }
  }

  void _parseAndSetDashboardData(dynamic data) {
    if (data is! Map) return;

    final parsedName =
        data['user_name']?.toString() ??
        data['userName']?.toString() ??
        data['name']?.toString() ??
        (data['user'] is Map ? data['user']['name']?.toString() : null) ??
        (data['details'] is Map ? data['details']['name']?.toString() : null);

    final name =
        (parsedName != null &&
            parsedName.isNotEmpty &&
            parsedName.toLowerCase() != 'user')
        ? parsedName
        : dashboardData.value.userName;

    if (parsedName != null &&
        parsedName.isNotEmpty &&
        parsedName.toLowerCase() != 'user') {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('username', parsedName);
      });
    }

    // Fleet status (counts + backend colours) for the Fleet Status chart
    _parseFleetStatus(data);

    // Parse statistics / fleet_status
    final stats =
        data['fleet_status'] ?? data['statistics'] ?? data['summary'] ?? data;
    int total = 0,
        running = 0,
        stopped = 0,
        idle = 0,
        inactive = 0,
        expired = 0,
        noData = 0;
    bool expiredSent = false;

    if (stats is Map) {
      total =
          int.tryParse(
            stats['total_vehicles']?.toString() ??
                stats['total']?.toString() ??
                '',
          ) ??
          0;
      running =
          int.tryParse(
            stats['running_vehicles']?.toString() ??
                stats['running']?.toString() ??
                '',
          ) ??
          0;
      stopped =
          int.tryParse(
            stats['stopped_vehicles']?.toString() ??
                stats['stopped']?.toString() ??
                '',
          ) ??
          0;
      idle =
          int.tryParse(
            stats['idle_vehicles']?.toString() ??
                stats['idle']?.toString() ??
                '',
          ) ??
          0;
      inactive =
          int.tryParse(
            stats['inactive_vehicles']?.toString() ??
                stats['inactive']?.toString() ??
                '',
          ) ??
          0;
      expiredSent =
          stats['expired_vehicles'] != null || stats['expired'] != null;
      expired =
          int.tryParse(
            stats['expired_vehicles']?.toString() ??
                stats['expired']?.toString() ??
                '',
          ) ??
          0;
      noData =
          int.tryParse(
            stats['nodata_vehicles']?.toString() ??
                stats['no_data']?.toString() ??
                '',
          ) ??
          0;
    }

    // Engine hours
    List<EngineHourDataPoint> engineList = [];
    final rawEngine =
        data['engine_hours'] ??
        data['engine_hours_data'] ??
        data['engineHours'];
    if (rawEngine is List) {
      for (final item in rawEngine) {
        if (item is Map) {
          final label =
              item['date']?.toString() ??
              item['label']?.toString() ??
              item['day']?.toString() ??
              '';
          final hrs =
              double.tryParse(
                item['hours']?.toString() ?? item['value']?.toString() ?? '',
              ) ??
              0.0;
          engineList.add(EngineHourDataPoint(date: label, hours: hrs));
        }
      }
    }

    // Travel distance
    List<TravelDistanceDataPoint> distanceList = [];
    final rawDist =
        data['travel_distance'] ??
        data['travel_distance_data'] ??
        data['travelDistance'];
    if (rawDist is List) {
      for (final item in rawDist) {
        if (item is Map) {
          final label =
              item['date']?.toString() ??
              item['label']?.toString() ??
              item['day']?.toString() ??
              '';
          final km =
              double.tryParse(
                item['distance_km']?.toString() ??
                    item['distance']?.toString() ??
                    item['distanceKm']?.toString() ??
                    item['value']?.toString() ??
                    '',
              ) ??
              0.0;
          distanceList.add(
            TravelDistanceDataPoint(date: label, distanceKm: km, maxKm: 0),
          );
        }
      }
      // Chart scale from the response: the backend's maxKm if it sends one,
      // otherwise the largest day rounded up (was a fixed 144 km, which cut
      // off days like 360 km).
      double scale = 0;
      for (final item in rawDist) {
        if (item is Map) {
          final m = double.tryParse(item['maxKm']?.toString() ?? '');
          if (m != null && m > scale) scale = m;
        }
      }
      if (scale <= 0) {
        final top = distanceList.fold<double>(
          0,
          (a, p) => p.distanceKm > a ? p.distanceKm : a,
        );
        scale = _niceCeil(top);
      }
      distanceList = [
        for (final p in distanceList)
          TravelDistanceDataPoint(
            date: p.date,
            distanceKm: p.distanceKm,
            maxKm: scale,
          ),
      ];
    }

    // Vehicles list
    List<VehicleItem> vehicleItems = [];
    final rawVehicles =
        data['vehicles'] ?? data['vehicle_list'] ?? data['vehicles_data'];
    if (rawVehicles is List) {
      for (int i = 0; i < rawVehicles.length; i++) {
        final item = rawVehicles[i];
        if (item is Map) {
          final reg =
              item['vehicle_number']?.toString() ??
              item['vehicle_no']?.toString() ??
              item['plate_number']?.toString() ??
              item['registration_number']?.toString() ??
              item['plateNumber']?.toString() ??
              item['name']?.toString() ??
              item['imei']?.toString() ??
              '';
          final st =
              item['status']?.toString() ??
              item['current_status']?.toString() ??
              'Running';
          vehicleItems.add(
            VehicleItem(
              registrationNumber: reg,
              status: st,
              isSelected: i == selectedVehicleIndex.value,
            ),
          );
        }
      }
    }

    // Fallback if vehicleItems is empty
    if (vehicleItems.isEmpty && homeController.vehicles.isNotEmpty) {
      for (int i = 0; i < homeController.vehicles.length; i++) {
        final v = homeController.vehicles[i];
        final name = v.plateNumber.isNotEmpty ? v.plateNumber : v.deviceId;
        vehicleItems.add(
          VehicleItem(
            registrationNumber: name,
            status: v.status,
            isSelected: i == selectedVehicleIndex.value,
          ),
        );
      }
    }

    // Match selected vehicle if provided
    if (data['selected_vehicle'] is Map) {
      final sel = data['selected_vehicle'] as Map;
      final selImei = sel['imei']?.toString();
      final selVehNo =
          sel['vehicle_number']?.toString() ?? sel['name']?.toString();
      if (rawVehicles is List) {
        for (int i = 0; i < rawVehicles.length; i++) {
          final vMap = rawVehicles[i];
          if (vMap is Map) {
            if ((selImei != null && vMap['imei']?.toString() == selImei) ||
                (selVehNo != null &&
                    (vMap['vehicle_number']?.toString() == selVehNo ||
                        vMap['plate_number']?.toString() == selVehNo))) {
              selectedVehicleIndex.value = i;
              break;
            }
          }
        }
      }
    }

    dashboardData.value = DashboardModel(
      userName: name,
      summaryList: _buildSummaryList(
        total: total > 0
            ? total
            : (int.tryParse(homeController.totalCount.value) ??
                  homeController.vehicles.length),
        running: running > 0
            ? running
            : (int.tryParse(homeController.runningCount.value) ??
                  homeController.vehicles
                      .where((v) => v.status == 'Running')
                      .length),
        idle: idle > 0
            ? idle
            : (int.tryParse(homeController.idleCount.value) ??
                  homeController.vehicles
                      .where((v) => v.status == 'Idle')
                      .length),
        stopped: stopped > 0
            ? stopped
            : (int.tryParse(homeController.stoppedCount.value) ??
                  homeController.vehicles
                      .where((v) => v.status == 'Stopped')
                      .length),
        expired: expiredSent
            ? expired
            : (inactive > 0
                  ? inactive
                  : (int.tryParse(homeController.expiredCount.value) ??
                        int.tryParse(homeController.inactiveCount.value) ??
                        0)),
        inactive: inactive,
        noData: noData,
      ),
      vehicleList: vehicleItems.isNotEmpty
          ? vehicleItems
          : dashboardData.value.vehicleList,
      engineHoursData: engineList.isNotEmpty
          ? engineList
          : dashboardData.value.engineHoursData,
      travelDistanceData: distanceList.isNotEmpty
          ? distanceList
          : dashboardData.value.travelDistanceData,
    );
  }

  /// Call GET /reports/ignition API to fetch ignition report details
  Future<void> fetchIgnitionReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isIgnitionReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      final response = await DioClient().get(
        ApiEndPoints.ignitionReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          bool foundListKey = false;
          if (resData['items'] is List) {
            rawList = resData['items'];
            foundListKey = true;
          } else if (resData['data'] is List) {
            rawList = resData['data'];
            foundListKey = true;
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
            foundListKey = true;
          } else if (resData['ignition_reports'] is List) {
            rawList = resData['ignition_reports'];
            foundListKey = true;
          } else if (resData['list'] is List) {
            rawList = resData['list'];
            foundListKey = true;
          }

          if (!foundListKey && rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseIgnitionReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseIgnitionReportItem(
                Map<String, dynamic>.from(item),
                parentMap,
              ),
            );
          }
        }
        ignitionReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching ignition reports: $e');
    } finally {
      isIgnitionReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseIgnitionReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    String vehicle = defaultVehicleName;
    if (veh is Map) {
      vehicle =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicle = veh.toString();
    } else {
      vehicle =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    final timestamp =
        raw['timestamp']?.toString() ??
        raw['created_at']?.toString() ??
        raw['device_time']?.toString() ??
        raw['time']?.toString() ??
        raw['date']?.toString() ??
        'N/A';

    final location =
        raw['location']?.toString() ??
        raw['address']?.toString() ??
        raw['location_name']?.toString() ??
        'N/A';

    bool isIgnitionOn = false;
    final ign =
        raw['isIgnitionOn'] ??
        raw['is_ignition_on'] ??
        raw['ignition'] ??
        raw['status'];
    if (ign is bool) {
      isIgnitionOn = ign;
    } else if (ign is num) {
      isIgnitionOn = ign == 1;
    } else if (ign is String) {
      final lower = ign.toLowerCase();
      isIgnitionOn =
          lower == 'true' ||
          lower == '1' ||
          lower == 'on' ||
          lower == 'ignition on';
    }

    return {
      ...raw,
      'vehicle': vehicle,
      'timestamp': timestamp,
      'location': location,
      'isIgnitionOn': isIgnitionOn,
    };
  }

  /// Call GET /reports/stoppag API to fetch stoppage report details
  Future<void> fetchStoppageReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isStoppageReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      dynamic response;
      try {
        response = await DioClient().get(
          ApiEndPoints.stoppageReport,
          queryParameters: queryParams,
        );
      } catch (e) {
        // Fallback retry with alternate path if stoppageReport returned 404
        debugPrint(
          'Primary stoppage report endpoint failed, retrying with fallback endpoint...',
        );
        response = await DioClient().get(
          "reports/stoppage",
          queryParameters: queryParams,
        );
      }

      if (response != null && response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          bool foundListKey = false;
          if (resData['items'] is List) {
            rawList = resData['items'];
            foundListKey = true;
          } else if (resData['data'] is List) {
            rawList = resData['data'];
            foundListKey = true;
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
            foundListKey = true;
          } else if (resData['stoppage_reports'] is List) {
            rawList = resData['stoppage_reports'];
            foundListKey = true;
          } else if (resData['stoppages'] is List) {
            rawList = resData['stoppages'];
            foundListKey = true;
          } else if (resData['list'] is List) {
            rawList = resData['list'];
            foundListKey = true;
          }

          if (!foundListKey && rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseStoppageReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseStoppageReportItem(
                Map<String, dynamic>.from(item),
                parentMap,
              ),
            );
          }
        }
        stoppageReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching stoppage reports: $e');
    } finally {
      isStoppageReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseStoppageReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    String vehicle = defaultVehicleName;
    if (veh is Map) {
      vehicle =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicle = veh.toString();
    } else {
      vehicle =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    final duration =
        raw['duration']?.toString() ??
        raw['stoppage_duration']?.toString() ??
        raw['time_duration']?.toString() ??
        '00h 00m';

    final startTime =
        raw['startTime']?.toString() ??
        raw['start_time']?.toString() ??
        raw['created_at']?.toString() ??
        raw['from_time']?.toString() ??
        'N/A';

    final endTime =
        raw['endTime']?.toString() ??
        raw['end_time']?.toString() ??
        raw['to_time']?.toString() ??
        raw['updated_at']?.toString() ??
        'N/A';

    final location =
        raw['location']?.toString() ??
        raw['address']?.toString() ??
        raw['location_name']?.toString() ??
        'N/A';

    return {
      ...raw,
      'vehicle': vehicle,
      'duration': duration,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'timestamp': startTime != 'N/A' ? startTime : endTime,
    };
  }

  /// Call GET /reports/trip API to fetch trip report details
  Future<void> fetchTripReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isTripReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      final response = await DioClient().get(
        ApiEndPoints.tripReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          bool foundListKey = false;
          if (resData['items'] is List) {
            rawList = resData['items'];
            foundListKey = true;
          } else if (resData['data'] is List) {
            rawList = resData['data'];
            foundListKey = true;
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
            foundListKey = true;
          } else if (resData['trip_reports'] is List) {
            rawList = resData['trip_reports'];
            foundListKey = true;
          } else if (resData['trips'] is List) {
            rawList = resData['trips'];
            foundListKey = true;
          } else if (resData['list'] is List) {
            rawList = resData['list'];
            foundListKey = true;
          }

          if (!foundListKey && rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseTripReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseTripReportItem(Map<String, dynamic>.from(item), parentMap),
            );
          }
        }
        tripReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching trip reports: $e');
    } finally {
      isTripReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseTripReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    String vehicle = defaultVehicleName;
    if (veh is Map) {
      vehicle =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicle = veh.toString();
    } else {
      vehicle =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    final duration =
        raw['duration']?.toString() ??
        raw['trip_duration']?.toString() ??
        raw['time_duration']?.toString() ??
        '00h 00m';

    final distance =
        raw['distance']?.toString() ??
        raw['trip_distance']?.toString() ??
        raw['distance_km']?.toString() ??
        '0.0 Km';

    final startTime =
        raw['startTime']?.toString() ??
        raw['start_time']?.toString() ??
        raw['created_at']?.toString() ??
        raw['from_time']?.toString() ??
        'N/A';

    final endTime =
        raw['endTime']?.toString() ??
        raw['end_time']?.toString() ??
        raw['to_time']?.toString() ??
        raw['updated_at']?.toString() ??
        'N/A';

    final startLocation =
        raw['startLocation']?.toString() ??
        raw['start_location']?.toString() ??
        raw['start_address']?.toString() ??
        raw['location']?.toString() ??
        'N/A';

    final endLocation =
        raw['endLocation']?.toString() ??
        raw['end_location']?.toString() ??
        raw['end_address']?.toString() ??
        raw['location']?.toString() ??
        'N/A';

    return {
      ...raw,
      'vehicle': vehicle,
      'duration': duration,
      'distance': distance,
      'startTime': startTime,
      'endTime': endTime,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'timestamp': startTime != 'N/A' ? startTime : endTime,
    };
  }

  /// Call GET /reports/daily API to fetch daily report details
  Future<void> fetchDailyReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isDailyReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      final response = await DioClient().get(
        ApiEndPoints.dailyReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          bool foundListKey = false;
          if (resData['items'] is List) {
            rawList = resData['items'];
            foundListKey = true;
          } else if (resData['data'] is List) {
            rawList = resData['data'];
            foundListKey = true;
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
            foundListKey = true;
          } else if (resData['daily_reports'] is List) {
            rawList = resData['daily_reports'];
            foundListKey = true;
          } else if (resData['daily'] is List) {
            rawList = resData['daily'];
            foundListKey = true;
          } else if (resData['list'] is List) {
            rawList = resData['list'];
            foundListKey = true;
          }

          if (!foundListKey && rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseDailyReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseDailyReportItem(Map<String, dynamic>.from(item), parentMap),
            );
          }
        }
        dailyReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching daily reports: $e');
    } finally {
      isDailyReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseDailyReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    final Map<String, dynamic> summary = raw['summary'] is Map<String, dynamic>
        ? raw['summary']
        : (raw['summary'] is Map
              ? Map<String, dynamic>.from(raw['summary'])
              : raw);

    String vehicleName = defaultVehicleName;
    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    if (veh is Map) {
      vehicleName =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicleName = veh.toString();
    } else {
      vehicleName =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    // Distance
    final rawDist =
        summary['route_length_km'] ??
        raw['route_length_km'] ??
        summary['distance'] ??
        raw['distance'] ??
        summary['total_distance'] ??
        raw['total_distance'] ??
        summary['distance_km'] ??
        raw['distance_km'] ??
        '0.0';
    String distanceStr = rawDist.toString();
    if (!distanceStr.toLowerCase().contains('km')) {
      distanceStr = '$distanceStr Km';
    }

    // Timestamps
    final dateRange = raw['date_range'] is Map
        ? Map<String, dynamic>.from(raw['date_range'])
        : (parentData?['date_range'] is Map
              ? Map<String, dynamic>.from(parentData!['date_range'])
              : null);

    final rawStart =
        summary['start_time'] ??
        raw['startTime'] ??
        raw['start_time'] ??
        raw['created_at'] ??
        raw['from_time'] ??
        dateRange?['from_date'] ??
        'N/A';
    String startTime = rawStart.toString();

    final rawEnd =
        summary['end_time'] ??
        raw['endTime'] ??
        raw['end_time'] ??
        raw['to_time'] ??
        raw['updated_at'] ??
        dateRange?['to_date'] ??
        'N/A';
    String endTime = rawEnd.toString();

    // Engine hour
    final rawEng =
        summary['engine_hours'] ??
        raw['engine_hours'] ??
        summary['engineHour'] ??
        raw['engineHour'] ??
        summary['engine_hour'] ??
        raw['engine_hour'] ??
        '00:00:00';
    String engineHourStr = rawEng.toString();
    if (!engineHourStr.toLowerCase().contains('h')) {
      engineHourStr = '${engineHourStr}h';
    }

    // Running (move_duration)
    final rawRun =
        summary['move_duration'] ??
        raw['move_duration'] ??
        summary['running'] ??
        raw['running'] ??
        summary['running_time'] ??
        raw['running_duration'] ??
        '00:00:00';
    String runningStr = rawRun.toString();
    if (!runningStr.toLowerCase().contains('h')) {
      runningStr = '${runningStr}h';
    }

    // Stopped (stop_duration)
    final rawStop =
        summary['stop_duration'] ??
        raw['stop_duration'] ??
        summary['stoped'] ??
        raw['stoped'] ??
        summary['stopped'] ??
        raw['stopped'] ??
        summary['stopped_time'] ??
        raw['stopped_time'] ??
        '00:00:00';
    String stopedStr = rawStop.toString();
    if (!stopedStr.toLowerCase().contains('h')) {
      stopedStr = '${stopedStr}h';
    }

    // Idle (idle_duration)
    final rawIdle =
        summary['idle_duration'] ??
        raw['idle_duration'] ??
        summary['idle'] ??
        raw['idle'] ??
        summary['idle_time'] ??
        raw['idle_duration'] ??
        '00:00:00';
    String idleStr = rawIdle.toString();
    if (!idleStr.toLowerCase().contains('h')) {
      idleStr = '${idleStr}h';
    }

    // Locations
    final startLocRaw =
        summary['start_address'] ??
        raw['start_address'] ??
        summary['startLocation'] ??
        raw['startLocation'] ??
        summary['start_location'] ??
        raw['start_location'] ??
        summary['location'] ??
        raw['location'];
    final startLocation =
        (startLocRaw != null && startLocRaw.toString().trim().isNotEmpty)
        ? startLocRaw.toString()
        : 'N/A';

    final endLocRaw =
        summary['end_address'] ??
        raw['end_address'] ??
        summary['endLocation'] ??
        raw['endLocation'] ??
        summary['end_location'] ??
        raw['end_location'] ??
        summary['location'] ??
        raw['location'];
    final endLocation =
        (endLocRaw != null && endLocRaw.toString().trim().isNotEmpty)
        ? endLocRaw.toString()
        : 'N/A';

    // Odometers
    final rawStartOdo =
        summary['start_odo'] ??
        summary['odometer_km'] ??
        raw['startOdo'] ??
        raw['start_odo'] ??
        raw['start_odometer'] ??
        '0';
    String startOdoStr = rawStartOdo.toString();
    if (!startOdoStr.toLowerCase().contains('km')) {
      startOdoStr = '${startOdoStr}KM';
    }

    final rawEndOdo =
        summary['end_odo'] ??
        raw['endOdo'] ??
        raw['end_odo'] ??
        raw['end_odometer'] ??
        summary['odometer_km'] ??
        '0';
    String endOdoStr = rawEndOdo.toString();
    if (!endOdoStr.toLowerCase().contains('km')) {
      endOdoStr = '${endOdoStr}KM';
    }

    // Speed
    final rawAvgSpeed =
        summary['average_speed'] ??
        raw['average_speed'] ??
        summary['avgSpeed'] ??
        raw['avgSpeed'] ??
        summary['avg_speed'] ??
        raw['avg_speed'] ??
        '0';
    String avgSpeedStr = rawAvgSpeed.toString();
    if (!avgSpeedStr.toLowerCase().contains('km')) {
      avgSpeedStr = '$avgSpeedStr kmph';
    }

    final rawMaxSpeed =
        summary['top_speed'] ??
        raw['top_speed'] ??
        summary['maxSpeed'] ??
        raw['maxSpeed'] ??
        summary['max_speed'] ??
        raw['max_speed'] ??
        '0';
    String maxSpeedStr = rawMaxSpeed.toString();
    if (!maxSpeedStr.toLowerCase().contains('km')) {
      maxSpeedStr = '$maxSpeedStr kmph';
    }

    return {
      ...raw,
      'vehicle': vehicleName,
      'distance': distanceStr,
      'startTime': startTime,
      'endTime': endTime,
      'engineHour': engineHourStr,
      'running': runningStr,
      'stoped': stopedStr,
      'idle': idleStr,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startOdo': startOdoStr,
      'endOdo': endOdoStr,
      'avgSpeed': avgSpeedStr,
      'maxSpeed': maxSpeedStr,
    };
  }

  /// Call GET /reports/summary API to fetch summary report details
  Future<void> fetchSummaryReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isSummaryReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      final response = await DioClient().get(
        ApiEndPoints.summaryReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          if (resData['items'] is List) {
            rawList = resData['items'];
          } else if (resData['data'] is List) {
            rawList = resData['data'];
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
          } else if (resData['summary_reports'] is List) {
            rawList = resData['summary_reports'];
          } else if (resData['summary'] is List) {
            rawList = resData['summary'];
          } else if (resData['list'] is List) {
            rawList = resData['list'];
          }

          if (rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseSummaryReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseSummaryReportItem(
                Map<String, dynamic>.from(item),
                parentMap,
              ),
            );
          }
        }
        summaryReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching summary reports: $e');
    } finally {
      isSummaryReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseSummaryReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    // Extract summary sub-map if present
    final Map<String, dynamic> summary = raw['summary'] is Map<String, dynamic>
        ? raw['summary']
        : (raw['summary'] is Map
              ? Map<String, dynamic>.from(raw['summary'])
              : raw);

    // Extract vehicle info if vehicle is a map or string
    String vehicleName = defaultVehicleName;
    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    if (veh is Map) {
      vehicleName =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicleName = veh.toString();
    } else {
      vehicleName =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    // Distance
    final rawDist =
        summary['route_length_km'] ??
        raw['route_length_km'] ??
        summary['distance'] ??
        raw['distance'] ??
        summary['total_distance'] ??
        raw['total_distance'] ??
        summary['distance_km'] ??
        raw['distance_km'] ??
        '0';
    String distanceStr = rawDist.toString();
    if (!distanceStr.toLowerCase().contains('km')) {
      distanceStr = '$distanceStr Km';
    }

    // Engine hour
    final rawEng =
        summary['engine_hours'] ??
        raw['engine_hours'] ??
        summary['engineHour'] ??
        raw['engineHour'] ??
        summary['engine_hour'] ??
        raw['engine_hour'] ??
        '00:00:00';
    String engineHourStr = rawEng.toString();
    if (!engineHourStr.toLowerCase().contains('h')) {
      engineHourStr = '${engineHourStr}h';
    }

    // Running (move_duration)
    final rawRun =
        summary['move_duration'] ??
        raw['move_duration'] ??
        summary['running'] ??
        raw['running'] ??
        summary['running_time'] ??
        raw['running_time'] ??
        '00:00:00';
    String runningStr = rawRun.toString();
    if (!runningStr.toLowerCase().contains('h')) {
      runningStr = '${runningStr}h';
    }

    // Stopped (stop_duration)
    final rawStop =
        summary['stop_duration'] ??
        raw['stop_duration'] ??
        summary['stoped'] ??
        raw['stoped'] ??
        summary['stopped'] ??
        raw['stopped'] ??
        summary['stopped_time'] ??
        raw['stopped_time'] ??
        '00:00:00';
    String stopedStr = rawStop.toString();
    if (!stopedStr.toLowerCase().contains('h')) {
      stopedStr = '${stopedStr}h';
    }

    // Idle (idle_duration)
    final rawIdle =
        summary['idle_duration'] ??
        raw['idle_duration'] ??
        summary['idle'] ??
        raw['idle'] ??
        summary['idle_time'] ??
        raw['idle_time'] ??
        '00:00:00';
    String idleStr = rawIdle.toString();
    if (!idleStr.toLowerCase().contains('h')) {
      idleStr = '${idleStr}h';
    }

    // Locations
    final startLocRaw =
        summary['start_address'] ??
        raw['start_address'] ??
        summary['startLocation'] ??
        raw['startLocation'] ??
        summary['start_location'] ??
        raw['start_location'] ??
        summary['location'] ??
        raw['location'];
    final startLocation =
        (startLocRaw != null && startLocRaw.toString().trim().isNotEmpty)
        ? startLocRaw.toString()
        : 'N/A';

    final endLocRaw =
        summary['end_address'] ??
        raw['end_address'] ??
        summary['endLocation'] ??
        raw['endLocation'] ??
        summary['end_location'] ??
        raw['end_location'] ??
        summary['location'] ??
        raw['location'];
    final endLocation =
        (endLocRaw != null && endLocRaw.toString().trim().isNotEmpty)
        ? endLocRaw.toString()
        : 'N/A';

    // Odometers
    final rawStartOdo =
        summary['odometer_km'] ??
        summary['start_odo'] ??
        raw['start_odo'] ??
        summary['startOdo'] ??
        raw['startOdo'] ??
        summary['start_odometer'] ??
        raw['start_odometer'] ??
        '0';
    String startOdoStr = rawStartOdo.toString();
    if (!startOdoStr.toLowerCase().contains('km')) {
      startOdoStr = '${startOdoStr}KM';
    }

    final rawEndOdo =
        summary['end_odo'] ??
        raw['end_odo'] ??
        summary['endOdo'] ??
        raw['endOdo'] ??
        summary['end_odometer'] ??
        raw['end_odometer'] ??
        summary['odometer_km'] ??
        '0';
    String endOdoStr = rawEndOdo.toString();
    if (!endOdoStr.toLowerCase().contains('km')) {
      endOdoStr = '${endOdoStr}KM';
    }

    // Speed
    final rawAvgSpeed =
        summary['average_speed'] ??
        raw['average_speed'] ??
        summary['avgSpeed'] ??
        raw['avgSpeed'] ??
        summary['avg_speed'] ??
        raw['avg_speed'] ??
        '0';
    String avgSpeedStr = rawAvgSpeed.toString();
    if (!avgSpeedStr.toLowerCase().contains('km')) {
      avgSpeedStr = '$avgSpeedStr kmph';
    }

    final rawMaxSpeed =
        summary['top_speed'] ??
        raw['top_speed'] ??
        summary['maxSpeed'] ??
        raw['maxSpeed'] ??
        summary['max_speed'] ??
        raw['max_speed'] ??
        '0';
    String maxSpeedStr = rawMaxSpeed.toString();
    if (!maxSpeedStr.toLowerCase().contains('km')) {
      maxSpeedStr = '$maxSpeedStr kmph';
    }

    return {
      ...raw,
      'vehicle': vehicleName,
      'distance': distanceStr,
      'engineHour': engineHourStr,
      'running': runningStr,
      'stoped': stopedStr,
      'idle': idleStr,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startOdo': startOdoStr,
      'endOdo': endOdoStr,
      'avgSpeed': avgSpeedStr,
      'maxSpeed': maxSpeedStr,
    };
  }

  /// Call GET /reports/overspeed API to fetch overspeed report details
  Future<void> fetchOverSpeedReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isOverSpeedReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      final response = await DioClient().get(
        ApiEndPoints.overspeedReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          bool foundListKey = false;
          if (resData['items'] is List) {
            rawList = resData['items'];
            foundListKey = true;
          } else if (resData['data'] is List) {
            rawList = resData['data'];
            foundListKey = true;
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
            foundListKey = true;
          } else if (resData['overspeed_reports'] is List) {
            rawList = resData['overspeed_reports'];
            foundListKey = true;
          } else if (resData['overspeed'] is List) {
            rawList = resData['overspeed'];
            foundListKey = true;
          } else if (resData['list'] is List) {
            rawList = resData['list'];
            foundListKey = true;
          }

          if (!foundListKey && rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseOverSpeedReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseOverSpeedReportItem(
                Map<String, dynamic>.from(item),
                parentMap,
              ),
            );
          }
        }
        overSpeedReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching overspeed reports: $e');
    } finally {
      isOverSpeedReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseOverSpeedReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    String vehicleName = defaultVehicleName;
    if (veh is Map) {
      vehicleName =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicleName = veh.toString();
    } else {
      vehicleName =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    final rawSpeed =
        raw['speed'] ??
        raw['top_speed'] ??
        raw['max_speed'] ??
        raw['overspeed'] ??
        raw['speed_kmph'] ??
        '0';
    String speedStr = rawSpeed.toString();
    if (!speedStr.toLowerCase().contains('km')) {
      speedStr = '$speedStr kmph';
    }

    final dateRange = raw['date_range'] is Map
        ? Map<String, dynamic>.from(raw['date_range'])
        : (parentData?['date_range'] is Map
              ? Map<String, dynamic>.from(parentData!['date_range'])
              : null);

    final rawTime =
        raw['time'] ??
        raw['timestamp'] ??
        raw['created_at'] ??
        raw['device_time'] ??
        raw['start_time'] ??
        dateRange?['from_date'] ??
        'N/A';
    String timeStr = rawTime.toString();

    final locRaw =
        raw['location'] ??
        raw['address'] ??
        raw['start_address'] ??
        raw['location_name'];
    String locationStr = (locRaw != null && locRaw.toString().trim().isNotEmpty)
        ? locRaw.toString()
        : 'N/A';

    return {
      ...raw,
      'vehicle': vehicleName,
      'speed': speedStr,
      'time': timeStr,
      'location': locationStr,
    };
  }

  /// Call GET /reports/geofence API to fetch geofence report details
  Future<void> fetchGeofenceReports({
    String? imei,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      isGeofenceReportLoading.value = true;

      Map<String, dynamic> queryParams = {'page': page};

      String selectedImei = imei ?? '';
      if (selectedImei.isEmpty && homeController.vehicles.isNotEmpty) {
        final idx = selectedVehicleIndex.value < homeController.vehicles.length
            ? selectedVehicleIndex.value
            : 0;
        selectedImei = homeController.vehicles[idx].deviceId;
      }
      if (selectedImei.isNotEmpty) {
        queryParams['imei'] = selectedImei;
      }

      final reqFromDate = (fromDate != null && fromDate.isNotEmpty)
          ? fromDate
          : reportStartDate.value;
      if (reqFromDate.isNotEmpty) {
        queryParams['from_date'] = reqFromDate;
      }

      final reqToDate = (toDate != null && toDate.isNotEmpty)
          ? toDate
          : reportEndDate.value;
      if (reqToDate.isNotEmpty) {
        queryParams['to_date'] = reqToDate;
      }

      final response = await DioClient().get(
        ApiEndPoints.geofenceReport,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final resData =
            response.data['data'] ?? response.data['reports'] ?? response.data;
        List rawList = [];
        Map<String, dynamic>? parentMap;

        if (resData is List) {
          rawList = resData;
        } else if (resData is Map) {
          parentMap = Map<String, dynamic>.from(resData);
          bool foundListKey = false;
          if (resData['items'] is List) {
            rawList = resData['items'];
            foundListKey = true;
          } else if (resData['data'] is List) {
            rawList = resData['data'];
            foundListKey = true;
          } else if (resData['reports'] is List) {
            rawList = resData['reports'];
            foundListKey = true;
          } else if (resData['geofence_reports'] is List) {
            rawList = resData['geofence_reports'];
            foundListKey = true;
          } else if (resData['geofences'] is List) {
            rawList = resData['geofences'];
            foundListKey = true;
          } else if (resData['list'] is List) {
            rawList = resData['list'];
            foundListKey = true;
          }

          if (!foundListKey && rawList.isEmpty) {
            rawList = [resData];
          }
        }

        List<Map<String, dynamic>> parsedList = [];
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedList.add(_parseGeofenceReportItem(item, parentMap));
          } else if (item is Map) {
            parsedList.add(
              _parseGeofenceReportItem(
                Map<String, dynamic>.from(item),
                parentMap,
              ),
            );
          }
        }
        geofenceReports.value = parsedList;
      }
    } catch (e) {
      debugPrint('Error fetching geofence reports: $e');
    } finally {
      isGeofenceReportLoading.value = false;
    }
  }

  Map<String, dynamic> _parseGeofenceReportItem(
    Map<String, dynamic> raw, [
    Map<String, dynamic>? parentData,
  ]) {
    String defaultVehicleName = 'N/A';
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      defaultVehicleName = homeController.vehicles[idx].plateNumber;
    }

    final veh = raw['vehicle'] ?? parentData?['vehicle'];
    String vehicleName = defaultVehicleName;
    if (veh is Map) {
      vehicleName =
          veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['name']?.toString() ??
          veh['registration_number']?.toString() ??
          veh['imei']?.toString() ??
          defaultVehicleName;
    } else if (veh != null && veh.toString().trim().isNotEmpty) {
      vehicleName = veh.toString();
    } else {
      vehicleName =
          raw['vehicle_name']?.toString() ??
          raw['plate_number']?.toString() ??
          raw['registration_number']?.toString() ??
          raw['device_id']?.toString() ??
          raw['imei']?.toString() ??
          parentData?['vehicle_name']?.toString() ??
          parentData?['plate_number']?.toString() ??
          parentData?['registration_number']?.toString() ??
          parentData?['device_id']?.toString() ??
          parentData?['imei']?.toString() ??
          defaultVehicleName;
    }

    final rawEvent =
        raw['event'] ??
        raw['event_type'] ??
        raw['action'] ??
        raw['status'] ??
        raw['geofence_event'] ??
        'Geofence Event';
    String eventStr = rawEvent.toString();

    bool isEnter = true;
    final lowerEvent = eventStr.toLowerCase();
    if (raw['isEnter'] is bool) {
      isEnter = raw['isEnter'];
    } else if (raw['is_enter'] is bool) {
      isEnter = raw['is_enter'];
    } else if (lowerEvent.contains('exit') ||
        lowerEvent.contains('out') ||
        lowerEvent.contains('leave')) {
      isEnter = false;
    } else if (lowerEvent.contains('enter') ||
        lowerEvent.contains('in') ||
        lowerEvent.contains('inside')) {
      isEnter = true;
    }

    final dateRange = raw['date_range'] is Map
        ? Map<String, dynamic>.from(raw['date_range'])
        : (parentData?['date_range'] is Map
              ? Map<String, dynamic>.from(parentData!['date_range'])
              : null);

    final rawTime =
        raw['time'] ??
        raw['timestamp'] ??
        raw['created_at'] ??
        raw['device_time'] ??
        raw['event_time'] ??
        raw['start_time'] ??
        dateRange?['from_date'] ??
        'N/A';
    String timeStr = rawTime.toString();

    final locRaw =
        raw['location'] ??
        raw['address'] ??
        raw['geofence_name'] ??
        raw['name'] ??
        raw['start_address'] ??
        raw['location_name'];
    String locationStr = (locRaw != null && locRaw.toString().trim().isNotEmpty)
        ? locRaw.toString()
        : 'N/A';

    return {
      ...raw,
      'vehicle': vehicleName,
      'event': eventStr,
      'isEnter': isEnter,
      'time': timeStr,
      'location': locationStr,
    };
  }

  @override
  void onClose() {
    _dashboardAutoUpdateTimer?.cancel();
    super.onClose();
  }
}
