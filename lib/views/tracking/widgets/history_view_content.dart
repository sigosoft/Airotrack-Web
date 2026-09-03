import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/vehicle_detail_controller.dart';

class HistoryViewContent extends StatelessWidget {
  const HistoryViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller =
        Get.find<VehicleDetailController>();

    // Kalamassery / Kochi route points for History view matching reference screenshot
    final routePoints = [
      const LatLng(10.052, 76.325),
      const LatLng(10.048, 76.322),
      const LatLng(10.040, 76.315),
      const LatLng(10.038, 76.318),
      const LatLng(10.032, 76.312),
      const LatLng(10.030, 76.328),
      const LatLng(10.026, 76.335),
    ];

    final nodePoints = [
      const LatLng(10.040, 76.324),
      const LatLng(10.044, 76.316),
      const LatLng(10.034, 76.310),
    ];

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
                    if (Navigator.canPop(context)) {
                      Get.back();
                    } else {
                      controller.selectTab(-1);
                    }
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

                // Navigation Header Tabs (History, Alerts, Statistics)
                _buildHeaderTab(
                  'History',
                  Icons.access_time_rounded,
                  0,
                  controller,
                ),
                const SizedBox(width: 24),
                _buildHeaderTab(
                  'Alerts',
                  Icons.notifications_none_rounded,
                  1,
                  controller,
                ),
                const SizedBox(width: 24),
                _buildHeaderTab(
                  'Statistics',
                  Icons.analytics_outlined,
                  2,
                  controller,
                ),

                const Spacer(),

                // Date Range Pickers (Start Date & End Date)
                Obx(() => _buildDatePickerBox(controller.startDateStr.value)),
                const SizedBox(width: 12),
                Obx(() => _buildDatePickerBox(controller.endDateStr.value)),
                const SizedBox(width: 12),

                // Filter Sliders Icon Button
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFD0D5DD),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: Color(0xFF344054),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Area (Left Map + Right History Sidebar)
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
                          onTap: (tapPosition, point) {
                            controller.toggleHistoryMapDialog();
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          // Numbered Route Nodes (1, 2, 3)
                          MarkerLayer(
                            markers: [
                              _buildNodeMarker(nodePoints[0], '1', controller),
                              _buildNodeMarker(nodePoints[1], '2', controller),
                              _buildNodeMarker(nodePoints[2], '3', controller),
                            ],
                          ),
                        ],
                      ),

                      // Route Node Info Popup Dialog (Matching Reference Screenshot 2)
                      Obx(() {
                        if (!controller.isHistoryMapDialogVisible.value) {
                          return const SizedBox.shrink();
                        }

                        return Positioned(
                          left: 180,
                          bottom: 140,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 310,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
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
                                  // Close 'X' button
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: InkWell(
                                      onTap: controller.hideHistoryMapDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF2F4F7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Color(0xFF344054),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  _buildDialogRow(
                                    'Arrival Time:',
                                    '08 Oct 2025 11:00 AM',
                                  ),
                                  const SizedBox(height: 5),
                                  _buildDialogRow(
                                    'Departure Time:',
                                    '08 Oct 2025 12:30 PM',
                                  ),
                                  const SizedBox(height: 5),
                                  _buildDialogRow('Duration:', '01h 30m'),
                                  const SizedBox(height: 5),
                                  _buildDialogRow(
                                    'Address:',
                                    'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Right Floating Action Map Toolbar
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: const [
                            _HistoryMapIconButton(icon: Icons.map_outlined),
                            _HistoryMapIconButton(
                              icon: Icons.location_on_outlined,
                            ),
                            _HistoryMapIconButton(
                              text: 'P',
                              color: Color(0xFF00A859),
                            ),
                            _HistoryMapIconButton(
                              icon: Icons.my_location_rounded,
                            ),
                          ],
                        ),
                      ),

                      // Zoom Buttons
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Column(
                          children: const [
                            _HistoryMapIconButton(icon: Icons.add_rounded),
                            _HistoryMapIconButton(icon: Icons.remove_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right History Details Sidebar
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

                        // 3. History Trip / Stop Item Card 1 (Red Stop Badge)
                        _buildHistoryTripCard(
                          badgeLabel: 'Stop',
                          badgeBgColor: const Color(0xFFFEE4E2),
                          badgeTextColor: const Color(0xFFF04438),
                        ),

                        const SizedBox(height: 12),

                        // 4. History Trip / Stop Item Card 2 (Green Stop Badge)
                        _buildHistoryTripCard(
                          badgeLabel: 'Stop',
                          badgeBgColor: const Color(0xFFD1FADF),
                          badgeTextColor: const Color(0xFF12B76A),
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

  Widget _buildHeaderTab(
    String title,
    IconData icon,
    int index,
    VehicleDetailController controller,
  ) {
    return Obx(() {
      final isSelected = controller.selectedTopTab.value == index;
      final color = isSelected
          ? const Color(0xFF0288D1)
          : const Color(0xFF344054);

      return InkWell(
        onTap: () => controller.selectTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Row(
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Blue underline indicator for selected tab
            Container(
              height: 2.5,
              width: 70,
              color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
            ),
          ],
        ),
      );
    });
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

  Marker _buildNodeMarker(
    LatLng point,
    String label,
    VehicleDetailController controller,
  ) {
    return Marker(
      point: point,
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: controller.toggleHistoryMapDialog,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00A3E0).withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF00A3E0), width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475467),
              height: 1.2,
            ),
          ),
        ),
      ],
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

  Widget _buildHistoryTripCard({
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

class _HistoryMapIconButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final Color? color;

  const _HistoryMapIconButton({this.icon, this.text, this.color});

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
