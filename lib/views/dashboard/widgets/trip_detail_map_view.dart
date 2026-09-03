import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/vehicle_detail_controller.dart';

class TripDetailMapView extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const TripDetailMapView({
    super.key,
    this.reportData,
  });

  @override
  State<TripDetailMapView> createState() => _TripDetailMapViewState();
}

class _TripDetailMapViewState extends State<TripDetailMapView> {
  final routePoints = [
    const LatLng(10.035, 76.308),
    const LatLng(10.033, 76.315),
    const LatLng(10.035, 76.328),
    const LatLng(10.042, 76.335),
  ];

  @override
  Widget build(BuildContext context) {
    final vehicleNumber = widget.reportData?['vehicle'] ?? 'KL 07 D 0518';
    final VehicleDetailController controller = Get.put(VehicleDetailController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Navigation Header Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
              ),
            ),
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
                Obx(() => _buildDatePickerBox(controller.startDateStr.value)),
                const SizedBox(width: 12),
                Obx(() => _buildDatePickerBox(controller.endDateStr.value)),
              ],
            ),
          ),

          // 2. Main Area (Left Map + Right Trip Details Sidebar)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Map Area
                Expanded(
                  child: Stack(
                    children: [
                      // OpenStreetMap Canvas
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: const LatLng(10.038, 76.325),
                          initialZoom: 13.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.airotrack.app',
                          ),
                          // Route Black Polyline
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
                  ),
                ),

                // Right Trip Details Sidebar
                Container(
                  width: 340,
                  color: const Color(0xFFF4F6F9),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top 3 Metric Cards Row (0 Kmph, 00:00:00, 12.5 Km)
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.dashboard_outlined,
                                value: '0',
                                unit: 'Kmph',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.access_time_rounded,
                                value: '00:00:00',
                                unit: '',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.speed_rounded,
                                value: '12.5',
                                unit: 'Km',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 2. Playback Bar Card (Play, Slider, 1x, Replay, Tune)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEAECF0),
                              width: 1,
                            ),
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
                                      inactiveTrackColor: const Color(
                                        0xFFE4E7EC,
                                      ),
                                      thumbColor: const Color(0xFF0288D1),
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
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

                        // 3. Trip / Stop Item Card (Red Stop Badge)
                        _buildTripDetailCard(
                          badgeLabel: 'Stop',
                          badgeBgColor: const Color(0xFFFEE4E2),
                          badgeTextColor: const Color(0xFFF04438),
                        ),
                      ],
                    ),
                  ),
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
              const Text(
                '00.00 Km',
                style: TextStyle(
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
              const Text(
                '00.00 Km',
                style: TextStyle(
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
            time: '08 Oct 2025, 12:04:32 AM',
            showLineBelow: true,
          ),
          _buildTimelineStep(
            icon: Icons.access_time_rounded,
            title: 'Duration',
            time: '09h 33m 13s',
            showLineBelow: true,
          ),
          _buildTimelineStep(
            icon: Icons.stop_rounded,
            title: 'End',
            time: '08 Oct 2025, 11:01:30 PM',
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
