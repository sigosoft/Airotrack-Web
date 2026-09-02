import 'package:get/get.dart';
import '../models/tracking_model.dart';

class TrackingController extends GetxController {
  final Rx<TrackingModel> trackingData = TrackingModel(
    trackingVehicles: [
      TrackingCardData(
        registrationNumber: 'KL 07 A 0518',
        speedKmH: 20,
        status: 'RUNNING',
        duration: 'since 08h 30m',
        timestamp: 'Jul 31, 2025 05:38:08 PM',
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690639, India',
        distanceKmText: '38.12 Km',
        validityText: '599 Days validity',
        isGreenVehicle: true,
        isLocked: false,
        isRunning: true,
      ),
      TrackingCardData(
        registrationNumber: 'KL 07 A 0518',
        speedKmH: 0,
        status: 'RUNNING',
        duration: 'since 08h 30m',
        timestamp: 'Jul 31, 2025 05:38:08 PM',
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690639, India',
        distanceKmText: '20.12 Km',
        validityText: '596 Days validity',
        isGreenVehicle: false,
        isLocked: true,
        isRunning: false,
      ),
      TrackingCardData(
        registrationNumber: 'KL 07 A 0518',
        speedKmH: 20,
        status: 'RUNNING',
        duration: 'since 08h 30m',
        timestamp: 'Jul 31, 2025 05:38:08 PM',
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690639, India',
        distanceKmText: '38.12 Km',
        validityText: '599 Days validity',
        isGreenVehicle: true,
        isLocked: false,
        isRunning: true,
      ),
      TrackingCardData(
        registrationNumber: 'KL 07 A 0518',
        speedKmH: 0,
        status: 'RUNNING',
        duration: 'since 08h 30m',
        timestamp: 'Jul 31, 2025 05:38:08 PM',
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690639, India',
        distanceKmText: '20.12 Km',
        validityText: '596 Days validity',
        isGreenVehicle: false,
        isLocked: true,
        isRunning: false,
      ),
    ],
  ).obs;

  void onActionTap(String actionName, String vehicleNumber) {}
}
