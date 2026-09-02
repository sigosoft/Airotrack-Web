import 'package:get/get.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final RxInt selectedTab = 0.obs; // 0: Alerts, 1: Announcements, 2: Reminders
  final RxInt currentPage = 1.obs;
  final RxString searchQuery = ''.obs;

  final Rx<NotificationModel> notificationData = NotificationModel(
    notifications: [
      NotificationItemData(
        vehicleNumber: 'KL 07 D 0518',
        ignitionStatus: 'Ignition On',
        isIgnitionOn: true,
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
        timestamp: 'Oct 17, 2025 5:38:08 PM',
      ),
      NotificationItemData(
        vehicleNumber: 'KL 07 D 0518',
        ignitionStatus: 'Ignition Off',
        isIgnitionOn: false,
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
        timestamp: 'Oct 17, 2025 5:38:08 PM',
      ),
      NotificationItemData(
        vehicleNumber: 'KL 07 D 0518',
        ignitionStatus: 'Ignition On',
        isIgnitionOn: true,
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
        timestamp: 'Oct 17, 2025 5:38:08 PM',
      ),
      NotificationItemData(
        vehicleNumber: 'KL 07 D 0518',
        ignitionStatus: 'Ignition Off',
        isIgnitionOn: false,
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
        timestamp: 'Oct 17, 2025 5:38:08 PM',
      ),
      NotificationItemData(
        vehicleNumber: 'KL 07 D 0518',
        ignitionStatus: 'Ignition On',
        isIgnitionOn: true,
        locationAddress: 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
        timestamp: 'Oct 17, 2025 5:38:08 PM',
      ),
    ],
  ).obs;

  void selectTab(int index) {
    selectedTab.value = index;
  }

  void selectPage(int page) {
    currentPage.value = page;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }
}
