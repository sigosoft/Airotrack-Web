import 'package:get/get.dart';
import '../models/tracking_model.dart';
import '../models/vehicle_model.dart';
import 'home_controller.dart';

class TrackingController extends GetxController {
  final Rx<TrackingModel> trackingData = TrackingModel(trackingVehicles: []).obs;
  late final HomeController _homeController;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<HomeController>()) {
      _homeController = Get.find<HomeController>();
    } else {
      _homeController = Get.put(HomeController());
    }

    // Map home vehicles to tracking cards dynamically
    ever(_homeController.vehicles, (List<Vehicle> list) => _updateTrackingCards(list));
    if (_homeController.vehicles.isNotEmpty) {
      _updateTrackingCards(_homeController.vehicles);
    } else {
      _homeController.fetchVehicles();
    }
  }

  void _updateTrackingCards(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) return;

    final cards = vehicles.map((v) {
      final isRunning = v.status.toLowerCase() == 'running';
      final speed = double.tryParse(v.speed) ?? 0.0;

      return TrackingCardData(
        registrationNumber: v.plateNumber,
        speedKmH: speed.toInt(),
        status: v.status.toUpperCase(),
        duration: v.statusDuration.isNotEmpty ? v.statusDuration : 'N/A',
        timestamp: v.lastUpdated.isNotEmpty ? v.lastUpdated : 'N/A',
        locationAddress: v.locationLabel,
        distanceKmText: v.todayKm,
        validityText: '${v.validityDays} Days validity',
        isGreenVehicle: isRunning,
        isLocked: v.isLocked,
        isRunning: isRunning,
      );
    }).toList();

    trackingData.value = TrackingModel(trackingVehicles: cards);
  }

  void onActionTap(String actionName, String vehicleNumber) {}
}
