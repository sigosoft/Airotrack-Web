import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // Reactive UI States
  final RxBool isPasswordObscured = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    passwordController = TextEditingController();

    // Listen to changes and update model
    phoneController.addListener(() {
      loginModel.update((val) {
        val?.phoneNumber = phoneController.text.trim();
      });
    });

    passwordController.addListener(() {
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
  }

  /// Execute Sign In and navigate to DashboardView
  Future<void> signIn() async {
    isLoading.value = true;

    try {
      // Simulate network authentication API request
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

      AppToast.show('Signed in successfully!');

      // Navigate to Dashboard View
      Get.offAll(() => const DashboardView());
    } catch (e) {
      AppToast.show('Failed to sign in. Please try again.', isError: true);
    } finally {
      isLoading.value = false;
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
