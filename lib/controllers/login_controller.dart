import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/login_model.dart';
import '../utils/app_toast.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/forgot_password/forgot_password_view.dart';
import '../views/register_view.dart';

class LoginController extends GetxController {
  // Model reference
  final Rx<LoginModel> loginModel = LoginModel().obs;

  // Text Controllers
  late TextEditingController phoneController;
  late TextEditingController passwordController;

  // Reactive UI & Validation States
  final RxBool isPasswordObscured = true.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxString phoneError = ''.obs;
  final RxString passwordError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    passwordController = TextEditingController();

    // Listen to changes and update model
    phoneController.addListener(() {
      if (phoneError.isNotEmpty) phoneError.value = '';
      loginModel.update((val) {
        val?.phoneNumber = phoneController.text.trim();
      });
    });

    passwordController.addListener(() {
      if (passwordError.isNotEmpty) passwordError.value = '';
      loginModel.update((val) {
        val?.password = passwordController.text;
      });
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility state
  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
    isPasswordVisible.value = !isPasswordObscured.value;
  }

  // --- Validation Regex Helpers ---
  static final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
  bool _isValidEmail(String value) => _emailRegex.hasMatch(value);

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  bool _isValidUsername(String value) {
    return value.length >= 3;
  }

  /// Validate inputs before API request
  bool validate() {
    bool isValid = true;
    final username = phoneController.text.trim();

    if (username.isEmpty) {
      phoneError.value = 'Phone number, email or username is required';
      isValid = false;
    } else if (username.contains('@')) {
      if (!_isValidEmail(username)) {
        phoneError.value = 'Please enter a valid email address';
        isValid = false;
      } else {
        phoneError.value = '';
      }
    } else if (_isValidPhone(username)) {
      phoneError.value = '';
    } else if (_isValidUsername(username)) {
      phoneError.value = '';
    } else {
      phoneError.value =
          'Please enter a valid phone number (10+ digits), email or username (3+ characters)';
      isValid = false;
    }

    if (passwordController.text.trim().isEmpty) {
      passwordError.value = 'Password is required';
      isValid = false;
    } else if (passwordController.text.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    } else {
      passwordError.value = '';
    }

    if (!isValid) {
      if (phoneError.isNotEmpty) {
        AppToast.show(phoneError.value, isError: true);
      } else if (passwordError.isNotEmpty) {
        AppToast.show(passwordError.value, isError: true);
      }
    }

    return isValid;
  }

  /// Execute Sign In via Dio Client API request
  Future<void> signIn() async {
    if (!validate()) return;
    isLoading.value = true;

    try {
      final response = await DioClient().post(
        ApiEndPoints.login,
        body: {
          'username': phoneController.text.trim(),
          'password': passwordController.text.trim(),
          'fcm': '',
        },
      );

      isLoading.value = false;

      if (response.data != null) {
        String? token;
        String? displayName;
        final responseData = response.data;

        if (responseData is Map) {
          if (responseData['data'] != null && responseData['data'] is Map) {
            final dataMap = responseData['data'] as Map;
            if (dataMap['details'] != null && dataMap['details'] is Map) {
              token = dataMap['details']['token']?.toString();
              displayName = dataMap['details']['name']?.toString() ??
                  dataMap['details']['username']?.toString() ??
                  dataMap['details']['user_name']?.toString();
            }
            displayName ??= dataMap['name']?.toString() ??
                dataMap['username']?.toString() ??
                dataMap['user_name']?.toString();
          }
          token ??= responseData['token']?.toString();
        }

        if (token != null && token.isNotEmpty) {
          DioClient().updateToken(token);
          final prefs = await SharedPreferences.getInstance();
          final savedName = (displayName != null && displayName.isNotEmpty)
              ? displayName
              : phoneController.text.trim();

          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', savedName);
          await prefs.setString('user_phone', phoneController.text.trim());

          AppToast.show('Signed in successfully!');
          Get.offAll(() => const DashboardView());
        } else {
          final msg = (responseData is Map && responseData['message'] != null)
              ? responseData['message'].toString()
              : 'Failed to login. Please check your credentials.';
          AppToast.show(msg, isError: true);
        }
      }
    } catch (e) {
      isLoading.value = false;
      AppToast.showErrorMessage(e);
    }
  }

  /// Handle Forgot Password click - Opens 3-step ForgotPasswordView
  void onForgotPassword() {
    Get.to(() => const ForgotPasswordView());
  }

  /// Handle Sign Up click - Navigates to RegisterView
  void onSignUp() {
    Get.to(() => const RegisterView());
  }
}
