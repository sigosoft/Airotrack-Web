import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import '../../../models/tracking_model.dart';
import '../vehicle_detail_map_view.dart';

class VehicleActionDialog extends StatelessWidget {
  final TrackingCardData data;

  const VehicleActionDialog({super.key, required this.data});

  void _prepareVehicle() {
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      final match = homeCtrl.vehicles.firstWhereOrNull(
        (v) => v.plateNumber == data.registrationNumber,
      );
      if (match != null) {
        final detailCtrl = Get.isRegistered<VehicleDetailController>()
            ? Get.find<VehicleDetailController>()
            : Get.put(VehicleDetailController());
        detailCtrl.updateFromVehicle(match);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with Vehicle Plate & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.registrationNumber,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Choose an action for this vehicle',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF344054),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Track Vehicle Option Card
            _buildOptionCard(
              context: context,
              icon: Icons.my_location_rounded,
              iconBgColor: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF00A3E0),
              title: 'Track Vehicle',
              subtitle: 'Live vehicle tracking & metrics details',
              onTap: () {
                Navigator.of(context).pop();
                _prepareVehicle();
                final detailCtrl = Get.isRegistered<VehicleDetailController>()
                    ? Get.find<VehicleDetailController>()
                    : Get.put(VehicleDetailController());
                detailCtrl.selectedTopTab.value = -1;
                Get.to(() => const VehicleDetailMapView());
              },
            ),

            const SizedBox(height: 12),

            // 3. See History Option Card
            _buildOptionCard(
              context: context,
              icon: Icons.history_rounded,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF00A859),
              title: 'See History',
              subtitle: 'Route playback, alerts & statistics',
              onTap: () {
                Navigator.of(context).pop();
                _prepareVehicle();
                final detailCtrl = Get.isRegistered<VehicleDetailController>()
                    ? Get.find<VehicleDetailController>()
                    : Get.put(VehicleDetailController());
                detailCtrl.selectTab(0);
                Get.to(() => const VehicleDetailMapView());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
