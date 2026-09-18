import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/profile_model.dart';
import '../utils/app_toast.dart';
import '../views/login_view.dart';
import 'dashboard_controller.dart';

import '../views/profile/widgets/delete_account_confirmation_dialog.dart';
import '../views/profile/widgets/sign_out_confirmation_dialog.dart';

class ProfileController extends GetxController {
  final RxInt selectedMenuIndex = 0.obs;
  final RxBool isNotificationEnabled = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isChangingPassword = false.obs;

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

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
    fetchProfileDetails();
  }

  /// Call GET /profile API method to load profile details
  Future<void> fetchProfileDetails() async {
    try {
      isLoading.value = true;
      final response = await DioClient().get(ApiEndPoints.profile);

      if (response.data != null) {
        final fetchedUser = _parseUserProfile(
          response.data,
          profileData.value.user,
        );
        profileData.update((val) {
          if (val != null) {
            profileData.value = ProfileModel(
              user: fetchedUser,
              generalSettings: val.generalSettings,
            );
          }
        });

        final prefs = await SharedPreferences.getInstance();
        if (fetchedUser.name.isNotEmpty && fetchedUser.name != 'User') {
          await prefs.setString('username', fetchedUser.name);
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().updateUserName(fetchedUser.name);
          }
        }
        if (fetchedUser.phoneNumber.isNotEmpty &&
            fetchedUser.phoneNumber != 'N/A') {
          await prefs.setString('user_phone', fetchedUser.phoneNumber);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Call POST /update_profile API method to update profile details
  Future<bool> updateProfile({
    String? name,
    String? companyName,
    String? mobile,
  }) async {
    try {
      isLoading.value = true;
      final currentUser = profileData.value.user;

      final bodyName = name ?? currentUser.name;
      final bodyCompany = companyName ?? currentUser.companyName;
      final bodyMobile = mobile ?? currentUser.phoneNumber;

      final response = await DioClient().post(
        ApiEndPoints.updateProfile,
        body: {
          'name': bodyName,
          'company_name': bodyCompany,
          'mobile': bodyMobile,
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          (response.data is Map && response.data['status'] == true)) {
        AppToast.show(
          (response.data is Map && response.data['message'] != null)
              ? response.data['message'].toString()
              : 'Profile updated successfully!',
        );

        await fetchProfileDetails();
        return true;
      } else {
        AppToast.show(
          (response.data is Map && response.data['message'] != null)
              ? response.data['message'].toString()
              : 'Failed to update profile',
          isError: true,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  UserProfile _parseUserProfile(
    dynamic responseData,
    UserProfile fallbackUser,
  ) {
    dynamic userObj;

    if (responseData is Map) {
      final data = responseData['data'];
      if (data is Map) {
        if (data['user'] is Map) {
          userObj = data['user'];
        } else if (data['details'] is Map) {
          userObj = data['details'];
        } else if (data['profile'] is Map) {
          userObj = data['profile'];
        } else {
          userObj = data;
        }
      } else if (responseData['user'] is Map) {
        userObj = responseData['user'];
      } else if (responseData['details'] is Map) {
        userObj = responseData['details'];
      } else if (responseData['profile'] is Map) {
        userObj = responseData['profile'];
      } else {
        userObj = responseData;
      }
    }

    if (userObj is Map) {
      final map = Map<String, dynamic>.from(userObj);
      final parsed = UserProfile.fromJson(map);

      final finalName = (parsed.name.isNotEmpty && parsed.name != 'User')
          ? parsed.name
          : fallbackUser.name;
      final finalPhone =
          (parsed.phoneNumber.isNotEmpty && parsed.phoneNumber != 'N/A')
          ? parsed.phoneNumber
          : fallbackUser.phoneNumber;
      final finalAvatar = parsed.avatarUrl.isNotEmpty
          ? parsed.avatarUrl
          : fallbackUser.avatarUrl;
      final finalCompany = parsed.companyName.isNotEmpty
          ? parsed.companyName
          : fallbackUser.companyName;

      return UserProfile(
        name: finalName,
        phoneNumber: finalPhone,
        avatarUrl: finalAvatar,
        companyName: finalCompany,
      );
    }

    return fallbackUser;
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

      if (username != null && username.isNotEmpty && username != 'User') {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().updateUserName(username);
        }
      }
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

  Future<void> deleteAccount() async {
    final context = Get.context;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const DeleteAccountConfirmationDialog(),
      );
    } else {
      await performDeleteAccount();
    }
  }

  Future<void> performDeleteAccount() async {
    try {
      isLoading.value = true;
      final response = await DioClient().post(ApiEndPoints.deleteAccount);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          (response.data is Map && response.data['status'] == true)) {
        AppToast.show(
          (response.data is Map && response.data['message'] != null)
              ? response.data['message'].toString()
              : 'Account deleted successfully',
        );
        await performSignOut();
      } else {
        AppToast.show(
          (response.data is Map && response.data['message'] != null)
              ? response.data['message'].toString()
              : 'Failed to delete account',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      AppToast.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Call POST /changePassword API method to change password
  Future<bool> changePassword() async {
    final currentPass = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      AppToast.show('Please enter current password', isError: true);
      return false;
    }

    if (newPass.isEmpty) {
      AppToast.show('Please enter new password', isError: true);
      return false;
    }

    if (newPass.length < 6) {
      AppToast.show('New password must be at least 6 characters', isError: true);
      return false;
    }

    if (confirmPass.isNotEmpty && newPass != confirmPass) {
      AppToast.show('New password and confirm password do not match',
          isError: true);
      return false;
    }

    try {
      isChangingPassword.value = true;
      final response = await DioClient().post(
        ApiEndPoints.changePassword,
        body: {
          'current_password': currentPass,
          'password': newPass,
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          (response.data is Map && response.data['status'] == true)) {
        AppToast.show(
          (response.data is Map && response.data['message'] != null)
              ? response.data['message'].toString()
              : 'Password changed successfully!',
        );

        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        return true;
      } else {
        AppToast.show(
          (response.data is Map && response.data['message'] != null)
              ? response.data['message'].toString()
              : 'Failed to change password',
          isError: true,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isChangingPassword.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
