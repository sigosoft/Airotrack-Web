import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/geofence_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import '../../../models/geofence_model.dart';
import '../../../utils/app_toast.dart';

/// Track > Select Geofence: tick the geofences this vehicle should be linked
/// to (vehicle_synced_geofences / vehicle_unsynced_geofences), Submit syncs
/// them (sync_vehicle_geofences), the same as the mobile app.
class SelectGeofenceDialog extends StatefulWidget {
  const SelectGeofenceDialog({super.key});

  @override
  State<SelectGeofenceDialog> createState() => _SelectGeofenceDialogState();
}

class _SelectGeofenceDialogState extends State<SelectGeofenceDialog> {
  static const _blue = Color(0xFF00A3E0);

  final TextEditingController searchController = TextEditingController();
  late final GeofenceController _controller;
  int? _vehicleId;
  String _vehicleNumber = '';
  String _searchQuery = '';
  final Set<int> _selected = {};
  List<int> _initiallySynced = const [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<GeofenceController>()
        ? Get.find<GeofenceController>()
        : Get.put(GeofenceController());
    if (Get.isRegistered<VehicleDetailController>() &&
        Get.isRegistered<HomeController>()) {
      final imei = Get.find<VehicleDetailController>().activeImei;
      final v = Get.find<HomeController>().vehicles.firstWhereOrNull(
        (veh) => veh.deviceId == imei,
      );
      _vehicleId = v?.id;
      _vehicleNumber = v?.plateNumber ?? '';
    }
    searchController.addListener(() {
      setState(() => _searchQuery = searchController.text.trim().toLowerCase());
    });
    _load();
  }

  Future<void> _load() async {
    final id = _vehicleId;
    if (id == null) return;
    await _controller.fetchVehicleGeofenceLists(id);
    if (!mounted) return;
    setState(() {
      _initiallySynced = _controller.vehicleSyncedGeofencesList
          .map((g) => g.id)
          .toList();
      _selected
        ..clear()
        ..addAll(_initiallySynced);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<GeofenceModel> get _all => [
    ..._controller.vehicleSyncedGeofencesList,
    ..._controller.vehicleUnsyncedGeofencesList,
  ];

  List<GeofenceModel> get _filtered {
    if (_searchQuery.isEmpty) return _all;
    return _all
        .where(
          (g) =>
              g.name.toLowerCase().contains(_searchQuery) ||
              g.address.toLowerCase().contains(_searchQuery) ||
              g.type.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  Future<void> _submit() async {
    final id = _vehicleId;
    if (id == null) {
      AppToast.show('Vehicle id not available', isError: true);
      return;
    }
    final now = _selected.toSet();
    if (now.length == _initiallySynced.length &&
        now.containsAll(_initiallySynced)) {
      Get.back();
      return;
    }
    setState(() => _isSubmitting = true);
    final ok = await _controller.syncVehicleGeofences(
      id,
      now.toList()..sort(),
      previouslySynced: _initiallySynced,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isMobile = screen.width < 768;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: 480,
        constraints: BoxConstraints(maxHeight: screen.height - 40),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Geofence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2939),
                        ),
                      ),
                      if (_vehicleNumber.isNotEmpty)
                        Text(
                          _vehicleNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                    ],
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
                  borderSide: const BorderSide(color: Color(0xFFEAECF0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _blue, width: 1.5),
                ),
                suffixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF98A2B3),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Obx(() {
                if (_controller.isVehicleGeofencesLoading.value &&
                    !_isSubmitting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(color: _blue),
                    ),
                  );
                }
                // Touch the lists so Obx rebuilds when they load.
                _controller.vehicleSyncedGeofencesList.length;
                _controller.vehicleUnsyncedGeofencesList.length;
                final list = _filtered;
                if (_vehicleId == null || list.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Center(
                      child: Text(
                        _vehicleId == null
                            ? 'Vehicle id not available'
                            : 'No geofences found',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (_, i) => _tile(list[i]),
                );
              }),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
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
                      onPressed: _isSubmitting || _vehicleId == null
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        disabledBackgroundColor: const Color(0xFF7FD1EF),
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
    );
  }

  Widget _tile(GeofenceModel item) {
    final checked = _selected.contains(item.id);
    final location = item.address.isNotEmpty
        ? item.address
        : (item.description.isNotEmpty
              ? item.description
              : 'Location unavailable');
    return InkWell(
      onTap: () => setState(() {
        if (!_selected.remove(item.id)) _selected.add(item.id);
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: checked ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: checked ? _blue : const Color(0xFFEAECF0),
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              switch (item.shape) {
                'polygon' => Icons.pentagon_outlined,
                'rectangle' => Icons.crop_square_rounded,
                _ => Icons.panorama_fish_eye_rounded,
              },
              size: 18,
              color: _blue,
            ),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 4),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? _blue : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked ? _blue : const Color(0xFFD0D5DD),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
