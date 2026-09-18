import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import '../../../utils/custom_media_query.dart';

class StatisticsViewContent extends StatefulWidget {
  const StatisticsViewContent({super.key});

  @override
  State<StatisticsViewContent> createState() => _StatisticsViewContentState();
}

class _StatisticsViewContentState extends State<StatisticsViewContent> {
  String? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<VehicleDetailController>()) {
        Get.find<VehicleDetailController>().loadStatistics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller =
        Get.find<VehicleDetailController>();
    final isMobile = CustomMediaQuery.isMobile(context);

    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final List<String> vehiclesList =
        homeCtrl?.vehicles.map((v) => v.plateNumber).toList() ?? [];
    if (vehiclesList.isEmpty &&
        controller.vehicleDetail.value.vehicleNumber.isNotEmpty) {
      vehiclesList.add(controller.vehicleDetail.value.vehicleNumber);
    }
    final selectedVehValue =
        (_selectedVehicle != null && vehiclesList.contains(_selectedVehicle))
        ? _selectedVehicle
        : (vehiclesList.isNotEmpty ? vehiclesList.first : null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Navigation Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
                ),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (Navigator.canPop(context)) {
                                  Get.back();
                                } else {
                                  controller.selectTab(-1);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildHeaderTab(
                                    'History',
                                    Icons.access_time_rounded,
                                    0,
                                    controller,
                                  ),
                                  _buildHeaderTab(
                                    'Alerts',
                                    Icons.notifications_none_rounded,
                                    1,
                                    controller,
                                  ),
                                  _buildHeaderTab(
                                    'Statistics',
                                    Icons.analytics_outlined,
                                    2,
                                    controller,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => _buildDatePickerBox(
                                  controller.startDateStr.value,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Obx(
                                () => _buildDatePickerBox(
                                  controller.endDateStr.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          // Back Arrow Button
                          InkWell(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Get.back();
                              } else {
                                controller.selectTab(-1);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Navigation Header Tabs (History, Alerts, Statistics)
                          _buildHeaderTab(
                            'History',
                            Icons.access_time_rounded,
                            0,
                            controller,
                          ),
                          const SizedBox(width: 24),
                          _buildHeaderTab(
                            'Alerts',
                            Icons.notifications_none_rounded,
                            1,
                            controller,
                          ),
                          const SizedBox(width: 24),
                          _buildHeaderTab(
                            'Statistics',
                            Icons.analytics_outlined,
                            2,
                            controller,
                          ),

                          const Spacer(),

                          // Date Range Pickers (Start Date & End Date)
                          Obx(
                            () => _buildDatePickerBox(
                              controller.startDateStr.value,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Obx(
                            () => _buildDatePickerBox(
                              controller.endDateStr.value,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // 2. Main Area (Vehicle Dropdown + 5x2 Stat Cards Grid)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Dropdown Selector Button
                    Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEAECF0),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedVehValue,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF00A3E0),
                            size: 28,
                          ),
                          items: vehiclesList.map((String vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle,
                              child: Text(
                                vehicle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedVehicle = val;
                              });
                              if (homeCtrl != null) {
                                final matchedVeh = homeCtrl.vehicles
                                    .firstWhereOrNull(
                                      (v) => v.plateNumber == val,
                                    );
                                if (matchedVeh != null) {
                                  controller.updateFromVehicle(matchedVeh);
                                  controller.loadStatistics(
                                    imei: matchedVeh.deviceId,
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 10 Statistics Cards Grid (5 per row)
                    Obx(() {
                      final stats = controller.statisticsData;

                      final List<Map<String, String>> statCards = [
                        {
                          'title': 'Route Length',
                          'value': stats['Route Length'] ?? '0 km',
                          'asset': AppAssets.routeLength,
                        },
                        {
                          'title': 'Move Duration',
                          'value': stats['Move Duration'] ?? '00:00:00',
                          'asset': AppAssets.moveDuration,
                        },
                        {
                          'title': 'Idle Duration',
                          'value': stats['Idle Duration'] ?? '00:00:00',
                          'asset': AppAssets.idleDuration,
                        },
                        {
                          'title': 'Stop Duration',
                          'value': stats['Stop Duration'] ?? '00:00:00',
                          'asset': AppAssets.stopDuration,
                        },
                        {
                          'title': 'Stop Count',
                          'value': stats['Stop Count'] ?? '0',
                          'asset': AppAssets.stopCount,
                        },
                        {
                          'title': 'Average Speed',
                          'value': stats['Average Speed'] ?? '0 kmph',
                          'asset': AppAssets.averageSpeed,
                        },
                        {
                          'title': 'Top Speed',
                          'value': stats['Top Speed'] ?? '0 kmph',
                          'asset': AppAssets.topSpeed,
                        },
                        {
                          'title': 'Over Speed Count',
                          'value': stats['Over Speed Count'] ?? '0',
                          'asset': AppAssets.overSpeedCount,
                        },
                        {
                          'title': 'Engine Hours',
                          'value': stats['Engine Hours'] ?? '00:00:00',
                          'asset': AppAssets.engineHours,
                        },
                        {
                          'title': 'Odometer',
                          'value': stats['Odometer'] ?? '0 km',
                          'asset': AppAssets.odometes,
                        },
                      ];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double maxWidth = constraints.maxWidth;
                          int crossAxisCount = 5;

                          if (maxWidth < 600) {
                            crossAxisCount = 2;
                          } else if (maxWidth < 950) {
                            crossAxisCount = 3;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: statCards.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.25,
                                ),
                            itemBuilder: (context, index) {
                              final card = statCards[index];
                              return _buildStatCard(
                                title: card['title']!,
                                value: card['value']!,
                                assetPath: card['asset']!,
                              );
                            },
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String assetPath,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // PNG Icon Asset
          Image.asset(assetPath, width: 38, height: 38, fit: BoxFit.contain),
          const SizedBox(height: 12),

          // Title Label
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475467),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Metric Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(
    String title,
    IconData icon,
    int index,
    VehicleDetailController controller,
  ) {
    return Obx(() {
      final isSelected = controller.selectedTopTab.value == index;
      final color = isSelected
          ? const Color(0xFF0288D1)
          : const Color(0xFF344054);

      return InkWell(
        onTap: () => controller.selectTab(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Blue underline indicator for selected tab
            Container(
              height: 2.5,
              width: 70,
              color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDatePickerBox(String dateStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 15,
            color: Color(0xFF667085),
          ),
          const SizedBox(width: 6),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }
}
