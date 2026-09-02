import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/register_model.dart';
import '../utils/app_toast.dart';

class RegisterController extends GetxController {
  // Model reference
  final Rx<RegisterModel> registerModel = RegisterModel().obs;

  // Text Controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  // Reactive States
  final RxBool isPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // Field change listeners
    nameController.addListener(() {
      registerModel.update((val) => val?.name = nameController.text.trim());
    });

    phoneController.addListener(() {
      registerModel.update((val) => val?.phoneNumber = phoneController.text.trim());
    });

    passwordController.addListener(() {
      registerModel.update((val) => val?.password = passwordController.text);
    });

    confirmPasswordController.addListener(() {
      registerModel.update((val) => val?.confirmPassword = confirmPasswordController.text);
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  /// Register Action Handler
  Future<void> onRegister() async {
    isLoading.value = true;

    try {
      // Simulate API registration request
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

      AppToast.show('Account created successfully!');

      // Return back to Login screen
      onLoginTap();
    } catch (e) {
      AppToast.show('Unable to create account. Please try again.', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate back to Login view
  void onLoginTap() {
    Get.back();
  }
}
