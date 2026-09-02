import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../controllers/register_controller.dart';
import '../utils/custom_media_query.dart';
import 'widgets/custom_input_field.dart';
import 'widgets/phone_input_field.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject / retrieve RegisterController
    final RegisterController controller = Get.put(RegisterController());

    final isMobile = CustomMediaQuery.isMobile(context);
    final isLandscape = CustomMediaQuery.isLandscape(context);
    final screenHeight = CustomMediaQuery.screenHeight(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image with graceful fallback
          Positioned.fill(
            child: Image.asset(
              AppAssets.background,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 2. Responsive Registration Card Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20.0 : 32.0,
                  vertical: isLandscape && screenHeight < 600 ? 16.0 : 24.0,
                ),
                child: Container(
                  width: CustomMediaQuery.cardWidth(context),
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24.0 : 36.0,
                    vertical: isMobile ? 28.0 : 36.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 30,
                        spreadRadius: 0,
                        offset: Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- Logo ---
                        Image.asset(
                          AppAssets.logo,
                          height: isMobile ? 64.0 : 74.0,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.location_on,
                                  size: 50,
                                  color: AppColors.buttonBlue,
                                ),
                                Text(
                                  'AIR TRACK',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // --- Title Header ---
                        const Text(
                          AppStrings.hello,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // --- Subtitle ---
                        const Text(
                          AppStrings.pleaseRegister,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- 1. Name Input Field ---
                        CustomInputField(
                          controller: controller.nameController,
                          hintText: AppStrings.enterName,
                        ),
                        const SizedBox(height: 14),

                        // --- 2. Phone Input Field ---
                        PhoneInputField(controller: controller.phoneController),
                        const SizedBox(height: 14),

                        // --- 3. Password Input Field ---
                        Obx(
                          () => CustomInputField(
                            controller: controller.passwordController,
                            hintText: AppStrings.enterPassword,
                            isObscure: controller.isPasswordObscured.value,
                            onToggleObscure:
                                controller.togglePasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // --- 4. Confirm Password Input Field ---
                        Obx(
                          () => CustomInputField(
                            controller: controller.confirmPasswordController,
                            hintText: AppStrings.enterConfirmPassword,
                            isObscure:
                                controller.isConfirmPasswordObscured.value,
                            onToggleObscure:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Registration Action Button ---
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.onRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      AppStrings.signIn,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Already have an account? Login Footer Link ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              AppStrings.alreadyHaveAccount,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            InkWell(
                              onTap: controller.onLoginTap,
                              borderRadius: BorderRadius.circular(4),
                              child: const Text(
                                AppStrings.login,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
