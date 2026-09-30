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

  Future<void> _pickDate(
    BuildContext context,
    NotificationController controller,
    bool isStart,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      if (isStart) {
        controller.startDateStr.value = formatted;
      } else {
        controller.endDateStr.value = formatted;
      }
      controller.loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationController controller =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());
    final DashboardController dashboardController =
        Get.isRegistered<DashboardController>()
            ? Get.find<DashboardController>()
            : Get.put(DashboardController());

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
          Obx(
            () => NotificationHeader(
              onSearchChanged: controller.updateSearch,
              startDate: controller.startDateStr.value.isNotEmpty
                  ? controller.startDateStr.value
                  : null,
              endDate: controller.endDateStr.value.isNotEmpty
                  ? controller.endDateStr.value
                  : null,
              onStartDateTap: () => _pickDate(context, controller, true),
              onEndDateTap: () => _pickDate(context, controller, false),
              onFilterTap: () => controller.loadNotifications(),
            ),
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
                          if (controller.isLoading.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00A3E0),
                                ),
                              ),
                            );
                          }

                          final notifications =
                              controller.notificationData.value.notifications;

                          if (notifications.isEmpty) {
                            String emptyMessage = 'No alerts found';
                            if (controller.selectedTab.value == 1) {
                              emptyMessage = 'No announcements found';
                            } else if (controller.selectedTab.value == 2) {
                              emptyMessage = 'No reminders found';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  emptyMessage,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF667085),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          // 10 items per page pagination
                          const pageSize = 10;
                          final totalPages = (notifications.length / pageSize).ceil();
                          final safePage = controller.currentPage.value
                              .clamp(1, totalPages > 0 ? totalPages : 1);
                          final startIndex = (safePage - 1) * pageSize;
                          final pagedNotifications = notifications
                              .skip(startIndex)
                              .take(pageSize)
                              .toList();

                          return Column(
                            children: pagedNotifications.map((item) {
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

                          final safePage = controller.currentPage.value
                              .clamp(1, totalPages);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(totalPages, (index) {
                                final pageNum = index + 1;
                                final isActive = safePage == pageNum;

                                return InkWell(
                                  onTap: () => controller.selectPage(pageNum),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF00A3E0)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$pageNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isActive
                                            ? Colors.white
                                            : const Color(0xFF344054),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 12),
                              if (safePage < totalPages)
                                InkWell(
                                  onTap: () {
                                    if (safePage < totalPages) {
                                      controller.selectPage(safePage + 1);
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
