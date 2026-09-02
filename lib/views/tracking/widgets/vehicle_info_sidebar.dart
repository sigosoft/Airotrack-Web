import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../models/vehicle_detail_model.dart';
import 'send_command_dialog.dart';

class VehicleInfoSidebar extends StatelessWidget {
  final VehicleDetailData data;

  const VehicleInfoSidebar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final odometerDigitsList = data.odometerDigits.split('');

    return Container(
      width: 380,
      color: const Color(0xFFF4F6F9),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header (Back Arrow + Vehicle Number)
            Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  data.vehicleNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Boxed Digital Odometer Counter
            Row(
              children: odometerDigitsList.map((digit) {
                return Container(
                  width: 22,
                  height: 26,
                  margin: const EdgeInsets.only(right: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFD0D5DD),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // 3. Date & Distance Row (using Avg speed.png PNG image asset)
            Row(
              children: [
                Text(
                  data.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                  ),
                ),
                const Spacer(),
                Image.asset(
                  AppAssets.avgSpeed,
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
                Text(
                  data.distanceKm,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF344054),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Vehicle & Speedometer Gauge Card (using Speeds.png asset)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAECF0), width: 1),
              ),
              child: Row(
                children: [
                  // SUV Car Image
                  Expanded(
                    flex: 1,
                    child: Image.asset(
                      AppAssets.greenCar,
                      height: 75,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Speedometer Gauge Asset Image (Speeds.png)
                  Image.asset(
                    AppAssets.speedsGauge,
                    width: 85,
                    height: 75,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Coordinates & Location Container (using Accuracy.png asset)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEAECF0), width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Image.asset(
                          AppAssets.accuracy,
                          width: 14,
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.coordinates,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF0288D1),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFEAECF0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF667085),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.address,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF475467),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 6. Action PNG Image Assets Toolbar (Ignition.png, On_Off.png, battery charge.png, Power.png, Wifi.png)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _ImageAssetPill(assetPath: AppAssets.ignition),
                const _ImageAssetPill(assetPath: AppAssets.onOff),
                const _ImageAssetPill(assetPath: AppAssets.batteryCharge),
                _ImageAssetPill(
                  assetPath: AppAssets.power,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SendCommandDialog(
                        vehicleNumber: data.vehicleNumber,
                      ),
                    );
                  },
                ),
                const _ImageAssetPill(assetPath: AppAssets.wifi),
              ],
            ),
            const SizedBox(height: 12),

            // 7. Device Time & Server Time Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEAECF0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Device Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.deviceTime,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0288D1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEAECF0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Server Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.serverTime,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0288D1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 8. Status Duration Pills (4 Pills)
            Row(
              children: [
                _buildStatusDurationPill(
                  'Running',
                  data.runningDuration,
                  const Color(0xFF00A859),
                  const Color(0xFFE8F5E9),
                ),
                const SizedBox(width: 4),
                _buildStatusDurationPill(
                  'Idle',
                  data.idleDuration,
                  const Color(0xFFF57C00),
                  const Color(0xFFFFF8E1),
                ),
                const SizedBox(width: 4),
                _buildStatusDurationPill(
                  'Stopped',
                  data.stoppedDuration,
                  const Color(0xFFD32F2F),
                  const Color(0xFFFFEBEE),
                ),
                const SizedBox(width: 4),
                _buildStatusDurationPill(
                  'Inactive',
                  data.inactiveDuration,
                  const Color(0xFF0288D1),
                  const Color(0xFFE1F5FE),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 9. Performance Cards (3 Cards using PNG image assets: Avg speed.png, Max speed.png, Today Km.png)
            Row(
              children: [
                _buildImageAssetStatCard(
                  'Avg Speed',
                  '${data.avgSpeedKmph} Kmph',
                  AppAssets.avgSpeed,
                ),
                const SizedBox(width: 6),
                _buildImageAssetStatCard(
                  'Max Speed',
                  '${data.maxSpeedKmph} Kmph',
                  AppAssets.maxSpeed,
                ),
                const SizedBox(width: 6),
                _buildImageAssetStatCard(
                  'Today Odo',
                  '${data.todayOdoKm} km',
                  AppAssets.todayKm,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 10. Telemetry Sensors Grid (4x2 Grid Cards using PNG image assets)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.1,
              ),
              itemCount: data.sensors.length,
              itemBuilder: (context, index) {
                final item = data.sensors[index];

                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEAECF0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _getSensorImageAsset(item.iconType),
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Color(0xFF667085),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2939),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDurationPill(
    String title,
    String duration,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(duration, style: TextStyle(fontSize: 8.5, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAssetStatCard(
    String title,
    String value,
    String assetPath,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEAECF0), width: 1),
        ),
        child: Column(
          children: [
            Image.asset(assetPath, width: 22, height: 22, fit: BoxFit.contain),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF667085)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSensorImageAsset(String type) {
    switch (type) {
      case 'battery':
        return AppAssets.battery;
      case 'car_battery':
        return AppAssets.carBattery;
      case 'satellite':
        return AppAssets.satelite;
      case 'fuel':
        return AppAssets.fuels;
      case 'accuracy':
        return AppAssets.accuracy;
      case 'temp':
        return AppAssets.temp;
      case 'movement':
        return AppAssets.movement;
      case 'movement2':
        return AppAssets.movementNa;
      default:
        return AppAssets.battery;
    }
  }
}

class _ImageAssetPill extends StatelessWidget {
  final String assetPath;
  final VoidCallback? onTap;

  const _ImageAssetPill({required this.assetPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEAECF0), width: 1),
        ),
        child: Image.asset(
          assetPath,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
