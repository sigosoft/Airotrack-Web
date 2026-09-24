import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/custom_media_query.dart';
import '../../notification/notification_view.dart';
import '../../profile/profile_view.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMenuTap;

  const DashboardHeader({
    super.key,
    this.userName = 'John Doe',
    this.onNotificationTap,
    this.onProfileTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = CustomMediaQuery.isMobile(context);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Menu Button (Mobile) + AIR TRACK Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMobile) ...[
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF344054),
                        size: 24,
                      ),
                      onPressed:
                          onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Image.asset(
                  AppAssets.logo,
                  height: isMobile ? 32 : 38,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.buttonBlue,
                        size: isMobile ? 22 : 28,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AIR TRACK',
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Right: User Profile & Notification Badge
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // User Name (Truncated with ellipsis if long)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: isMobile ? 12.5 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 16),

                  // Notification Bell Icon with Badge (Clickable to open NotificationView)
                  InkWell(
                    onTap:
                        onNotificationTap ??
                        () => Get.to(() => const NotificationView()),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: const Color(0xFF344054),
                            size: isMobile ? 22 : 24,
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
                  SizedBox(width: isMobile ? 8 : 16),

                  // User Avatar (Clickable to open ProfileView)
                  InkWell(
                    onTap:
                        onProfileTap ?? () => Get.to(() => const ProfileView()),
                    borderRadius: BorderRadius.circular(16),
                    child: CircleAvatar(
                      radius: isMobile ? 14 : 16,
                      backgroundColor: const Color(0xFFE4E7EC),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF667085),
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
