import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/configure_alerts_controller.dart';
import '../../../services/lookups_service.dart';
import '../../../utils/custom_media_query.dart';

/// Profile > Configure Alerts: pick a vehicle, tick the alerts it should
/// send, Submit. Built in the same style as the other profile panels.
class ConfigureAlertsContent extends StatelessWidget {
  const ConfigureAlertsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ConfigureAlertsController>()
        ? Get.find<ConfigureAlertsController>()
        : Get.put(ConfigureAlertsController());
    final isMobile = CustomMediaQuery.isMobile(context);

    final vehiclePanel = _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (v) => controller.searchQuery.value = v,
            style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
            decoration: InputDecoration(
              hintText: 'Search Vehicles',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF98A2B3),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFEAECF0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF00A3E0),
                  width: 1.5,
                ),
              ),
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF98A2B3),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.vehicles.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00A3E0)),
                );
              }
              final list = controller.filteredVehicles;
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'No vehicles found',
                    style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                  ),
                );
              }
              final selectedImei = controller.selectedVehicle.value?.imei;
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _vehicleTile(
                  list[i],
                  selected: list[i].imei == selectedImei,
                  onTap: () => controller.selectVehicle(list[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );

    final alertsPanel = _panel(
      child: Obx(() {
        final vehicle = controller.selectedVehicle.value;
        if (vehicle == null) {
          return const Center(
            child: Text(
              'Select a vehicle to configure its alerts',
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
          );
        }
        if (controller.isLoadingAlerts.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A3E0)),
          );
        }
        // Read the set so Obx rebuilds when a box is ticked.
        final ticked = controller.selectedAlerts.toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.vehicleNumber,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'IMEI: ${vehicle.imei}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            _checkRow(
              label: 'All Alerts',
              value: controller.allSelected,
              bold: true,
              onTap: controller.toggleAll,
            ),
            const Divider(height: 16, color: Color(0xFFEAECF0)),
            Expanded(
              child: ListView(
                children: controller.alertOptions
                    .map(
                      (o) => _checkRow(
                        label: o.label,
                        value: ticked.contains(o.key),
                        onTap: () => controller.toggleAlert(o.key),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: isMobile ? double.infinity : 340,
              height: 42,
              child: ElevatedButton(
                onPressed: controller.isSaving.value ? null : controller.save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3E0),
                  disabledBackgroundColor: const Color(0xFF7FD1EF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configure Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            // Side by side only when there is room for both panels.
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 700
                  ? Column(
                      children: [
                        SizedBox(height: 220, child: vehiclePanel),
                        const SizedBox(height: 14),
                        Expanded(child: alertsPanel),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 320, child: vehiclePanel),
                        const SizedBox(width: 20),
                        Expanded(child: alertsPanel),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: child,
    );
  }

  Widget _vehicleTile(
    VehicleOption v, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF00A3E0) : const Color(0xFFEAECF0),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              AppAssets.carImage,
              width: 18,
              height: 18,
              color: const Color(0xFF00A3E0),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.vehicleNumber,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  Text(
                    v.imei,
                    style: const TextStyle(
                      fontSize: 11,
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

  Widget _checkRow({
    required String label,
    required bool value,
    required VoidCallback onTap,
    bool bold = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF00A3E0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF344054),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
