import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.grid_view_rounded, 'hasDropdown': false},
      {'title': 'Tracking', 'icon': Icons.location_on_outlined, 'hasDropdown': false},
      {'title': 'Reports', 'icon': Icons.insert_drive_file_outlined, 'hasDropdown': true},
      {'title': 'Expenses', 'icon': Icons.account_balance_wallet_outlined, 'hasDropdown': false},
      {'title': 'Geofence', 'icon': Icons.center_focus_weak_outlined, 'hasDropdown': false},
    ];

    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFEAECF0), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...List.generate(menuItems.length, (index) {
            final isSelected = selectedIndex == index;
            final item = menuItems[index];

            return InkWell(
              onTap: () => onItemSelected(index),
              child: Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Active Left Indicator Bar
                    Container(
                      width: 4,
                      height: double.infinity,
                      color: isSelected ? AppColors.buttonBlue : Colors.transparent,
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.buttonBlue : const Color(0xFF344054),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.buttonBlue : const Color(0xFF344054),
                        ),
                      ),
                    ),
                    if (item['hasDropdown'] as bool) ...[
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
