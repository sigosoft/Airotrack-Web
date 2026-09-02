import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../notification/notification_view.dart';
import '../../profile/profile_view.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    this.userName = 'John Doe',
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: AIR TRACK Logo
          Image.asset(
            AppAssets.logo,
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Row(
              children: const [
                Icon(Icons.location_on, color: AppColors.buttonBlue, size: 28),
                SizedBox(width: 6),
                Text(
                  'AIR TRACK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Right: User Profile & Notification Badge
          Row(
            children: [
              // User Name (Clickable to open ProfileView)
              InkWell(
                onTap: onProfileTap ?? () => Get.to(() => const ProfileView()),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Notification Bell Icon with Badge (Clickable to open NotificationView)
              InkWell(
                onTap: onNotificationTap ?? () => Get.to(() => const NotificationView()),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF344054),
                        size: 24,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User Avatar (Clickable to open ProfileView)
              InkWell(
                onTap: onProfileTap ?? () => Get.to(() => const ProfileView()),
                borderRadius: BorderRadius.circular(16),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE4E7EC),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF667085),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
