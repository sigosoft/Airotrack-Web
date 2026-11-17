import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/location_controller.dart';
import '../../../models/vehicle_model.dart';
import 'vehicle_details_dialog.dart';

class AiroMapWidget extends StatelessWidget {
  final LocationController controller;
  final ValueChanged<VehicleGroup>? onGroupTap;

  const AiroMapWidget({
    super.key,
    required this.controller,
    this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final style = controller.currentStyle.value;
      final traffic = controller.trafficEnabled.value;
      final tileUrl = style.tileUrl(traffic);
      final zoom = controller.currentZoomStep.value;
      final groups = controller.groupedVehicles(zoom);
      final selectedId = controller.selectedVehicleId.value;

      final initialCenter = controller.lastCenter ??
          (controller.mapVehicles.isNotEmpty
              ? LatLng(
                  controller.mapVehicles.first.latitude!,
                  controller.mapVehicles.first.longitude!,
                )
              : const LatLng(20.5937, 78.9629));

      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: controller.lastZoom,
          minZoom: 3.0,
          maxZoom: 19.0,
          onMapReady: controller.onMapReady,
          onPositionChanged: (position, hasGesture) {
            controller.onPositionChanged(position, hasGesture);
          },
        ),
        children: [
          TileLayer(
            key: ValueKey('$style|$traffic'),
            urlTemplate: tileUrl,
            userAgentPackageName: 'com.airotrack.app',
          ),
          MarkerLayer(
            markers: groups.map((g) {
              final anchor = g.anchor;
              final isGroup = g.vehicles.length > 1;
              final status = evaluateVehicleStatus(anchor);
              final isSelected = selectedId == anchor.deviceId;

              return Marker(
                point: LatLng(anchor.latitude!, anchor.longitude!),
                width: 140,
                height: 64,
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isGroup) {
                      onGroupTap?.call(g);
                    } else {
                      controller.selectVehicle(anchor);
                      showVehicleDetailsDialog(context, anchor);
                    }
                  },
                  child: _VehicleMarker(
                    vehicle: anchor,
                    groupCount: g.vehicles.length,
                    status: status,
                    isSelected: isSelected,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

class _VehicleMarker extends StatelessWidget {
  final Vehicle vehicle;
  final int groupCount;
  final VehicleMarkerStatus status;
  final bool isSelected;

  const _VehicleMarker({
    required this.vehicle,
    required this.groupCount,
    required this.status,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;
    final plate = vehicle.plateNumber.isNotEmpty
        ? vehicle.plateNumber
        : vehicle.deviceId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Plate Pill (+ Cluster Badge if multiple)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? const Color(0xFF0077C5) : statusColor,
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Color Indicator Dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  plate,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: const Color(0xFF1D2939),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (groupCount > 1) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077C5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${groupCount - 1}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Car Graphic with status color ring
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: statusColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            status.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Image.asset(
              status.fallbackAssetPath,
              color: status == VehicleMarkerStatus.running ||
                      status == VehicleMarkerStatus.stopped
                  ? null
                  : statusColor,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                AppAssets.carImage,
                width: 18,
                height: 18,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
