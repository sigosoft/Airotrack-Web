import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData;

import '../../../config/api_config.dart';
import '../../../config/dio_client.dart';
import '../../../controllers/geofence_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import '../../../models/geofence_model.dart';
import '../../../utils/app_toast.dart';

class SelectGeofenceDialog extends StatefulWidget {
  const SelectGeofenceDialog({super.key});

  @override
  State<SelectGeofenceDialog> createState() => _SelectGeofenceDialogState();
}

class _SelectGeofenceDialogState extends State<SelectGeofenceDialog> {
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<GeofenceModel> _allGeofences = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchGeofences();
    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text.trim().toLowerCase();
        selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Calls GET /geofences API
  Future<void> _fetchGeofences() async {
    setState(() => _isLoading = true);
    try {
      final response = await DioClient().get(
        ApiEndPoints.geofences,
        queryParameters: {'limit': '50'},
      );

      if (response.data != null) {
        final data = response.data;
        List<dynamic>? rawList;

        if (data is Map) {
          if (data['data'] != null && data['data'] is Map) {
            rawList = data['data']['geofences'] as List<dynamic>?;
          } else if (data['data'] is List) {
            rawList = data['data'] as List<dynamic>?;
          } else if (data['geofences'] is List) {
            rawList = data['geofences'] as List<dynamic>?;
          }
        }

        if (rawList != null) {
          _allGeofences = rawList
              .map(
                (json) => GeofenceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SelectGeofenceDialog] Error fetching geofences: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<GeofenceModel> get _filteredGeofences {
    if (_searchQuery.isEmpty) return _allGeofences;
    return _allGeofences.where((g) {
      return g.name.toLowerCase().contains(_searchQuery) ||
          g.address.toLowerCase().contains(_searchQuery) ||
          g.type.toLowerCase().contains(_searchQuery) ||
          g.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  /// Calls POST /add_geofence API
  Future<void> _submitGeofence() async {
    final list = _filteredGeofences;
    if (list.isEmpty || selectedIndex < 0 || selectedIndex >= list.length) {
      AppToast.show('Please select a geofence', isError: true);
      return;
    }

    final selected = list[selectedIndex];
    setState(() => _isSubmitting = true);

    try {
      int? vehicleId;
      if (Get.isRegistered<VehicleDetailController>()) {
        final vCtrl = Get.find<VehicleDetailController>();
        if (Get.isRegistered<HomeController>()) {
          final homeCtrl = Get.find<HomeController>();
          final v = homeCtrl.vehicles.firstWhereOrNull(
            (veh) => veh.deviceId == vCtrl.activeImei,
          );
          if (v != null) vehicleId = v.id;
        }
      }

      final typeInt = selected.type.toLowerCase() == 'polygon' ? 2 : 1;
      final bodyMap = <String, dynamic>{
        'name': selected.name,
        'type': typeInt,
        'tolerance': selected.tolerance,
        'event_type':
            selected.eventType.isNotEmpty ? selected.eventType : 'both',
        'address': selected.address,
        'description': selected.description,
        'latitude': selected.latitude ?? 0.0,
        'longitude': selected.longitude ?? 0.0,
        'radius': selected.radius > 0 ? selected.radius : 500.0,
      };

      if (selected.id > 0) {
        bodyMap['geofence_id'] = selected.id;
      }
      if (vehicleId != null) {
        bodyMap['vehicle_id'] = vehicleId;
        bodyMap['vehicle_ids'] = [vehicleId];
      }

      final formData = FormData.fromMap(bodyMap);

      final response = await DioClient().post(
        ApiEndPoints.addGeofence,
        body: formData,
      );

      if (response.data != null &&
          (response.data['status'] == true ||
              response.data['success'] == true)) {
        AppToast.show(
          response.data['message']?.toString() ??
              'Geofence added successfully',
        );
        if (Get.isRegistered<GeofenceController>()) {
          Get.find<GeofenceController>().fetchGeofences();
        }
        if (mounted) {
          Get.back();
        }
      } else {
        final msg = response.data?['message']?.toString() ??
            'Failed to add geofence';
        AppToast.show(msg, isError: true);
      }
    } catch (e) {
      debugPrint('[SelectGeofenceDialog] Error adding geofence: $e');
      AppToast.showErrorMessage(e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isMobile = screenWidth < 768;
    final displayList = _filteredGeofences;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: 480,
        constraints: BoxConstraints(maxHeight: screenHeight - 40),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Close 'X' Icon Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Geofence',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F4F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Single Seamless Search Geofence Input Bar
              TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
                decoration: InputDecoration(
                  hintText: 'Search Geofence',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF98A2B3),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFFEAECF0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFF00A3E0),
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF98A2B3),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Geofence Option Cards Stack (Dynamic from GET /geofences)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00A3E0),
                    ),
                  ),
                )
              else if (displayList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No geofences found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(displayList.length, (index) {
                    final isSelected = selectedIndex == index;
                    final item = displayList[index];
                    final locationText = item.address.isNotEmpty
                        ? item.address
                        : (item.description.isNotEmpty
                            ? item.description
                            : 'Location unavailable');

                    return InkWell(
                      onTap: () => setState(() => selectedIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0F9FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00A3E0)
                                : const Color(0xFFEAECF0),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D2939),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 13,
                                        color: Color(0xFF667085),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          locationText,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF667085),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Radio Button Indicator
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00A3E0)
                                      : const Color(0xFFD0D5DD),
                                  width: isSelected ? 6 : 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 14),

              // 4. Bottom Action Buttons Row (Cancel vs Submit)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFD0D5DD),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitGeofence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
