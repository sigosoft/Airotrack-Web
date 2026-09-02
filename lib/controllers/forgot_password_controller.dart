import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/forgot_password_model.dart';
import '../utils/app_toast.dart';
import '../views/forgot_password/otp_verification_view.dart';
import '../views/forgot_password/create_new_password_view.dart';
import '../views/login_view.dart';

class ForgotPasswordController extends GetxController {
  final Rx<ForgotPasswordModel> model = ForgotPasswordModel().obs;

  late TextEditingController phoneController;
  late TextEditingController otpController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final RxBool isNewPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    otpController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    phoneController.addListener(() {
      model.update((val) => val?.phoneNumber = phoneController.text.trim());
    });

    otpController.addListener(() {
      model.update((val) => val?.otpCode = otpController.text.trim());
    });

    newPasswordController.addListener(() {
      model.update((val) => val?.newPassword = newPasswordController.text);
    });

    confirmPasswordController.addListener(() {
      model.update((val) => val?.confirmPassword = confirmPasswordController.text);
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordObscured.value = !isNewPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  /// Step 1: Send Verification Code
  Future<void> sendVerificationCode() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      AppToast.show('Verification code sent!');

      Get.to(() => const OtpVerificationView());
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 2: Verify OTP
  Future<void> verifyOtp() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      AppToast.show('OTP verified successfully!');

      Get.to(() => const CreateNewPasswordView());
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 3: Reset Password
  Future<void> resetPassword() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

      AppToast.show('Password reset successfully!');

      // Return to Login Screen and clear stack
      Get.offAll(() => const LoginView());
    } finally {
      isLoading.value = false;
    }
  }
}
