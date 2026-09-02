import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import 'map_bottom_action_cards.dart';

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

    // Route points in Kalamassery / Kochi matching reference image
    final routePoints = [
      const LatLng(10.052, 76.325),
      const LatLng(10.048, 76.322),
      const LatLng(10.040, 76.315),
      const LatLng(10.038, 76.318),
      const LatLng(10.032, 76.312),
      const LatLng(10.030, 76.328),
      const LatLng(10.026, 76.335),
    ];

    final currentVehiclePosition = routePoints.first;
    final startFlagPosition = routePoints.last;

    return Column(
      children: [
        // 1. Top Header Bar (History, Alerts, Statistics)
        Container(
          height: 48,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTopTabItem('History', Icons.access_time_rounded, 0),
              _buildTopTabItem('Alerts', Icons.notifications_none_rounded, 1),
              _buildTopTabItem('Statistics', Icons.analytics_outlined, 2),
            ],
          ),
        ),

        // 2. Interactive Map Container Area
        Expanded(
          child: Stack(
            children: [
              // OpenStreetMap Tile Canvas Layer
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(10.038, 76.325),
                  initialZoom: 13.5,
                  onTap: (tapPosition, point) {
                    controller.toggleMapDialog();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.airotrack.app',
                  ),
                  // Vehicle Route Polyline (Clickable to show dialogue box)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: Colors.black,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                  // Vehicle & Flag PNG Markers
                  MarkerLayer(
                    markers: [
                      // Current Vehicle Marker (Green Car.png)
                      Marker(
                        point: currentVehiclePosition,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: controller.toggleMapDialog,
                          child: Image.asset(
                            AppAssets.greenCar,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Start Flag Marker (Flag.png)
                      Marker(
                        point: startFlagPosition,
                        width: 34,
                        height: 34,
                        child: GestureDetector(
                          onTap: controller.toggleMapDialog,
                          child: Image.asset(
                            AppAssets.flag,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Route Info Popup Dialogue Box matching reference screenshot
              Obx(() {
                if (!controller.isMapDialogVisible.value) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: 180,
                  bottom: 120,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 310,
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
                          // Header with Close 'X' Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox.shrink(),
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
                          const SizedBox(height: 2),

                          // Table Info Rows
                          _buildDialogRow(
                            'Arrival Time:',
                            '08 Oct 2025 11:00 AM',
                          ),
                          const SizedBox(height: 6),
                          _buildDialogRow(
                            'Departure Time:',
                            '08 Oct 2025 12:30 PM',
                          ),
                          const SizedBox(height: 6),
                          _buildDialogRow('Duration:', '01h 30m'),
                          const SizedBox(height: 6),
                          _buildDialogRow(
                            'Address:',
                            'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Right Map Floating Action Toolbar (Separate Individual Floating Cards)
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: const [
                    _SeperateMapIconButton(icon: Icons.map_outlined),
                    _SeperateMapIconButton(
                      icon: Icons.lock_open_rounded,
                      color: Color(0xFF00A859),
                    ),
                    _SeperateMapIconButton(text: 'P', color: Color(0xFFE53935)),
                    _SeperateMapIconButton(icon: Icons.videocam_outlined),
                    _SeperateMapIconButton(
                      icon: Icons.alt_route_rounded,
                      color: Color(0xFF00A859),
                    ),
                    _SeperateMapIconButton(icon: Icons.my_location_rounded),
                    _SeperateMapIconButton(icon: Icons.person_outline_rounded),
                    _SeperateMapIconButton(
                      icon: Icons.person_pin_circle_outlined,
                    ),
                    _SeperateMapIconButton(icon: Icons.explore_outlined),
                    SizedBox(height: 4),
                    _SeperateMapIconButton(icon: Icons.add_rounded),
                    _SeperateMapIconButton(icon: Icons.remove_rounded),
                  ],
                ),
              ),

              // Bottom Quick Action Cards Row (Overlay over Map)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: const MapBottomActionCards(),
              ),
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
