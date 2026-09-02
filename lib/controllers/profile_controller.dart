import 'package:get/get.dart';
import '../models/profile_model.dart';
import '../utils/app_toast.dart';
import '../views/login_view.dart';

class ProfileController extends GetxController {
  final RxInt selectedMenuIndex = 0.obs;
  final RxBool isNotificationEnabled = true.obs;

  final Rx<ProfileModel> profileData = ProfileModel(
    user: UserProfile(
      name: 'John Doe',
      phoneNumber: '+91 91234 56789',
    ),
    generalSettings: [
      GeneralSettingItem(title: 'Show History on Live', iconType: 'history', selectedValue: 'Enabled'),
      GeneralSettingItem(title: 'Vehicle Icon Size', iconType: 'vehicle_size', selectedValue: 'Medium'),
      GeneralSettingItem(title: 'Time Format', iconType: 'time_format', selectedValue: '12 Hours'),
      GeneralSettingItem(title: 'Speedometer', iconType: 'speedometer', selectedValue: 'Gauge'),
      GeneralSettingItem(title: 'Map Type', iconType: 'map_type', selectedValue: 'OpenStreetMap'),
      GeneralSettingItem(title: 'Speed', iconType: 'speed', selectedValue: 'Kmph'),
      GeneralSettingItem(title: 'Distance', iconType: 'distance', selectedValue: 'Km'),
    ],
  ).obs;

  void selectMenu(int index) {
    selectedMenuIndex.value = index;
  }

  void toggleNotification(bool value) {
    isNotificationEnabled.value = value;
  }

  void signOut() {
    AppToast.show('Signed out successfully');
    Get.offAll(() => const LoginView());
  }
}
