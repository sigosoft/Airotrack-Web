import 'package:get/get.dart';
import '../models/vehicle_detail_model.dart';

class VehicleDetailController extends GetxController {
  final RxInt selectedTopTab = (-1).obs; // -1: Vehicle Info Detail, 0: History, 1: Alerts, 2: Statistics
  final RxBool isMapDialogVisible = false.obs;
  final RxBool isHistoryMapDialogVisible = false.obs;
  final RxDouble playbackProgress = 0.3.obs;
  final RxBool isPlaying = false.obs;
  final RxString playbackSpeed = '1x'.obs;
  final RxString startDateStr = '28-08-2025 12:00 AM'.obs;
  final RxString endDateStr = '28-08-2025 12:00 AM'.obs;

  final Rx<VehicleDetailData> vehicleDetail = VehicleDetailData(
    vehicleNumber: 'KL 07 D 0518',
    odometerDigits: '0535855',
    timestamp: 'Jul 31, 2025 5:38:08 PM',
    distanceKm: '20.12 km',
    speedKmph: 45,
    coordinates: '9°58\'49.7"N 76°19\'06.8"E',
    address: 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    deviceTime: 'Aug 02, 2025 02:38:40',
    serverTime: 'Aug 02, 2025 02:38:40',
    runningDuration: '06-36 hrs',
    idleDuration: '06-36 hrs',
    stoppedDuration: '06-36 hrs',
    inactiveDuration: '06-36 hrs',
    avgSpeedKmph: '50',
    maxSpeedKmph: '70',
    todayOdoKm: '80',
    sensors: [
      SensorReadingItem(label: 'Battery', value: 'ON', iconType: 'battery'),
      SensorReadingItem(label: 'Car Battery', value: '12V', iconType: 'car_battery'),
      SensorReadingItem(label: 'Satellite', value: '15', iconType: 'satellite'),
      SensorReadingItem(label: 'Fuel', value: 'N/A', iconType: 'fuel'),
      SensorReadingItem(label: 'Accuracy', value: '0.0', iconType: 'accuracy'),
      SensorReadingItem(label: 'Temperature', value: 'N/A', iconType: 'temp'),
      SensorReadingItem(label: 'Movement', value: 'False', iconType: 'movement'),
      SensorReadingItem(label: 'Movement', value: 'N/A', iconType: 'movement2'),
    ],
  ).obs;

  void selectTab(int index) {
    selectedTopTab.value = index;
  }

  void toggleMapDialog() {
    isMapDialogVisible.value = !isMapDialogVisible.value;
  }

  void hideMapDialog() {
    isMapDialogVisible.value = false;
  }

  void showMapDialog() {
    isMapDialogVisible.value = true;
  }

  void toggleHistoryMapDialog() {
    isHistoryMapDialogVisible.value = !isHistoryMapDialogVisible.value;
  }

  void hideHistoryMapDialog() {
    isHistoryMapDialogVisible.value = false;
  }

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
  }
}
