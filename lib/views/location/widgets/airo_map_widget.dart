import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/location_controller.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/app_settings.dart';
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
              : LocationController.defaultCenter);

      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: controller.lastZoom,
          minZoom: 3.0,
          maxZoom: 19.0,
          onMapReady: controller.onMapReady,
          // Rotation locked, as on the mobile map.
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
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
              final isSelected =
                  g.vehicles.any((v) => v.deviceId == selectedId);
              final scale = AppSettings.to.iconScale;

              // Mobile marker box: 180 x (38 + 52 x icon size).
              return Marker(
                point: LatLng(anchor.latitude!, anchor.longitude!),
                width: 180,
                height: 38 + 52 * scale,
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
    // Same marker as the mobile Locations map: a black pill (blue when
    // selected) with the white plate and a "+N" badge, the status car below.
    final plate = vehicle.plateNumber.isNotEmpty
        ? vehicle.plateNumber
        : vehicle.deviceId;
    final extra = groupCount - 1;
    const blue = Color(0xFF009FE3);
    final carPx = (isSelected ? 52.0 : 44.0) * AppSettings.to.iconScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? blue : Colors.black,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  plate.isEmpty ? '—' : plate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (extra > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      color: isSelected ? blue : Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Image.asset(
          status.assetPath,
          width: carPx,
          height: carPx,
          errorBuilder: (_, _, _) => Image.asset(
            status.fallbackAssetPath,
            width: carPx,
            height: carPx,
            errorBuilder: (_, _, _) => Image.asset(
              AppAssets.carImage,
              width: carPx * 0.6,
              height: carPx * 0.6,
              color: status.color,
            ),
          ),
        ),
      ],
    );
  }
}
