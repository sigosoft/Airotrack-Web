import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../controllers/login_controller.dart';
import '../utils/custom_media_query.dart';
import 'widgets/custom_input_field.dart';
import 'widgets/phone_input_field.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject / retrieve GetX controller
    final LoginController controller = Get.put(LoginController());

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

          // 2. Responsive Sign-In Card Container
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
                    vertical: isMobile ? 32.0 : 40.0,
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
                          height: isMobile ? 68.0 : 78.0,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.location_on,
                                  size: 54,
                                  color: AppColors.buttonBlue,
                                ),
                                Text(
                                  'AIR TRACK',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

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
                          AppStrings.pleaseSignIn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // --- Phone Input Field ---
                        PhoneInputField(controller: controller.phoneController),
                        const SizedBox(height: 16),

                        // --- Password Input Field ---
                        Obx(
                          () => CustomInputField(
                            controller: controller.passwordController,
                            hintText: AppStrings.enterPassword,
                            isObscure: controller.isPasswordObscured.value,
                            onToggleObscure:
                                controller.togglePasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- Forgot Password Link ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: controller.onForgotPassword,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 2.0,
                              ),
                              child: Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Sign In Button ---
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.signIn,
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

                        // --- Sign Up Footer Link ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              AppStrings.dontHaveAccount,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            InkWell(
                              onTap: controller.onSignUp,
                              borderRadius: BorderRadius.circular(4),
                              child: const Text(
                                AppStrings.signUp,
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
