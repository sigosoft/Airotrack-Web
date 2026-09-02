import 'package:get/get.dart';
import '../models/dashboard_model.dart';

class DashboardController extends GetxController {
  final RxInt selectedMenuIndex = 0.obs;
  final RxInt selectedVehicleIndex = 0.obs;

  final Rx<DashboardModel> dashboardData = DashboardModel(
    userName: 'John Doe',
    summaryList: [
      VehicleStatusSummary(
        title: 'All Vehicles',
        count: 15,
        colorHex: 0xFF0288D1,
        lightBgHex: 0xFFE1F5FE,
      ),
      VehicleStatusSummary(
        title: 'Running',
        count: 2,
        colorHex: 0xFF2E7D32,
        lightBgHex: 0xFFE8F5E9,
      ),
      VehicleStatusSummary(
        title: 'Stopped',
        count: 11,
        colorHex: 0xFFD32F2F,
        lightBgHex: 0xFFFFEBEE,
      ),
      VehicleStatusSummary(
        title: 'Idle',
        count: 2,
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
    vehicleList: [
      VehicleItem(registrationNumber: 'KL 07 D 0518', isSelected: true),
      VehicleItem(registrationNumber: 'KL 07 D 0518'),
      VehicleItem(registrationNumber: 'KL 07 D 0518'),
      VehicleItem(registrationNumber: 'KL 07 D 0518'),
    ],
    engineHoursData: [
      EngineHourDataPoint(date: '2/10', hours: 4.0),
      EngineHourDataPoint(date: '3/10', hours: 2.8),
      EngineHourDataPoint(date: '4/10', hours: 2.9),
      EngineHourDataPoint(date: '5/10', hours: 1.2),
      EngineHourDataPoint(date: '6/10', hours: 2.6),
      EngineHourDataPoint(date: '7/10', hours: 4.2),
      EngineHourDataPoint(date: '8/10', hours: 0.0),
    ],
    travelDistanceData: [
      TravelDistanceDataPoint(date: '6/10', distanceKm: 20.0),
      TravelDistanceDataPoint(date: '7/10', distanceKm: 10.0),
      TravelDistanceDataPoint(date: '8/10', distanceKm: 14.0),
      TravelDistanceDataPoint(date: '9/10', distanceKm: 28.0),
      TravelDistanceDataPoint(date: '10/10', distanceKm: 132.0),
      TravelDistanceDataPoint(date: '11/10', distanceKm: 0.0),
      TravelDistanceDataPoint(date: '12/10', distanceKm: 0.0),
      TravelDistanceDataPoint(date: '13/10', distanceKm: 6.0),
    ],
  ).obs;

  void selectMenu(int index) {
    selectedMenuIndex.value = index;
  }

  void selectVehicle(int index) {
    selectedVehicleIndex.value = index;
  }
}
