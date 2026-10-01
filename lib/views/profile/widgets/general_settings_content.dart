import 'package:airotrack_web/constants/app_strings.dart';
import 'package:airotrack_web/services/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/custom_media_query.dart';

class GeneralSettingsContent extends StatefulWidget {
  const GeneralSettingsContent({super.key});

  @override
  State<GeneralSettingsContent> createState() => _GeneralSettingsContentState();
}

class _GeneralSettingsContentState extends State<GeneralSettingsContent> {
  // Row that is expanded (Vehicle Icon Size shows its 3 options).
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final isMobile = CustomMediaQuery.isMobile(context);
    final settings = AppSettings.to;

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
      padding: EdgeInsets.all(isMobile ? 14 : 24),
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
                final title = item['title'] as String;
                final isHistory = title == 'Show History on Live';
                final isIconSize = title == 'Vehicle Icon Size';
                final open = _expanded == title;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEAECF0),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (isHistory) {
                            settings.setShowHistoryOnLive(
                              !settings.showHistoryOnLive.value,
                            );
                          } else if (isIconSize) {
                            setState(() => _expanded = open ? null : title);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
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
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF344054),
                                  ),
                                ),
                              ),

                              // Show History on Live: switch (like the app).
                              // Others: the dropdown arrow as before.
                              if (isHistory)
                                Obx(
                                  () => SizedBox(
                                    height: 26,
                                    child: Transform.scale(
                                      scale: 0.75,
                                      child: CupertinoSwitch(
                                        value: settings.showHistoryOnLive.value,
                                        activeColor: const Color(0xFF00A3E0),
                                        onChanged:
                                            settings.setShowHistoryOnLive,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  open
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  size: 26,
                                  color: AppColors.buttonBlue,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Vehicle Icon Size options: Small / Medium / Large.
                      // One is always selected; the car on the Live and
                      // History maps uses that size.
                      if (isIconSize && open)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(54, 0, 16, 10),
                          child: Obx(
                            () => Column(
                              children: [
                                for (final size in AppSettings.iconSizes)
                                  InkWell(
                                    onTap: () =>
                                        settings.setVehicleIconSize(size),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              size,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF344054),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 26,
                                            child: Transform.scale(
                                              scale: 0.75,
                                              child: CupertinoSwitch(
                                                value:
                                                    settings
                                                        .vehicleIconSize
                                                        .value ==
                                                    size,
                                                activeColor: const Color(
                                                  0xFF00A3E0,
                                                ),
                                                onChanged: (on) {
                                                  if (on) {
                                                    settings.setVehicleIconSize(
                                                      size,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
