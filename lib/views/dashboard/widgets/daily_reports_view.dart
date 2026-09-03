import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../controllers/dashboard_controller.dart';

class DailyReportsView extends StatefulWidget {
  const DailyReportsView({super.key});

  @override
  State<DailyReportsView> createState() => _DailyReportsViewState();
}

class _DailyReportsViewState extends State<DailyReportsView> {
  int _selectedPage = 1;

  final List<Map<String, dynamic>> _dailyReportsList = [
    {
      'vehicle': 'KL 07 D 0518',
      'distance': '2.65 Km',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'engineHour': '00:38:41h',
      'running': '00:38:41h',
      'stoped': '00:38:41h',
      'idle': '00:38:41h',
      'startLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'endLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'startOdo': '0535855KM',
      'endOdo': '0535855KM',
      'avgSpeed': '25.10 kmph',
      'maxSpeed': '52.10 kmph',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'distance': '2.65 Km',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'engineHour': '00:38:41h',
      'running': '00:38:41h',
      'stoped': '00:38:41h',
      'idle': '00:38:41h',
      'startLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'endLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'startOdo': '0535855KM',
      'endOdo': '0535855KM',
      'avgSpeed': '25.10 kmph',
      'maxSpeed': '52.10 kmph',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'distance': '2.65 Km',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'engineHour': '00:38:41h',
      'running': '00:38:41h',
      'stoped': '00:38:41h',
      'idle': '00:38:41h',
      'startLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'endLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'startOdo': '0535855KM',
      'endOdo': '0535855KM',
      'avgSpeed': '25.10 kmph',
      'maxSpeed': '52.10 kmph',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'distance': '2.65 Km',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'engineHour': '00:38:41h',
      'running': '00:38:41h',
      'stoped': '00:38:41h',
      'idle': '00:38:41h',
      'startLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'endLocation': 'Puthiyakavu Junction,Karunagappalli, Kerala 690539, India',
      'startOdo': '0535855KM',
      'endOdo': '0535855KM',
      'avgSpeed': '25.10 kmph',
      'maxSpeed': '52.10 kmph',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Header Bar (Search Box + Date Pickers + Export Icon)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Search Vehicles Search Bar
                Container(
                  width: 300,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Search Vehicles',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Start Date & End Date Range Pickers
                Obx(
                  () => _buildDatePickerBox(controller.reportStartDate.value),
                ),
                const SizedBox(width: 12),
                Obx(() => _buildDatePickerBox(controller.reportEndDate.value)),
                const SizedBox(width: 12),

                // Yellow Document Export Button with Blue Download Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD0D5DD),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Color(0xFFF59E0B),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A3E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content Body (2-Column Cards Grid & Pagination)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // 2-Column Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth;
                      int crossAxisCount = 2;

                      if (maxWidth < 850) {
                        crossAxisCount = 1;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _dailyReportsList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.45,
                        ),
                        itemBuilder: (context, index) {
                          final item = _dailyReportsList[index];
                          return _buildDailyCard(item);
                        },
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Section 1: Vehicle Number + Location Pin Metric
          Row(
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2939),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.location_on,
                size: 14,
                color: Color(0xFFF04438),
              ),
              const SizedBox(width: 4),
              Text(
                item['distance'],
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2939),
                ),
              ),
            ],
          ),

          // Section 2: Timestamps
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF12B76A),
              ),
              const SizedBox(width: 4),
              Text(
                item['startTime'],
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFFF04438),
              ),
              const SizedBox(width: 4),
              Text(
                item['endTime'],
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),

          const _HorizontalDashedLine(),

          // Section 3: 4 Metrics Grid (Engine Hour, Running, Stoped, Idle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('Engine Hour', item['engineHour'], const Color(0xFFE65100)),
              _buildMetricColumn('Running', item['running'], const Color(0xFF12B76A)),
              _buildMetricColumn('Stoped', item['stoped'], const Color(0xFFF04438)),
              _buildMetricColumn('Idle', item['idle'], const Color(0xFFF57C00)),
            ],
          ),

          const _HorizontalDashedLine(),

          // Section 4: Locations & Odometer Pills Timeline
          Column(
            children: [
              // Start Location
              Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 9,
                    color: Color(0xFF12B76A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['startLocation'],
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF475467),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Middle Vertical Connector & Odometer Pills Row
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Row(
                  children: [
                    Container(
                      width: 1.5,
                      height: 22,
                      color: const Color(0xFFD0D5DD),
                    ),
                    const SizedBox(width: 24),
                    // Green Odometer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FADF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['startOdo'],
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF12B76A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Color(0xFF98A2B3),
                    ),
                    const SizedBox(width: 8),
                    // Red Odometer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE4E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['endOdo'],
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF04438),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // End Location
              Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 9,
                    color: Color(0xFFF04438),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['endLocation'],
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF475467),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const _HorizontalDashedLine(),

          // Section 5: Speed Metrics Bottom Row (Avg Speed & Max Speed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: Color(0xFF00A3E0),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Avg Speed: ',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                    Text(
                      item['avgSpeed'],
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: Color(0xFFF04438),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Max Speed: ',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                    Text(
                      item['maxSpeed'],
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color labelColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 2,
          width: 54,
          decoration: BoxDecoration(
            color: labelColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2939),
          ),
        ),
      ],
    );
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

class _HorizontalDashedLine extends StatelessWidget {
  const _HorizontalDashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 3.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEAECF0)),
              ),
            );
          }),
        );
      },
    );
  }
}
