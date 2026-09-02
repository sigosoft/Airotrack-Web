import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/tracking_controller.dart';
import '../../utils/custom_media_query.dart';
import '../dashboard/widgets/dashboard_header.dart';
import '../dashboard/widgets/sidebar_navigation.dart';
import '../dashboard/widgets/vehicle_status_cards.dart';
import 'widgets/tracking_card.dart';

class TrackingView extends StatelessWidget {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final TrackingController controller = Get.put(TrackingController());
    final DashboardController dashboardController = Get.put(DashboardController());

    final isMobile = CustomMediaQuery.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Header Bar
          Obx(
            () => DashboardHeader(
              userName: dashboardController.dashboardData.value.userName,
            ),
          ),

          // 2. Body Container (Sidebar + Tracking Cards Grid)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar Navigation (Index 1 selected for Tracking)
                if (!isMobile)
                  Obx(
                    () => SidebarNavigation(
                      selectedIndex: dashboardController.selectedMenuIndex.value,
                      onItemSelected: dashboardController.selectMenu,
                    ),
                  ),

                // Main Tracking Content Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Summary Status Bar
                        Obx(
                          () => VehicleStatusCards(
                            summaryList: dashboardController.dashboardData.value.summaryList,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2x2 Responsive Tracking Cards Grid
                        Obx(
                          () => LayoutBuilder(
                            builder: (context, constraints) {
                              final trackingList = controller.trackingData.value.trackingVehicles;

                              if (constraints.maxWidth < 900) {
                                return Column(
                                  children: trackingList.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: TrackingCard(data: item),
                                    );
                                  }).toList(),
                                );
                              }

                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: trackingList.map((item) {
                                  return SizedBox(
                                    width: (constraints.maxWidth - 16) / 2,
                                    child: TrackingCard(data: item),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
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
}
