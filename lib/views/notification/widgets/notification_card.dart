import 'package:flutter/material.dart';
import '../../../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItemData data;

  const NotificationCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final statusColor = data.isIgnitionOn
        ? const Color(0xFF00A859)
        : const Color(0xFFE53935);

    final statusBgColor = data.isIgnitionOn
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.power_settings_new_rounded,
                      size: 22,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data.ignitionStatus,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.locationAddress,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF667085),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    data.timestamp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A2B3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Power Icon (Green for Ignition On / Red for Ignition Off)
                Icon(
                  Icons.power_settings_new_rounded,
                  size: 26,
                  color: statusColor,
                ),
                const SizedBox(width: 20),

                // Main Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data.vehicleNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Ignition Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data.ignitionStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.locationAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right Timestamp
                Text(
                  data.timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
