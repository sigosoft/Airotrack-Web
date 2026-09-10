import 'package:get/get.dart';
import '../models/dashboard_model.dart';
import 'home_controller.dart';
import 'vehicle_detail_controller.dart';

class DashboardController extends GetxController {
  final RxInt selectedMenuIndex = 0.obs;
  final RxInt selectedVehicleIndex = 0.obs;

  final RxBool isReportsExpanded = false.obs;
  final RxInt selectedReportSubIndex = 0.obs;
  final RxString reportStartDate = '28-08-2025 12:00 AM'.obs;
  final RxString reportEndDate = '28-08-2025 12:00 AM'.obs;

  late final HomeController homeController;

  @override
  void onInit() {
    super.onInit();
    homeController = Get.put(HomeController());

    ever(homeController.vehicles, (_) => _updateDashboardData());
    ever(homeController.totalCount, (_) => _updateDashboardData());
    ever(homeController.runningCount, (_) => _updateDashboardData());
    ever(homeController.stoppedCount, (_) => _updateDashboardData());
    ever(homeController.idleCount, (_) => _updateDashboardData());
    ever(homeController.inactiveCount, (_) => _updateDashboardData());
  }

  void _updateDashboardData() {
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

    List<VehicleItem> items = [];
    List<EngineHourDataPoint> dynamicEngineHours = [];
    List<TravelDistanceDataPoint> dynamicTravelDistance = [];

    for (int i = 0; i < homeController.vehicles.length; i++) {
      final v = homeController.vehicles[i];
      items.add(
        VehicleItem(
          registrationNumber: v.plateNumber,
          status: v.status,
          isSelected: i == selectedVehicleIndex.value,
        ),
      );

      if (i < 7) {
        final distNum =
            double.tryParse(v.todayKm.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;
        double hoursNum = 0.0;
        final dur = v.statusDuration.toLowerCase();
        if (dur.contains('h')) {
          final parts = dur.split('h');
          hoursNum =
              double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;
        } else {
          hoursNum =
              double.tryParse(dur.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }

        final label = v.plateNumber.length > 5
            ? v.plateNumber.substring(v.plateNumber.length - 4)
            : 'V${i + 1}';

        dynamicEngineHours.add(
          EngineHourDataPoint(date: label, hours: hoursNum.clamp(0.0, 24.0)),
        );
        dynamicTravelDistance.add(
          TravelDistanceDataPoint(date: label, distanceKm: distNum),
        );
      }
    }

    dashboardData.value = DashboardModel(
      userName: dashboardData.value.userName,
      summaryList: [
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
          title: 'In Active',
          count: inactive,
          colorHex: 0xFF0288D1,
          lightBgHex: 0xFFE1F5FE,
        ),
        VehicleStatusSummary(
          title: 'Expired',
          count: 0,
          colorHex: 0xFFE65100,
          lightBgHex: 0xFFFBE9E7,
        ),
        VehicleStatusSummary(
          title: 'No Data',
          count: 0,
          colorHex: 0xFF757575,
          lightBgHex: 0xFFF5F5F5,
        ),
      ],
      vehicleList: items.isNotEmpty ? items : dashboardData.value.vehicleList,
      engineHoursData: dynamicEngineHours.isNotEmpty
          ? dynamicEngineHours
          : dashboardData.value.engineHoursData,
      travelDistanceData: dynamicTravelDistance.isNotEmpty
          ? dynamicTravelDistance
          : dashboardData.value.travelDistanceData,
    );

    // Sync selected vehicle to VehicleDetailController
    if (homeController.vehicles.isNotEmpty) {
      final idx = selectedVehicleIndex.value < homeController.vehicles.length
          ? selectedVehicleIndex.value
          : 0;
      final selectedVeh = homeController.vehicles[idx];
      if (Get.isRegistered<VehicleDetailController>()) {
        Get.find<VehicleDetailController>().updateFromVehicle(selectedVeh);
      }
    }
  }

  void toggleReportsExpand() {
    isReportsExpanded.value = !isReportsExpanded.value;
  }

  void selectReportSub(int index) {
    selectedReportSubIndex.value = index;
    selectedMenuIndex.value = 2; // Reports menu
  }

  final Rx<DashboardModel> dashboardData = DashboardModel(
    userName: 'User',
    summaryList: [
      VehicleStatusSummary(
        title: 'All Vehicles',
        count: 0,
        colorHex: 0xFF0288D1,
        lightBgHex: 0xFFE1F5FE,
      ),
      VehicleStatusSummary(
        title: 'Running',
        count: 0,
        colorHex: 0xFF2E7D32,
        lightBgHex: 0xFFE8F5E9,
      ),
      VehicleStatusSummary(
        title: 'Stopped',
        count: 0,
        colorHex: 0xFFD32F2F,
        lightBgHex: 0xFFFFEBEE,
      ),
      VehicleStatusSummary(
        title: 'Idle',
        count: 0,
        colorHex: 0xFFF57C00,
        lightBgHex: 0xFFFFF8E1,
      ),
      VehicleStatusSummary(
        title: 'In Active',
        count: 0,
        colorHex: 0xFF0288D1,
        lightBgHex: 0xFFE1F5FE,
      ),
      VehicleStatusSummary(
        title: 'Expired',
        count: 0,
        colorHex: 0xFFE65100,
        lightBgHex: 0xFFFBE9E7,
      ),
      VehicleStatusSummary(
        title: 'No Data',
        count: 0,
        colorHex: 0xFF757575,
        lightBgHex: 0xFFF5F5F5,
      ),
    ],
    vehicleList: [],
    engineHoursData: [],
    travelDistanceData: [],
  ).obs;

  void selectMenu(int index) {
    selectedMenuIndex.value = index;
  }

  void selectVehicle(int index) {
    selectedVehicleIndex.value = index;
    _updateDashboardData();
  }
}
