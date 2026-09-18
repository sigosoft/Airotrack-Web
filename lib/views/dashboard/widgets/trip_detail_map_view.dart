import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/vehicle_detail_controller.dart';
import '../../../utils/custom_media_query.dart';

class TripDetailMapView extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const TripDetailMapView({super.key, this.reportData});

  @override
  State<TripDetailMapView> createState() => _TripDetailMapViewState();
}

class _TripDetailMapViewState extends State<TripDetailMapView> {
  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  @override
  Widget build(BuildContext context) {
    final vehicleNumber = widget.reportData?['vehicle'] ??
        widget.reportData?['vehicle_number'] ??
        widget.reportData?['plate_number'] ??
        'Vehicle';

    final rawStartLat = widget.reportData?['start_latitude'] ??
        widget.reportData?['start_lat'] ??
        widget.reportData?['from_latitude'] ??
        widget.reportData?['from_lat'] ??
        widget.reportData?['latitude'] ??
        widget.reportData?['lat'];
    final rawStartLng = widget.reportData?['start_longitude'] ??
        widget.reportData?['start_lng'] ??
        widget.reportData?['from_longitude'] ??
        widget.reportData?['from_lng'] ??
        widget.reportData?['longitude'] ??
        widget.reportData?['lng'];
    final rawEndLat = widget.reportData?['end_latitude'] ??
        widget.reportData?['end_lat'] ??
        widget.reportData?['to_latitude'] ??
        widget.reportData?['to_lat'];
    final rawEndLng = widget.reportData?['end_longitude'] ??
        widget.reportData?['end_lng'] ??
        widget.reportData?['to_longitude'] ??
        widget.reportData?['to_lng'];

    final startLat = _parseDouble(rawStartLat);
    final startLng = _parseDouble(rawStartLng);
    final endLat = _parseDouble(rawEndLat);
    final endLng = _parseDouble(rawEndLng);

    List<LatLng> routePoints = [];
    if (widget.reportData?['route'] is List) {
      for (var pt in widget.reportData!['route']) {
        if (pt is Map && pt['lat'] != null && pt['lng'] != null) {
          final lat = _parseDouble(pt['lat']);
          final lng = _parseDouble(pt['lng']);
          if (lat != null && lng != null) routePoints.add(LatLng(lat, lng));
        }
      }
    }
    if (routePoints.isEmpty && startLat != null && startLng != null) {
      routePoints.add(LatLng(startLat, startLng));
      if (endLat != null && endLng != null) {
        routePoints.add(LatLng(endLat, endLng));
      }
    }

    final initialCenter = routePoints.isNotEmpty
        ? routePoints.first
        : const LatLng(10.038, 76.325);

    final speedVal = widget.reportData?['max_speed']?.toString() ??
        widget.reportData?['speed']?.toString() ??
        '0';
    final durationVal = widget.reportData?['duration']?.toString() ??
        widget.reportData?['trip_duration']?.toString() ??
        '00:00:00';
    final distanceVal = widget.reportData?['distance']?.toString() ??
        widget.reportData?['trip_distance']?.toString() ??
        '0.0';
    final startTimeStr = widget.reportData?['startTime']?.toString() ??
        widget.reportData?['start_time']?.toString() ??
        widget.reportData?['startLocation']?.toString() ??
        '-';
    final endTimeStr = widget.reportData?['endTime']?.toString() ??
        widget.reportData?['end_time']?.toString() ??
        widget.reportData?['endLocation']?.toString() ??
        '-';

    final VehicleDetailController controller = Get.put(
      VehicleDetailController(),
    );
    final isMobile = CustomMediaQuery.isMobile(context);

    Widget buildMapStack() {
      return Stack(
        children: [
          // OpenStreetMap Canvas
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: routePoints.isNotEmpty ? 13.5 : 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.airotrack.app',
              ),
              // Route Black Polyline
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.black,
                      strokeWidth: 3.5,
                    ),
                  ],
                ),
              // Red Flag (Start) & Green Flag (End) Markers
              if (routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    // Start Red Flag Marker
                    Marker(
                      point: routePoints.first,
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFFE53935),
                        size: 32,
                      ),
                    ),
                    // End Green Flag Marker
                    if (routePoints.length > 1)
                      Marker(
                        point: routePoints.last,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFF00A859),
                          size: 32,
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Right Floating Action Map Toolbar
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: const [
                _MapIconButton(icon: Icons.map_outlined),
                _MapIconButton(icon: Icons.location_on_outlined),
                _MapIconButton(text: 'P', color: Color(0xFF00A859)),
                _MapIconButton(icon: Icons.my_location_rounded),
              ],
            ),
          ),

          // Zoom Buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: const [
                _MapIconButton(icon: Icons.add_rounded),
                _MapIconButton(icon: Icons.remove_rounded),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildTripSidebar() {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top 3 Metric Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.dashboard_outlined,
                    value: speedVal,
                    unit: 'Kmph',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.access_time_rounded,
                    value: durationVal,
                    unit: '',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.speed_rounded,
                    value: distanceVal,
                    unit: distanceVal.toLowerCase().contains('km') ? '' : 'Km',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Playback Bar Card (Play, Slider, 1x, Replay, Tune)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAECF0), width: 1),
              ),
              child: Obx(
                () => Row(
                  children: [
                    // Play / Pause circular button
                    InkWell(
                      onTap: controller.togglePlay,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0288D1),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          controller.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 16,
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Progress Slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          activeTrackColor: const Color(0xFF0288D1),
                          inactiveTrackColor: const Color(0xFFE4E7EC),
                          thumbColor: const Color(0xFF0288D1),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: controller.playbackProgress.value,
                          onChanged: (val) {
                            controller.playbackProgress.value = val;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 1x Speed Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '1x',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Replay Icon
                    const Icon(
                      Icons.replay_rounded,
                      size: 16,
                      color: Color(0xFF0288D1),
                    ),
                    const SizedBox(width: 6),

                    // Settings / Tune Icon
                    const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Color(0xFF0288D1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. History Trip / Stop Item Card
            _buildTripDetailCard(
              badgeLabel: 'Trip',
              badgeBgColor: const Color(0xFFD1FADF),
              badgeTextColor: const Color(0xFF12B76A),
              distance: distanceVal.toLowerCase().contains('km') ? distanceVal : '$distanceVal Km',
              maxSpeed: speedVal.toLowerCase().contains('km') ? speedVal : '$speedVal Kmph',
              startTime: startTimeStr,
              duration: durationVal,
              endTime: endTimeStr,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Navigation Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
              ),
            ),
            child: isMobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Get.back();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vehicleNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => _buildDatePickerBox(
                                controller.startDateStr.value,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(
                              () => _buildDatePickerBox(
                                controller.endDateStr.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        // Back Arrow Button
                        InkWell(
                          onTap: () {
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Vehicle Registration Title
                        Text(
                          vehicleNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),

                        const Spacer(),

                        // Date Range Pickers (Start Date & End Date)
                        Obx(
                          () => _buildDatePickerBox(
                            controller.startDateStr.value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(
                          () =>
                              _buildDatePickerBox(controller.endDateStr.value),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2. Main Area (Left Map + Right Trip Details Sidebar)
          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      // Top Map View
                      SizedBox(height: 360, child: buildMapStack()),
                      // Bottom Trip Details Sidebar
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFFF4F6F9),
                          child: buildTripSidebar(),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Map Area
                      Expanded(child: buildMapStack()),

                      // Right Trip Details Sidebar
                      Container(
                        width: 340,
                        color: const Color(0xFFF4F6F9),
                        child: buildTripSidebar(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerBox(String dateStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 15,
            color: Color(0xFF667085),
          ),
          const SizedBox(width: 6),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE53935)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
            )
          else
            const SizedBox(height: 13),
        ],
      ),
    );
  }

  Widget _buildTripDetailCard({
    required String badgeLabel,
    required Color badgeBgColor,
    required Color badgeTextColor,
    String? distance,
    String? maxSpeed,
    String? startTime,
    String? duration,
    String? endTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Right Badge
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                ),
              ),
            ),
          ),

          // Metric Stats Row (Distance & Max Speed)
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                size: 14,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 4),
              const Text(
                'Distance',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF667085)),
              ),
              const SizedBox(width: 6),
              Text(
                distance ?? '0.00 Km',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2939),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.speed_rounded,
                size: 14,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 4),
              const Text(
                'Max Speed',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF667085)),
              ),
              const SizedBox(width: 6),
              Text(
                maxSpeed ?? '0.00 Kmph',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2939),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const _HorizontalDashedLine(),
          const SizedBox(height: 10),

          // Vertical Timeline Stepper
          _buildTimelineStep(
            icon: Icons.play_arrow_outlined,
            title: 'Start',
            time: startTime ?? '-',
            showLineBelow: true,
          ),
          _buildTimelineStep(
            icon: Icons.access_time_rounded,
            title: 'Duration',
            time: duration ?? '-',
            showLineBelow: true,
          ),
          _buildTimelineStep(
            icon: Icons.stop_rounded,
            title: 'End',
            time: endTime ?? '-',
            showLineBelow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String time,
    required bool showLineBelow,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF98A2B3), width: 1.2),
              ),
              child: Icon(icon, size: 11, color: const Color(0xFF667085)),
            ),
            if (showLineBelow)
              Container(width: 1, height: 20, color: const Color(0xFFD0D5DD)),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final Color? color;

  const _MapIconButton({this.icon, this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF344054),
              ),
            )
          : Icon(icon, size: 15, color: color ?? const Color(0xFF344054)),
    );
  }
}

class _HorizontalDashedLine extends StatelessWidget {
  const _HorizontalDashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 3.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFD0D5DD)),
              ),
            );
          }),
        );
      },
    );
  }
}
