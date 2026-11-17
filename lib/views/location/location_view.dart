import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../controllers/location_controller.dart';
import 'widgets/airo_map_widget.dart';
import 'widgets/vehicle_details_dialog.dart';

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  late final LocationController _controller;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<LocationController>()
        ? Get.find<LocationController>()
        : Get.put(LocationController());
    _controller.attachMap(_mapController);
  }

  @override
  void dispose() {
    _controller.detachMap(_mapController);
    _searchController.dispose();
    super.dispose();
  }

  void _showGroupSheet(BuildContext context, VehicleGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Parked Vehicles (${group.vehicles.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a vehicle to view details & tracking actions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEAECF0)),
                const SizedBox(height: 8),

                // Vehicle List in this cluster
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: group.vehicles.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: Color(0xFFF2F4F7),
                    ),
                    itemBuilder: (context, idx) {
                      final v = group.vehicles[idx];
                      final status = evaluateVehicleStatus(v);
                      final plate = v.plateNumber.isNotEmpty
                          ? v.plateNumber
                          : v.deviceId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: status.color.withValues(alpha: 0.4),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            AppAssets.carImage,
                            width: 20,
                            height: 20,
                            color: status.color,
                          ),
                        ),
                        title: Text(
                          plate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                        subtitle: Text(
                          '${status.label}${v.statusDuration.isNotEmpty ? " • ${v.statusDuration}" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: status.color,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF98A2B3),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _controller.selectVehicle(v);
                          showVehicleDetailsDialog(context, v);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    const filters = [
      'All',
      'Running',
      'Idle',
      'Stopped',
      'Expired',
      'Inactive',
      'No data',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Vehicle Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: filters.map((filter) {
                        return Obx(() {
                          final isSelected =
                              _controller.selectedFilter.value.toLowerCase() ==
                              filter.toLowerCase();
                          final count = _controller.countFor(filter);

                          Color dotColor = const Color(0xFF0077C5);
                          if (filter == 'Running') {
                            dotColor = const Color(0xFF00C853);
                          } else if (filter == 'Idle') {
                            dotColor = const Color(0xFFFFD600);
                          } else if (filter == 'Stopped') {
                            dotColor = const Color(0xFFFF3D00);
                          } else if (filter == 'Expired') {
                            dotColor = const Color(0xFFFF9100);
                          } else if (filter == 'Inactive') {
                            dotColor = const Color(0xFF2196F3);
                          } else if (filter == 'No data') {
                            dotColor = const Color(0xFF9E9E9E);
                          }

                          return InkWell(
                            onTap: () {
                              _controller.setFilter(filter);
                              Navigator.of(ctx).pop();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE0F2FE)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF0077C5)
                                            : const Color(0xFF344054),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0077C5)
                                          : const Color(0xFFF2F4F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF475467),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Full Screen Interactive Map Engine
          Positioned.fill(
            child: AiroMapWidget(
              controller: _controller,
              onGroupTap: (g) => _showGroupSheet(context, g),
            ),
          ),

          // 2. Top Bar & Floating Controls Layer
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top-Left Floating Controls: Map Style & Live Traffic
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFEAECF0), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Style Cycler (Streets -> Satellite -> Outdoors -> Streets)
                      Obx(() {
                        final style = _controller.currentStyle.value;
                        return Tooltip(
                          message: 'Map Style: ${style.displayName}',
                          child: InkWell(
                            onTap: _controller.cycleMapStyle,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.layers_rounded,
                                    size: 18,
                                    color: Color(0xFF344054),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    style.displayName,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF344054),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFFEAECF0),
                      ),
                      // Live Traffic Toggle
                      Obx(() {
                        final traffic = _controller.trafficEnabled.value;
                        return Tooltip(
                          message: traffic ? 'Disable Traffic' : 'Enable Traffic',
                          child: InkWell(
                            onTap: _controller.toggleTraffic,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(10),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: traffic
                                    ? const Color(0xFFE0F2FE)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.traffic_rounded,
                                    size: 18,
                                    color: traffic
                                        ? AppColors.primary
                                        : const Color(0xFF667085),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Traffic',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: traffic
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: traffic
                                          ? AppColors.primary
                                          : const Color(0xFF344054),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const Spacer(),

                // Search Bar or Search Toggle
                if (_isSearchOpen)
                  Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFEAECF0), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF667085),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Search plate, IMEI...',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF98A2B3),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 13),
                            onChanged: _controller.setSearchQuery,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _isSearchOpen = false);
                            _searchController.clear();
                            _controller.setSearchQuery('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFEAECF0), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF344054),
                      ),
                      tooltip: 'Search Vehicles',
                      onPressed: () => setState(() => _isSearchOpen = true),
                    ),
                  ),

                // Top-Right Floating Controls: Filter & Fit All
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFEAECF0), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Filter Button with Badge
                      Obx(() {
                        final filter = _controller.selectedFilter.value;
                        final count = _controller.countFor(filter);
                        final isFiltered = filter != 'All';

                        return InkWell(
                          onTap: () => _showFilterSheet(context),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  size: 18,
                                  color: isFiltered
                                      ? AppColors.primary
                                      : const Color(0xFF344054),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$filter ($count)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isFiltered
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isFiltered
                                        ? AppColors.primary
                                        : const Color(0xFF344054),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFFEAECF0),
                      ),
                      // Fit All / Recenter
                      Tooltip(
                        message: 'Fit All Vehicles',
                        child: InkWell(
                          onTap: _controller.fitAll,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Icon(
                              Icons.filter_center_focus_rounded,
                              size: 18,
                              color: Color(0xFF344054),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom-Right Zoom In / Zoom Out Controls
          Positioned(
            bottom: 24,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    color: const Color(0xFF344054),
                    tooltip: 'Zoom In',
                    onPressed: _controller.zoomIn,
                  ),
                  Container(
                    height: 1,
                    width: 24,
                    color: const Color(0xFFEAECF0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 20),
                    color: const Color(0xFF344054),
                    tooltip: 'Zoom Out',
                    onPressed: _controller.zoomOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
