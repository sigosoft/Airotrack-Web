import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/vehicle_detail_controller.dart';
import '../../utils/custom_media_query.dart';
import 'widgets/tracking_map_container.dart';
import 'widgets/vehicle_info_sidebar.dart';

class VehicleDetailMapView extends StatelessWidget {
  const VehicleDetailMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller = Get.put(VehicleDetailController());
    final isMobile = CustomMediaQuery.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Vehicle Details Metrics Sidebar
          Obx(
            () => VehicleInfoSidebar(
              data: controller.vehicleDetail.value,
            ),
          ),

          // Right Interactive Map Container Area
          Expanded(
            child: Obx(
              () => TrackingMapContainer(
                selectedTab: controller.selectedTopTab.value,
                onTabSelected: controller.selectTab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
