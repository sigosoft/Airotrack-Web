import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../models/tracking_model.dart';
import '../vehicle_detail_map_view.dart';

class TrackingCard extends StatelessWidget {
  final TrackingCardData data;
  final VoidCallback? onArrowTap;

  const TrackingCard({
    super.key,
    required this.data,
    this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = data.isGreenVehicle
        ? const Color(0xFF00A859)
        : const Color(0xFFE53935);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Padlock Badge on Top Left
          if (data.isLocked)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: Color(0xFF00A859),
                  size: 14,
                ),
              ),
            ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: SUV Image & Speed Indicator
                    SizedBox(
                      width: 135,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 6),
                          Image.asset(
                            data.isGreenVehicle ? AppAssets.greenCar : AppAssets.redCar,
                            width: 125,
                            height: 68,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${data.speedKmH}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D2939),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Text(
                            'Kmph',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Vertical Separator Line between Left & Right Columns
                    Container(
                      width: 1,
                      height: 145,
                      color: const Color(0xFFEAECF0),
                    ),

                    const SizedBox(width: 14),

                    // Right Column: Vertical Timeline Stepper with Dotted Connectors
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Registration Number Row
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                child: Icon(
                                  Icons.directions_car_rounded,
                                  size: 15,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data.registrationNumber,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ],
                          ),

                          // Dotted Connector 1
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: _VerticalDottedLine(height: 10, color: const Color(0xFF98A2B3)),
                          ),

                          // 2. Status Row
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data.status,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data.duration,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),

                          // Dotted Connector 2
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: _VerticalDottedLine(height: 10, color: const Color(0xFF98A2B3)),
                          ),

                          // 3. Timestamp Row
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                child: Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.timestamp,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475467),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Dotted Connector 3
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: _VerticalDottedLine(height: 10, color: const Color(0xFF98A2B3)),
                          ),

                          // 4. Location Address Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 14,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.locationAddress,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF475467),
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFEAECF0)),

              // Bottom Toolbar Row
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                child: Row(
                  children: [
                    // 4 Action Square Buttons
                    _buildSquareIconButton(
                      Icons.ac_unit_rounded,
                      data.isRunning ? const Color(0xFF00A3E0) : const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 6),
                    _buildSquareIconButton(
                      Icons.podcasts_rounded,
                      const Color(0xFF00A859),
                    ),
                    const SizedBox(width: 6),
                    _buildSquareIconButton(
                      Icons.power_settings_new_rounded,
                      data.isRunning ? const Color(0xFF00A859) : const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 6),
                    _buildSquareIconButton(
                      Icons.build_rounded,
                      data.isGreenVehicle ? const Color(0xFF00A3E0) : const Color(0xFFE53935),
                    ),

                    const Spacer(),

                    // Metric Pill 1: Odometer Distance
                    _buildMetricPill(
                      icon: Icons.speed_rounded,
                      label: data.distanceKmText,
                    ),
                    const SizedBox(width: 6),

                    // Metric Pill 2: Validity Days
                    _buildMetricPill(
                      icon: Icons.calendar_month_outlined,
                      label: data.validityText,
                    ),

                    const SizedBox(width: 10),

                    // Bottom Right Action Blue Button (↗)
                    InkWell(
                      onTap: onArrowTap ?? () => Get.to(() => const VehicleDetailMapView()),
                      child: Container(
                        width: 36,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A3E0),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: const Icon(
                          Icons.north_east_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareIconButton(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }

  Widget _buildMetricPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475467)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vertical Dotted Line Connector for Timeline Stepper
class _VerticalDottedLine extends StatelessWidget {
  final double height;
  final Color color;

  const _VerticalDottedLine({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: height,
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(1, height),
        painter: _DottedLinePainter(color: color),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 2.0;
    const dashSpace = 2.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
