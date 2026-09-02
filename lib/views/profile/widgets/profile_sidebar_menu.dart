import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/profile_controller.dart';

class ProfileSidebarMenu extends StatelessWidget {
  const ProfileSidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    final menuItems = [
      {'title': 'General Settings', 'asset': AppAssets.generalSettings},
      {'title': 'Account Settings', 'asset': AppAssets.accountSettings},
      {'title': 'Rise Ticket', 'asset': AppAssets.riseTicket},
      {'title': 'Change Password', 'asset': AppAssets.changePassword},
      {'title': 'Configure Alerts', 'asset': AppAssets.configureAlerts},
      {'title': 'Notification', 'asset': AppAssets.notificationss, 'hasSwitch': true},
    ];

    return Container(
      width: 350,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Row (Back Arrow + Profile Title)
            Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. User Info Card
            Obx(() {
              final user = controller.profileData.value.user;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFFE4E7EC),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF667085),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: Color(0xFF667085),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.phoneNumber,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // 3. Menu Items Stack (6 Cards)
            Obx(() {
              final selectedIndex = controller.selectedMenuIndex.value;

              return Column(
                children: List.generate(menuItems.length, (index) {
                  final isSelected = selectedIndex == index;
                  final item = menuItems[index];
                  final hasSwitch = item['hasSwitch'] == true;

                  return InkWell(
                    onTap: () {
                      if (hasSwitch) {
                        controller.toggleNotification(!controller.isNotificationEnabled.value);
                      } else {
                        controller.selectMenu(index);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFBEE3F8) : const Color(0xFFEAECF0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            item['asset'] as String,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF1D2939) : const Color(0xFF344054),
                              ),
                            ),
                          ),
                          if (hasSwitch)
                            Transform.scale(
                              scale: 0.7,
                              child: CupertinoSwitch(
                                value: controller.isNotificationEnabled.value,
                                activeColor: const Color(0xFF00A3E0),
                                onChanged: controller.toggleNotification,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 24),

            // 4. Sign Out Button directly below Notification item
            Center(
              child: InkWell(
                onTap: controller.signOut,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.logout,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
