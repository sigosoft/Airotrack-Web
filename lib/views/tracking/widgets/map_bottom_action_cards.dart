import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../reminder/add_reminder_view.dart';
import 'select_geofence_dialog.dart';
import 'share_location_dialog.dart';
import 'update_odometer_dialog.dart';

class MapBottomActionCards extends StatelessWidget {
  final ValueChanged<String>? onActionTap;

  const MapBottomActionCards({super.key, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'title': 'Share Location', 'asset': AppAssets.shareLocation},
      {'title': 'Add Geofence', 'asset': AppAssets.geofence},
      {'title': 'Street View', 'asset': AppAssets.streetView},
      {'title': 'Update Odometer', 'asset': AppAssets.odometer},
      {'title': 'Add Reminders', 'asset': AppAssets.reminder},
    ];

    return Row(
      children: actions.map((item) {
        final title = item['title'] as String;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAECF0), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  item['asset'] as String,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF344054),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () {
                      if (title == 'Share Location') {
                        showDialog(
                          context: context,
                          builder: (context) => const ShareLocationDialog(),
                        );
                      } else if (title == 'Add Geofence') {
                        showDialog(
                          context: context,
                          builder: (context) => const SelectGeofenceDialog(),
                        );
                      } else if (title == 'Update Odometer') {
                        showDialog(
                          context: context,
                          builder: (context) => const UpdateOdometerDialog(),
                        );
                      } else if (title == 'Add Reminders') {
                        Get.to(() => const AddReminderView());
                      } else {
                        onActionTap?.call(title);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 28,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.buttonBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
