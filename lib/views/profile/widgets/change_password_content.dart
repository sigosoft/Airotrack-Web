import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/profile_controller.dart';
import '../../../utils/custom_media_query.dart';

class ChangePasswordContent extends StatelessWidget {
  const ChangePasswordContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final isMobile = CustomMediaQuery.isMobile(context);

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordField(
                    label: 'Current Password',
                    controller: controller.currentPasswordController,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: 'New Password',
                    controller: controller.newPasswordController,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: 'Confirm Password',
                    controller: controller.confirmPasswordController,
                  ),
                  const SizedBox(height: 24),

                  // Confirm Button
                  Obx(() {
                    return SizedBox(
                      width: isMobile ? double.infinity : 200,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: controller.isChangingPassword.value
                            ? null
                            : () => controller.changePassword(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isChangingPassword.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: Color(0xFF00A3E0), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
