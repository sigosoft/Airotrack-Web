import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class IgnitionDetailMapView extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const IgnitionDetailMapView({
    super.key,
    this.reportData,
  });

  @override
  State<IgnitionDetailMapView> createState() => _IgnitionDetailMapViewState();
}

class _IgnitionDetailMapViewState extends State<IgnitionDetailMapView> {
  bool _isDialogVisible = true;

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.reportData?['vehicle'] ?? 'KL 07 D 0518';
    final isIgnitionOn = widget.reportData?['isIgnitionOn'] ?? true;
    final timestamp = widget.reportData?['timestamp'] ?? '08 Oct 2025 12:30 PM';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Navigation Bar with Back Arrow & 'Ignition' Title
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
                InkWell(
                  onTap: () {
                    Get.back();
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
                const Text(
                  'Ignition',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ],
            ),
          ),

          // 2. Full Map View with Red Marker & Popup Dialog
          Expanded(
            child: Stack(
              children: [
                // OpenStreetMap Canvas
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(10.038, 76.325),
                    initialZoom: 13.5,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _isDialogVisible = !_isDialogVisible;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.airotrack.app',
                    ),
                    // Red Pin Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: const LatLng(10.044, 76.320),
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDialogVisible = !_isDialogVisible;
                              });
                            },
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 48,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Info Dialog Box Overlay matching reference screenshot
                if (_isDialogVisible)
                  Positioned(
                    left: 180,
                    bottom: 120,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 310,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Close 'X' Button
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isDialogVisible = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF2F4F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Color(0xFF344054),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Detail Field Rows
                            _buildDetailRow('Vehicle :', vehicle),
                            _buildDetailRow('Event :', isIgnitionOn ? 'Ignition On' : 'Ignition Off'),
                            _buildDetailRow('Position :', '11.612885°75.7601470°'),
                            _buildDetailRow('Altitude :', '8'),
                            _buildDetailRow('Angle :', '199°'),
                            _buildDetailRow('Speed :', '30 Mph'),
                            _buildDetailRow('Address :', 'Puthiyakavu Junction,Karunagappalli, Kerala'),
                            _buildDetailRow('Time :', timestamp),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D2939),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
