import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/dio_client.dart';
import '../models/profile_model.dart';
import '../utils/app_toast.dart';
import '../views/login_view.dart';

import '../views/profile/widgets/sign_out_confirmation_dialog.dart';

class ProfileController extends GetxController {
  final RxInt selectedMenuIndex = 0.obs;
  final RxBool isNotificationEnabled = true.obs;

  final Rx<ProfileModel> profileData = ProfileModel(
    user: UserProfile(name: 'User', phoneNumber: ''),
    generalSettings: [
      GeneralSettingItem(
        title: 'Show History on Live',
        iconType: 'history',
        selectedValue: 'Enabled',
      ),
      GeneralSettingItem(
        title: 'Vehicle Icon Size',
        iconType: 'vehicle_size',
        selectedValue: 'Medium',
      ),
      GeneralSettingItem(
        title: 'Time Format',
        iconType: 'time_format',
        selectedValue: '12 Hours',
      ),
      GeneralSettingItem(
        title: 'Speedometer',
        iconType: 'speedometer',
        selectedValue: 'Gauge',
      ),
      GeneralSettingItem(
        title: 'Map Type',
        iconType: 'map_type',
        selectedValue: 'OpenStreetMap',
      ),
      GeneralSettingItem(
        title: 'Speed',
        iconType: 'speed',
        selectedValue: 'Kmph',
      ),
      GeneralSettingItem(
        title: 'Distance',
        iconType: 'distance',
        selectedValue: 'Km',
      ),
    ],
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var username = prefs.getString('username');
      var userPhone = prefs.getString('user_phone') ?? '';

      if (username == null ||
          username.isEmpty ||
          username.toLowerCase() == 'user') {
        username = userPhone.isNotEmpty ? userPhone : 'User';
      }

      final isPhone = RegExp(r'^[0-9+ ]+$').hasMatch(username);
      final phone = userPhone.isNotEmpty
          ? userPhone
          : (isPhone ? username : '');

      profileData.update((val) {
        if (val != null) {
          profileData.value = ProfileModel(
            user: UserProfile(
              name: username!,
              phoneNumber: phone.isNotEmpty ? phone : 'N/A',
            ),
            generalSettings: val.generalSettings,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  void selectMenu(int index) {
    selectedMenuIndex.value = index;
  }

  void toggleNotification(bool value) {
    isNotificationEnabled.value = value;
  }

  Future<void> signOut() async {
    final context = Get.context;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const SignOutConfirmationDialog(),
      );
    } else {
      await performSignOut();
    }
  }

  Future<void> performSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('token');
    await prefs.remove('username');
    await DioClient().clearToken();
    AppToast.show('Signed out successfully');
    Get.offAll(() => const LoginView());
  }
}
