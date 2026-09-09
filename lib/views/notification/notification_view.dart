import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../utils/custom_media_query.dart';
import '../dashboard/widgets/sidebar_navigation.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_header.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.put(NotificationController());
    final DashboardController dashboardController = Get.put(DashboardController());

    final isMobile = CustomMediaQuery.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: Obx(
                  () => SidebarNavigation(
                    selectedIndex: dashboardController.selectedMenuIndex.value,
                    onItemSelected: (index) {
                      dashboardController.selectMenu(index);
                      Get.offAllNamed('/dashboard');
                    },
                    onSubItemSelected: (_) {
                      Get.offAllNamed('/dashboard');
                    },
                    width: double.infinity,
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // 1. Notification Top Header Bar
          NotificationHeader(
            onSearchChanged: controller.updateSearch,
          ),

          // 2. Main Content Area (Sidebar + Notification List)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar Navigation
                if (!isMobile)
                  Obx(
                    () => SidebarNavigation(
                      selectedIndex: dashboardController.selectedMenuIndex.value,
                      onItemSelected: (index) {
                        dashboardController.selectMenu(index);
                        Get.offAllNamed('/dashboard');
                      },
                    ),
                  ),

                // Notification Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Tab Bar Pills (Alerts, Announcements, Reminders)
                        Obx(() {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTabPill('Alerts', 0, controller),
                                const SizedBox(width: 12),
                                _buildTabPill('Announcements', 1, controller),
                                const SizedBox(width: 12),
                                _buildTabPill('Reminders', 2, controller),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),

                        // Notification Cards Stack
                        Obx(() {
                          final notifications =
                              controller.notificationData.value.notifications;

                          return Column(
                            children: notifications.map((item) {
                              return NotificationCard(data: item);
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 24),

                        // Bottom Pagination Row (1 2 3 4 5 6 7 8 9 10 NEXT)
                        Obx(() {
                          final notifications =
                              controller.notificationData.value.notifications;
                          final totalPages = (notifications.length / 10).ceil();

                          if (totalPages <= 1) {
                            return const SizedBox.shrink();
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(totalPages, (index) {
                                final pageNum = index + 1;
                                final isActive = controller.currentPage.value == pageNum;

                                return InkWell(
                                  onTap: () => controller.selectPage(pageNum),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF00A3E0) : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$pageNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        color: isActive ? Colors.white : const Color(0xFF344054),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 12),
                              if (controller.currentPage.value < totalPages)
                                InkWell(
                                  onTap: () {
                                    if (controller.currentPage.value < totalPages) {
                                      controller.selectPage(controller.currentPage.value + 1);
                                    }
                                  },
                                  child: const Text(
                                    'NEXT',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00A3E0),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, int index, NotificationController controller) {
    final isSelected = controller.selectedTab.value == index;

    return InkWell(
      onTap: () => controller.selectTab(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3E0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A3E0) : const Color(0xFFE4E7EC),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }
}
