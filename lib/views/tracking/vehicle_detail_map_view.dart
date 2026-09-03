import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/vehicle_detail_controller.dart';
import '../../utils/custom_media_query.dart';
import 'widgets/alerts_view_content.dart';
import 'widgets/history_view_content.dart';
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
      body: Obx(() {
        if (controller.selectedTopTab.value == 0) {
          return const HistoryViewContent();
        } else if (controller.selectedTopTab.value == 1) {
          return const AlertsViewContent();
        } else if (controller.selectedTopTab.value == 2) {
          return const StatisticsViewContent();
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
    );
  }
}
