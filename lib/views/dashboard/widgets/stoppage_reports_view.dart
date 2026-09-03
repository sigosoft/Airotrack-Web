import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../controllers/dashboard_controller.dart';
import 'stoppage_detail_map_view.dart';

class StoppageReportsView extends StatefulWidget {
  const StoppageReportsView({super.key});

  @override
  State<StoppageReportsView> createState() => _StoppageReportsViewState();
}

class _StoppageReportsViewState extends State<StoppageReportsView> {
  int _selectedPage = 1;

  final List<Map<String, dynamic>> _stoppageReportsList = [
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'duration': '02h 40m',
      'startTime': 'Oct 17, 2025 12:00:08 AM',
      'endTime': 'Oct 17, 2025 2:40:08 AM',
      'location': 'Puthiyakavu Junction, Karunagappalli, Kerala 690539, India',
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

                      if (maxWidth < 768) {
                        crossAxisCount = 1;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stoppageReportsList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.8,
                        ),
                        itemBuilder: (context, index) {
                          final item = _stoppageReportsList[index];
                          return _buildStoppageCard(item);
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

  Widget _buildStoppageCard(Map<String, dynamic> item) {
    return Container(
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Row 1: Red Car Icon + Vehicle Number + Duration
                Row(
                  children: [
                    Image.asset(
                      AppAssets.carImage,
                      width: 18,
                      height: 18,
                      color: const Color(0xFFF04438),
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
                    const Text(
                      'Duration: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667085),
                      ),
                    ),
                    Text(
                      item['duration'],
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),

                // Row 2: Green Start Clock & Red End Clock Timestamps
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF12B76A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['startTime'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFFF04438),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['endTime'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),

                // Row 3: Location Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFFF04438),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['location'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475467),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Right Square Blue Action Button (↗)
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: () {
                Get.to(() => StoppageDetailMapView(reportData: item));
              },
              child: Container(
                width: 32,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A3E0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
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
