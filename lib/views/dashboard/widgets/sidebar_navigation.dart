import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/dashboard_controller.dart';

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
    final DashboardController controller = Get.find<DashboardController>();

    final menuItems = [
      {'title': 'Dashboard', 'asset': AppAssets.sidebarDashboard, 'hasDropdown': false},
      {'title': 'Tracking', 'asset': AppAssets.sidebarTracking, 'hasDropdown': false},
      {'title': 'Reports', 'asset': AppAssets.sidebarReports, 'hasDropdown': true},
      {'title': 'Expenses', 'asset': AppAssets.sidebarExpenses, 'hasDropdown': false},
      {'title': 'Geofence', 'asset': AppAssets.sidebarGeofence, 'hasDropdown': false},
    ];

    final reportSubItems = [
      'Ignition Reports',
      'Stoppage Reports',
      'Trip Reports',
      'Daily Reports',
      'Summary Reports',
      'Over Speed Reports',
      'Geofence Reports',
    ];

    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFEAECF0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            ...List.generate(menuItems.length, (index) {
              final isSelected = selectedIndex == index;
              final item = menuItems[index];

              if (index == 2) {
                // Reports Menu Item with Expandable Sub-items
                return Obx(() {
                  final isExpanded = controller.isReportsExpanded.value;
                  final isReportsSelected = selectedIndex == 2;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          controller.toggleReportsExpand();
                          onItemSelected(2);
                        },
                        child: Container(
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isReportsSelected
                                ? const Color(0xFFE0F2FE)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              // Active Left Indicator Bar
                              Container(
                                width: 4,
                                height: double.infinity,
                                color: isReportsSelected
                                    ? AppColors.buttonBlue
                                    : Colors.transparent,
                              ),
                              const SizedBox(width: 14),
                              Image.asset(
                                item['asset'] as String,
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isReportsSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isReportsSelected
                                        ? AppColors.buttonBlue
                                        : const Color(0xFF344054),
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: isReportsSelected
                                    ? AppColors.buttonBlue
                                    : const Color(0xFF667085),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),

                      // Reports Dropdown Sub-Items List
                      if (isExpanded)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(reportSubItems.length, (subIdx) {
                            final isSubSelected =
                                isReportsSelected &&
                                controller.selectedReportSubIndex.value == subIdx;

                            return InkWell(
                              onTap: () {
                                controller.selectReportSub(subIdx);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(
                                  left: 36,
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: Text(
                                  reportSubItems[subIdx],
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSubSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSubSelected
                                        ? AppColors.buttonBlue
                                        : const Color(0xFF344054),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  );
                });
              }

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
                      Image.asset(
                        item['asset'] as String,
                        width: 20,
                        height: 20,
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
      ),
    );
  }
}
