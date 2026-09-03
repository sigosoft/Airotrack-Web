import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers/vehicle_detail_controller.dart';

class AlertsViewContent extends StatefulWidget {
  const AlertsViewContent({super.key});

  @override
  State<AlertsViewContent> createState() => _AlertsViewContentState();
}

class _AlertsViewContentState extends State<AlertsViewContent> {
  int _selectedPage = 1;

  final List<Map<String, dynamic>> _alertsList = [
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': true,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': false,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': true,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': false,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': true,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': false,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': true,
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025 05:38:08 PM',
      'location': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'isIgnitionOn': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final VehicleDetailController controller =
        Get.find<VehicleDetailController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                Obx(() => _buildDatePickerBox(controller.startDateStr.value)),
                const SizedBox(width: 12),
                Obx(() => _buildDatePickerBox(controller.endDateStr.value)),
                const SizedBox(width: 12),

                // Filter Sliders Icon Button
                _buildFilterIconButton(),
              ],
            ),
          ),

          // 2. Main Content Area (Alerts Table & Pagination)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                children: [
                  // Table Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Vehicle',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Date & Time',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Data Rows List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _alertsList.length,
                    itemBuilder: (context, index) {
                      final item = _alertsList[index];
                      final isIgnitionOn = item['isIgnitionOn'] as bool;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFEAECF0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Vehicle Column
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Image.asset(
                                    AppAssets.carImage,
                                    width: 18,
                                    height: 18,
                                    color: const Color(0xFF00A3E0),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item['vehicle'],
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D2939),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Date & Time Column
                            Expanded(
                              flex: 3,
                              child: Text(
                                item['dateTime'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ),

                            // Location Column
                            Expanded(
                              flex: 5,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: Color(0xFFF04438),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item['location'],
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475467),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status Column
                            SizedBox(
                              width: 150,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.power_settings_new_rounded,
                                    size: 17,
                                    color: isIgnitionOn
                                        ? const Color(0xFF12B76A)
                                        : const Color(0xFFF04438),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isIgnitionOn
                                          ? const Color(0xFFD1FADF)
                                          : const Color(0xFFFEE4E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isIgnitionOn
                                          ? 'Ignition On'
                                          : 'Ignition Off',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isIgnitionOn
                                            ? const Color(0xFF12B76A)
                                            : const Color(0xFFF04438),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Bottom Pagination Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= 10; i++) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPage = i;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedPage == i
                                  ? const Color(0xFF00A3E0)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _selectedPage == i
                                    ? Colors.white
                                    : const Color(0xFF344054),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      const SizedBox(width: 8),

                      // NEXT Button
                      InkWell(
                        onTap: () {
                          if (_selectedPage < 10) {
                            setState(() {
                              _selectedPage++;
                            });
                          }
                        },
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A3E0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
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

  Widget _buildFilterIconButton() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
      ),
      child: const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF344054)),
    );
  }
}
