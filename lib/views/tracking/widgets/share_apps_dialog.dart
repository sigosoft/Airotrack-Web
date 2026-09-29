import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/app_toast.dart';
import '../../../utils/share_helper.dart';

class ShareAppsDialog extends StatelessWidget {
  final String vehicleNumber;
  final String durationLabel;
  final double? latitude;
  final double? longitude;

  const ShareAppsDialog({
    super.key,
    required this.vehicleNumber,
    required this.durationLabel,
    this.latitude,
    this.longitude,
  });

  String get shareUrl {
    if (latitude != null &&
        longitude != null &&
        latitude != 0.0 &&
        longitude != 0.0) {
      return 'https://maps.google.com/?q=$latitude,$longitude';
    }
    return 'https://airotrack.in';
  }

  String get shareText {
    return 'Live Location for $vehicleNumber ($durationLabel):\n$shareUrl\nShared via Airotrack';
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final apps = [
      {
        'title': 'WhatsApp',
        'subtitle': 'Share via WhatsApp chat',
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF25D366),
        'bg': const Color(0xFFE8F9EE),
        'action': () {
          final url =
              'https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareText)}';
          openShareUrl(url);
          Get.back();
        },
      },
      {
        'title': 'Telegram',
        'subtitle': 'Send via Telegram message',
        'icon': Icons.send_rounded,
        'color': const Color(0xFF0088CC),
        'bg': const Color(0xFFE0F2FE),
        'action': () {
          final url =
              'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent("Live tracking for $vehicleNumber ($durationLabel)")}';
          openShareUrl(url);
          Get.back();
        },
      },
      {
        'title': 'Email',
        'subtitle': 'Send via default email client',
        'icon': Icons.email_rounded,
        'color': const Color(0xFFEA4335),
        'bg': const Color(0xFFFEECEB),
        'action': () {
          final subject = 'Live Tracking for $vehicleNumber';
          final url =
              'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(shareText)}';
          openShareUrl(url);
          Get.back();
        },
      },
      {
        'title': 'Messages',
        'subtitle': 'Share via SMS text message',
        'icon': Icons.message_rounded,
        'color': const Color(0xFF007AFF),
        'bg': const Color(0xFFE6F2FF),
        'action': () {
          final url = 'sms:?body=${Uri.encodeComponent(shareText)}';
          openShareUrl(url);
          Get.back();
        },
      },
      {
        'title': 'Copy Link',
        'subtitle': 'Copy tracking link to clipboard',
        'icon': Icons.copy_rounded,
        'color': const Color(0xFF475467),
        'bg': const Color(0xFFF2F4F7),
        'action': () async {
          await Clipboard.setData(ClipboardData(text: shareText));
          AppToast.show('Tracking link copied to clipboard!');
          Get.back();
        },
      },
      {
        'title': 'System Share',
        'subtitle': 'Open device apps share sheet',
        'icon': Icons.share_rounded,
        'color': const Color(0xFF00A3E0),
        'bg': const Color(0xFFE0F7FD),
        'action': () async {
          final didShare = await invokeSystemShare(
            title: 'Live Tracking - $vehicleNumber',
            text: shareText,
            url: shareUrl,
          );
          if (!didShare) {
            await Clipboard.setData(ClipboardData(text: shareText));
            AppToast.show('Link copied to clipboard');
          }
          Get.back();
        },
      },
    ];

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$vehicleNumber • $durationLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF344054),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Link Preview Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: Color(0xFF667085),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shareUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF344054),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: shareText));
                      AppToast.show('Link copied!');
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A3E0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Apps Grid / List
            Column(
              children: apps.map((app) {
                final icon = app['icon'] as IconData;
                final color = app['color'] as Color;
                final bg = app['bg'] as Color;
                final title = app['title'] as String;
                final subtitle = app['subtitle'] as String;
                final action = app['action'] as VoidCallback;

                return InkWell(
                  onTap: action,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF98A2B3),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
