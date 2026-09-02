import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import 'widgets/account_settings_content.dart';
import 'widgets/coming_soon_content.dart';
import 'widgets/general_settings_content.dart';
import 'widgets/profile_sidebar_menu.dart';
import 'widgets/raise_ticket_content.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Profile Menu
          const ProfileSidebarMenu(),

          // Right Details Panel
          Expanded(
            child: Obx(() {
              final selectedIndex = controller.selectedMenuIndex.value;

              switch (selectedIndex) {
                case 1:
                  return const AccountSettingsContent();
                case 2:
                  return const RaiseTicketContent();
                case 3:
                  return const ComingSoonContent(title: 'Change Password');
                case 4:
                  return const ComingSoonContent(title: 'Configure Alerts');
                case 0:
                default:
                  return const GeneralSettingsContent();
              }
            }),
          ),
        ],
      ),
    );
  }
}
