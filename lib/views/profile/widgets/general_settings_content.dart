import 'package:flutter/material.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';

class GeneralSettingsContent extends StatelessWidget {
  const GeneralSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsList = [
      {'title': 'Show History on Live', 'asset': AppAssets.liveHistory},
      {'title': 'Vehicle Icon Size', 'asset': AppAssets.vehicleSize},
      {'title': 'Time Format', 'asset': AppAssets.timeFormat},
      {'title': 'Speedometer', 'asset': AppAssets.speedometer},
      {'title': 'Map Type', 'asset': AppAssets.mapType},
      {'title': 'Speed', 'asset': AppAssets.speed},
      {'title': 'Distance', 'asset': AppAssets.distance},
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          const Text(
            'General Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 20),

          // 7 Settings Dropdown Rows Cards (using PNG image assets)
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: settingsList.length,
              itemBuilder: (context, index) {
                final item = settingsList[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left Image Asset Container
                      Image.asset(
                        item['asset'] as String,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),

                      // Title
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),

                      // Right Dropdown Arrow Icon
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 26,
                        color: AppColors.buttonBlue,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
