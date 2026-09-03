import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/tracking_controller.dart';
import '../../utils/custom_media_query.dart';
import '../tracking/widgets/tracking_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/daily_reports_view.dart';
import 'widgets/engine_hours_chart.dart';
import 'widgets/expenses_view.dart';
import 'widgets/fleet_status_chart.dart';
import 'widgets/geofence_reports_view.dart';
import 'widgets/geofence_view.dart';
import 'widgets/ignition_reports_view.dart';
import 'widgets/over_speed_reports_view.dart';
import 'widgets/sidebar_navigation.dart';
import 'widgets/stoppage_reports_view.dart';
import 'widgets/summary_reports_view.dart';
import 'widgets/travel_distance_chart.dart';
import 'widgets/trip_reports_view.dart';
import 'widgets/vehicle_list_card.dart';
import 'widgets/vehicle_status_cards.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    final isMobile = CustomMediaQuery.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Header Bar
          Obx(
            () => DashboardHeader(
              userName: controller.dashboardData.value.userName,
            ),
          ),

          // 2. Body Container (Sidebar + Dynamic Screen Content)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar Navigation
                if (!isMobile)
                  Obx(
                    () => SidebarNavigation(
                      selectedIndex: controller.selectedMenuIndex.value,
                      onItemSelected: controller.selectMenu,
                    ),
                  ),

                // Dynamic Main Body Content (Dashboard vs Tracking vs Reports)
                Expanded(
                  child: Obx(() {
                    final selectedIndex = controller.selectedMenuIndex.value;

                    if (selectedIndex == 2) {
                      // --- Reports Screen Body ---
                      final subIndex = controller.selectedReportSubIndex.value;
                      if (subIndex == 6) {
                        return const GeofenceReportsView();
                      }
                      if (subIndex == 5) {
                        return const OverSpeedReportsView();
                      }
                      if (subIndex == 4) {
                        return const SummaryReportsView();
                      }
                      if (subIndex == 3) {
                        return const DailyReportsView();
                      }
                      if (subIndex == 2) {
                        return const TripReportsView();
                      }
                      if (subIndex == 1) {
                        return const StoppageReportsView();
                      }
                      return const IgnitionReportsView();
                    }

                    if (selectedIndex == 4) {
                      // --- Geofence Screen Body ---
                      return const GeofenceView();
                    }

                    if (selectedIndex == 3) {
                      // --- Expenses Screen Body ---
                      return const ExpensesView();
                    }

                    if (selectedIndex == 1) {
                      // --- Tracking Screen Body ---
                      final trackingController = Get.put(TrackingController());

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Vehicle Summary Status Cards
                            VehicleStatusCards(
                              summaryList:
                                  controller.dashboardData.value.summaryList,
                            ),
                            const SizedBox(height: 16),

                            // 2x2 Tracking Cards Grid
                            Obx(() {
                              final trackingList = trackingController
                                  .trackingData
                                  .value
                                  .trackingVehicles;

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 900) {
                                    return Column(
                                      children: trackingList.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: TrackingCard(data: item),
                                        );
                                      }).toList(),
                                    );
                                  }

                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: trackingList.map((item) {
                                      return SizedBox(
                                        width: (constraints.maxWidth - 16) / 2,
                                        child: TrackingCard(data: item),
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    }

                    // --- Default Dashboard Screen Body ---
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Summary Cards
                          VehicleStatusCards(
                            summaryList:
                                controller.dashboardData.value.summaryList,
                          ),
                          const SizedBox(height: 16),

                          // Row 2: Donut Chart & Vehicles List
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final vehicleListWidget = Obx(
                                () => VehicleListCard(
                                  vehicleList: controller
                                      .dashboardData
                                      .value
                                      .vehicleList,
                                  selectedIndex:
                                      controller.selectedVehicleIndex.value,
                                  onSelect: controller.selectVehicle,
                                ),
                              );

                              if (constraints.maxWidth < 768) {
                                return Column(
                                  children: [
                                    const FleetStatusChart(),
                                    const SizedBox(height: 16),
                                    vehicleListWidget,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    flex: 1,
                                    child: FleetStatusChart(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 1, child: vehicleListWidget),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Row 3: Line & Bar Charts
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final engineHoursWidget = EngineHoursChart(
                                dataPoints: controller
                                    .dashboardData
                                    .value
                                    .engineHoursData,
                              );
                              final travelDistanceWidget = TravelDistanceChart(
                                dataPoints: controller
                                    .dashboardData
                                    .value
                                    .travelDistanceData,
                              );

                              if (constraints.maxWidth < 768) {
                                return Column(
                                  children: [
                                    engineHoursWidget,
                                    const SizedBox(height: 16),
                                    travelDistanceWidget,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 1, child: engineHoursWidget),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: travelDistanceWidget,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
