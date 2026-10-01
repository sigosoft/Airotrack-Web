import 'package:airotrack_web/utils/custom_media_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../config/api_config.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import 'map_bottom_action_cards.dart';
import 'top_view_car.dart';

class TrackingMapContainer extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  const TrackingMapContainer({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller =
        Get.find<VehicleDetailController>();
    final isMobile = CustomMediaQuery.isMobile(context);

    return Column(
      children: [
        // 1. Top Header Bar (History, Alerts, Statistics)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 450;

            return Container(
              height: 48,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isNarrow
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTopTabItem(
                          'History',
                          Icons.access_time_rounded,
                          0,
                        ),
                        _buildTopTabItem(
                          'Alerts',
                          Icons.notifications_none_rounded,
                          1,
                        ),
                        _buildTopTabItem(
                          'Statistics',
                          Icons.analytics_outlined,
                          2,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTopTabItem(
                          'History',
                          Icons.access_time_rounded,
                          0,
                        ),
                        _buildTopTabItem(
                          'Alerts',
                          Icons.notifications_none_rounded,
                          1,
                        ),
                        _buildTopTabItem(
                          'Statistics',
                          Icons.analytics_outlined,
                          2,
                        ),
                      ],
                    ),
            );
          },
        ),

        // 2. Interactive Map Container Area
        Expanded(
          child: Stack(
            children: [
              // Dynamic Map Canvas Layer
              FlutterMap(
                mapController: controller.liveMapController,
                options: MapOptions(
                  initialCenter:
                      (controller.vehicleDetail.value.latitude != null &&
                          controller.vehicleDetail.value.longitude != null &&
                          controller.vehicleDetail.value.latitude != 0.0)
                      ? LatLng(
                          controller.vehicleDetail.value.latitude!,
                          controller.vehicleDetail.value.longitude!,
                        )
                      : const LatLng(10.038, 76.325),
                  initialZoom: 16.0,
                  onPositionChanged: (camera, hasGesture) {
                    controller.onLiveCameraChanged(camera, hasGesture);
                  },
                  onTap: (tapPosition, point) {
                    controller.toggleMapDialog();
                  },
                ),
                children: [
                  Obx(
                    () => TileLayer(
                      key: ValueKey(controller.mapLayer.value),
                      urlTemplate: controller.tileUrlFor(
                        ApiConfig.googleMapTileUrl,
                      ),
                      subdomains: controller.tileSubdomainsFor(
                        ApiConfig.googleMapTileUrl,
                        ApiConfig.googleMapSubdomains,
                      ),
                      userAgentPackageName: 'com.airotrack.app',
                    ),
                  ),
                  // Today's travelled route (route button)
                  Obx(
                    () =>
                        controller.showLiveRoute.value &&
                            controller.liveTodayRoute.length >= 2
                        ? PolylineLayer(
                            polylines: [
                              Polyline(
                                points: controller.liveTodayRoute.toList(),
                                color: const Color(0xFF4FC3F7),
                                strokeWidth: 3.5,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Parking stops (P button)
                  Obx(
                    () => controller.showLiveStops.value
                        ? MarkerLayer(
                            markers: [
                              for (final stop in controller.liveStops)
                                Marker(
                                  point: stop['point'] as LatLng,
                                  width: 24,
                                  height: 24,
                                  child: GestureDetector(
                                    onTap: () => controller.onLiveStopTap(stop),
                                    child: const _ParkingBadge(
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Live Vehicle Marker
                  Obx(() {
                    final detail = controller.vehicleDetail.value;
                    final lat = detail.latitude ?? 0.0;
                    final lng = detail.longitude ?? 0.0;
                    final currentVehiclePosition = (lat != 0.0 && lng != 0.0)
                        ? LatLng(lat, lng)
                        : const LatLng(10.038, 76.325);

                    final vehiclePos =
                        controller.liveMarkerPosition.value ??
                        currentVehiclePosition;
                    // Read the bearing so Obx rebuilds when the heading changes.
                    controller.liveMarkerBearing.value;

                    return MarkerLayer(
                      markers: [
                        // Current Vehicle Marker: front always points in the
                        // direction of travel (a stopped car keeps its last
                        // heading instead of snapping sideways).
                        Marker(
                          point: vehiclePos,
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: controller.toggleMapDialog,
                            child: Transform.rotate(
                              angle: controller.liveTopViewRotationRad,
                              child: const Center(child: TopViewCar()),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              // Route Info Popup Dialogue Box displaying dynamic vehicle details
              Obx(() {
                if (!controller.isMapDialogVisible.value) {
                  return const SizedBox.shrink();
                }

                final detail = controller.vehicleDetail.value;

                // Keep the dialog fully visible and its close button reachable.
                // On mobile with the sheet open, the sheet can be dragged up
                // over the map, so the dialog sits at the TOP of the map.
                final panelOpen = controller.isBottomPanelVisible.value;
                final mobileTop = isMobile && panelOpen;
                final double? dialogBottom = mobileTop
                    ? null
                    : (panelOpen ? 200.0 : 70.0);

                return Positioned(
                  left: isMobile ? 12 : 180,
                  right: isMobile ? 12 : null,
                  top: mobileTop ? 8 : null,
                  bottom: dialogBottom,
                  // Taps on the dialog stay on the dialog (never reach the map).
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: isMobile ? null : 310,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Vehicle Number & Close 'X' Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  detail.vehicleNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D2939),
                                  ),
                                ),
                                InkWell(
                                  onTap: controller.hideMapDialog,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
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
                            const SizedBox(height: 8),

                            // Table Dynamic Info Rows
                            _buildDialogRow(
                              'Device Time:',
                              detail.deviceTime.isNotEmpty
                                  ? detail.deviceTime
                                  : 'N/A',
                            ),
                            const SizedBox(height: 6),
                            _buildDialogRow(
                              'Server Time:',
                              detail.serverTime.isNotEmpty
                                  ? detail.serverTime
                                  : 'N/A',
                            ),
                            const SizedBox(height: 6),
                            _buildDialogRow(
                              'Duration:',
                              controller.liveDialogDuration,
                            ),
                            const SizedBox(height: 6),
                            _buildDialogRow(
                              'Address:',
                              detail.address.isNotEmpty
                                  ? detail.address
                                  : 'Location fetching...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Right Map Floating Action Toolbar (Separate Individual Floating Cards)
              Positioned(
                top: 16,
                right: 16,
                bottom: 130,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _SeperateMapIconButton(
                        icon: Icons.map_outlined,
                        onTap: controller.cycleMapLayer,
                      ),
                      _SeperateMapIconButton(
                        icon: Icons.lock_open_rounded,
                        color: const Color(0xFF00A859),
                        onTap: controller.toggleLiveLock,
                      ),
                      _SeperateMapIconButton(
                        text: 'P',
                        color: const Color(0xFFE53935),
                        onTap: controller.toggleLiveStops,
                      ),
                      // Hidden until a dashcam / video API is available.
                      const Visibility(
                        visible: false,
                        child: _SeperateMapIconButton(
                          icon: Icons.videocam_outlined,
                        ),
                      ),
                      _SeperateMapIconButton(
                        icon: Icons.alt_route_rounded,
                        color: const Color(0xFF00A859),
                        onTap: controller.toggleLiveRoute,
                      ),
                      _SeperateMapIconButton(
                        icon: Icons.my_location_rounded,
                        onTap: controller.recenterLiveMap,
                      ),
                      // Hidden until driver details / device location exist.
                      const Visibility(
                        visible: false,
                        child: _SeperateMapIconButton(
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const Visibility(
                        visible: false,
                        child: _SeperateMapIconButton(
                          icon: Icons.person_pin_circle_outlined,
                        ),
                      ),
                      _SeperateMapIconButton(
                        icon: Icons.explore_outlined,
                        onTap: controller.resetLiveNorth,
                      ),
                      const SizedBox(height: 4),
                      _SeperateMapIconButton(
                        icon: Icons.add_rounded,
                        onTap: controller.zoomInLiveMap,
                      ),
                      _SeperateMapIconButton(
                        icon: Icons.remove_rounded,
                        onTap: controller.zoomOutLiveMap,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Quick Action Cards Row (Overlay over Map) with a close
              // button; when closed, a "Show options" button brings it back.
              Obx(() {
                if (controller.isBottomPanelVisible.value) {
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMobile)
                          _PanelToggleButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            tooltip: 'Hide options',
                            onTap: controller.hideBottomPanel,
                          ),
                        if (!isMobile) const SizedBox(height: 6),
                        const MapBottomActionCards(),
                      ],
                    ),
                  );
                }
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: _ShowOptionsPill(onTap: controller.showBottomPanel),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopTabItem(String title, IconData icon, int index) {
    final isSelected = selectedTab == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? const Color(0xFF0288D1)
                : const Color(0xFF344054),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0288D1)
                  : const Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475467),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small round button used to hide the bottom panel.
class _PanelToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _PanelToggleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF344054)),
        ),
      ),
    );
  }
}

/// Floating pill shown when the bottom panel is closed.
class _ShowOptionsPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowOptionsPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 18,
                color: Color(0xFF0288D1),
              ),
              SizedBox(width: 4),
              Text(
                'Show options',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0288D1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small square "P" marker for a parking stop.
class _ParkingBadge extends StatelessWidget {
  final Color color;
  const _ParkingBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4), // square P box
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
      ),
      child: const Text(
        'P',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Separate Floating Square Card for each Map Action Icon
class _SeperateMapIconButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final Color? color;
  final VoidCallback? onTap;

  const _SeperateMapIconButton({this.icon, this.text, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(bottom: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEAECF0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: text != null
            ? Text(
                text!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color ?? const Color(0xFF344054),
                ),
              )
            : Icon(icon, size: 16, color: color ?? const Color(0xFF344054)),
      ),
    );
  }
}
