import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/vehicle_detail_controller.dart';
import '../../utils/custom_media_query.dart';
import 'widgets/alerts_view_content.dart';
import 'widgets/history_view_content.dart';
import 'widgets/map_bottom_action_cards.dart';
import 'widgets/statistics_view_content.dart';
import 'widgets/tracking_map_container.dart';
import 'widgets/vehicle_info_sidebar.dart';

class VehicleDetailMapView extends StatelessWidget {
  const VehicleDetailMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller = Get.put(
      VehicleDetailController(),
    );
    final isMobile = CustomMediaQuery.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.selectedTopTab.value == 0) {
            return const HistoryViewContent();
          } else if (controller.selectedTopTab.value == 1) {
            return const AlertsViewContent();
          } else if (controller.selectedTopTab.value == 2) {
            return const StatisticsViewContent();
          }

          if (isMobile) {
            return Stack(
              children: [
                // 1. Full Screen Interactive Map Area
                Positioned.fill(
                  child: TrackingMapContainer(
                    selectedTab: controller.selectedTopTab.value,
                    onTabSelected: controller.selectTab,
                  ),
                ),

                // 2. Draggable Bottom Sheet with Action Cards & Vehicle Metrics
                DraggableScrollableSheet(
                  initialChildSize: 0.40,
                  minChildSize: 0.22,
                  maxChildSize: 0.88,
                  snap: true,
                  snapSizes: const [0.22, 0.40, 0.88],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 16,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top Drag Handle Bar
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(top: 8, bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD0D5DD),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Action Cards Row (Share location, Add geofence, Update odometer, Add reminders, Street view)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: MapBottomActionCards(),
                          ),

                          const Divider(height: 1, color: Color(0xFFEAECF0)),

                          // Scrollable Vehicle Details & Metrics
                          Expanded(
                            child: VehicleInfoSidebar(
                              data: controller.vehicleDetail.value,
                              scrollController: scrollController,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Vehicle Details Metrics Sidebar
              VehicleInfoSidebar(data: controller.vehicleDetail.value),

              // Right Interactive Map Container Area
              Expanded(
                child: TrackingMapContainer(
                  selectedTab: controller.selectedTopTab.value,
                  onTabSelected: controller.selectTab,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
