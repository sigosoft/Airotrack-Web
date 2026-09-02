import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';

class TravelDistanceChart extends StatelessWidget {
  final List<TravelDistanceDataPoint> dataPoints;

  const TravelDistanceChart({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Travel Distance (in KM)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y-Axis Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      '144',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '128',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '112',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '96',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '80',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '64',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '48',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '32',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '16',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                    Text(
                      '0',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Vertical Axis Line
                Container(
                  width: 1,
                  height: double.infinity,
                  color: const Color(0xFFD0D5DD),
                ),
                const SizedBox(width: 8),
                // Bars Area & X-Axis
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: dataPoints.map((item) {
                            final fillRatio = (item.distanceKm / item.maxKm)
                                .clamp(0.0, 1.0);

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAECF0),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: fillRatio,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B5E20),
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Baseline Line
                      Container(height: 1, color: const Color(0xFFD0D5DD)),
                      const SizedBox(height: 4),
                      // X-Axis Date Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: dataPoints.map((item) {
                          return Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF667085),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
