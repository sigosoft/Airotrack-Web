import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/vehicle_detail_controller.dart';

class StatisticsViewContent extends StatefulWidget {
  const StatisticsViewContent({super.key});

  @override
  State<StatisticsViewContent> createState() => _StatisticsViewContentState();
}

class _StatisticsViewContentState extends State<StatisticsViewContent> {
  String _selectedVehicle = 'KL 07 D 0518';

  final List<String> _vehiclesList = [
    'KL 07 D 0518',
    'KL 07 D 0519',
    'KL 07 D 0520',
  ];

  final List<Map<String, String>> _statCards = [
    {
      'title': 'Route Length',
      'value': '100.13 km',
      'asset': AppAssets.routeLength,
    },
    {
      'title': 'Move Duration',
      'value': '30:10:11',
      'asset': AppAssets.moveDuration,
    },
    {
      'title': 'Idle Duration',
      'value': '00:10:11',
      'asset': AppAssets.idleDuration,
    },
    {
      'title': 'Stop Duration',
      'value': '10:49:23',
      'asset': AppAssets.stopDuration,
    },
    {
      'title': 'Stop Count',
      'value': '10',
      'asset': AppAssets.stopCount,
    },
    {
      'title': 'Average Speed',
      'value': '30.09 kmph',
      'asset': AppAssets.averageSpeed,
    },
    {
      'title': 'Top Speed',
      'value': '63 kmph',
      'asset': AppAssets.topSpeed,
    },
    {
      'title': 'Over Speed Count',
      'value': '5',
      'asset': AppAssets.overSpeedCount,
    },
    {
      'title': 'Engine Hours',
      'value': '30:10:11',
      'asset': AppAssets.engineHours,
    },
    {
      'title': 'Odometer',
      'value': '5000 km',
      'asset': AppAssets.odometes,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller = Get.find<VehicleDetailController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Navigation Header Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
              ),
            ),
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
                _buildHeaderTab('History', Icons.access_time_rounded, 0, controller),
                const SizedBox(width: 24),
                _buildHeaderTab('Alerts', Icons.notifications_none_rounded, 1, controller),
                const SizedBox(width: 24),
                _buildHeaderTab('Statistics', Icons.analytics_outlined, 2, controller),

                const Spacer(),

                // Date Range Pickers (Start Date & End Date)
                Obx(() => _buildDatePickerBox(controller.startDateStr.value)),
                const SizedBox(width: 12),
                Obx(() => _buildDatePickerBox(controller.endDateStr.value)),
              ],
            ),
          ),

          // 2. Main Area (Vehicle Dropdown + 5x2 Stat Cards Grid)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Dropdown Selector Button
                  Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEAECF0), width: 1),
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
                        value: _selectedVehicle,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFF00A3E0),
                          size: 28,
                        ),
                        items: _vehiclesList.map((String vehicle) {
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
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 10 Statistics Cards Grid (5 per row)
                  LayoutBuilder(
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
                        itemCount: _statCards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                        ),
                        itemBuilder: (context, index) {
                          final card = _statCards[index];
                          return _buildStatCard(
                            title: card['title']!,
                            value: card['value']!,
                            assetPath: card['asset']!,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
          Image.asset(
            assetPath,
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Row(
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
            const Spacer(),
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
