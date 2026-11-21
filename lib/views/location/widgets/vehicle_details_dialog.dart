import 'package:flutter/material.dart';
import 'package:airotrack_web/services/app_settings.dart';
import 'package:get/get.dart';

import '../../../controllers/location_controller.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import '../../../models/vehicle_model.dart';
import '../../tracking/vehicle_detail_map_view.dart';

void showVehicleDetailsDialog(BuildContext context, Vehicle vehicle) {
  showDialog(
    context: context,
    builder: (ctx) => VehicleDetailsDialog(vehicle: vehicle),
  );
}

class VehicleDetailsDialog extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailsDialog({super.key, required this.vehicle});

  void _prepareVehicle() {
    final detailCtrl = Get.isRegistered<VehicleDetailController>()
        ? Get.find<VehicleDetailController>()
        : Get.put(VehicleDetailController());
    detailCtrl.updateFromVehicle(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final status = evaluateVehicleStatus(vehicle);
    final statusColor = status.color;
    final plate = vehicle.plateNumber.isNotEmpty
        ? vehicle.plateNumber
        : vehicle.deviceId;

    final durationText = vehicle.statusDuration.isNotEmpty
        ? 'since ${vehicle.statusDuration}'
        : '';
    final statusDisplay = durationText.isNotEmpty
        ? '${status.label} $durationText'
        : status.label;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Top Header: Plate Number, Status Badge & Close Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFD0D5DD),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          plate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D2939),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF475467),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFEAECF0)),
            const SizedBox(height: 16),

            // Vehicle Details Key-Value Rows
            _buildDetailRow(
              icon: Icons.info_outline_rounded,
              label: 'Status & Duration',
              value: statusDisplay,
              valueColor: statusColor,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Device Time',
              value: vehicle.lastUpdated.isNotEmpty
                  ? AppSettings.to.anyTime(vehicle.lastUpdated)
                  : 'N/A',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: vehicle.locationLabel,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.power_settings_new_rounded,
              label: 'Engine Status',
              value: vehicle.isIgnitionOn ? 'On' : 'Off',
              valueColor: vehicle.isIgnitionOn
                  ? const Color(0xFF00A859)
                  : const Color(0xFFE53935),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.battery_charging_full_rounded,
              label: 'Voltage',
              value: '13.78 V',
            ),
            if (vehicle.speed.isNotEmpty && vehicle.speed != '0') ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.speed_rounded,
                label: 'Speed',
                value: AppSettings.to.units('${vehicle.speed} km/h'),
              ),
            ],

            const SizedBox(height: 22),
            const Divider(height: 1, color: Color(0xFFEAECF0)),
            const SizedBox(height: 18),

            // Action Buttons: Cancel, History, Track
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _prepareVehicle();
                      final detailCtrl =
                          Get.isRegistered<VehicleDetailController>()
                              ? Get.find<VehicleDetailController>()
                              : Get.put(VehicleDetailController());
                      detailCtrl.selectTab(0);
                      Get.to(() => const VehicleDetailMapView());
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: const Color(0xFF00A859),
                      side: const BorderSide(color: Color(0xFF00A859)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _prepareVehicle();
                      final detailCtrl =
                          Get.isRegistered<VehicleDetailController>()
                              ? Get.find<VehicleDetailController>()
                              : Get.put(VehicleDetailController());
                      detailCtrl.selectedTopTab.value = -1;
                      Get.to(() => const VehicleDetailMapView());
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text(
                      'Track',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF0077C5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1D2939),
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
