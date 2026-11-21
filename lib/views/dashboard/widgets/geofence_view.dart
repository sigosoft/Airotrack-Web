import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/geofence_controller.dart';
import '../../../models/geofence_model.dart';
import 'geofence_editor_dialog.dart';

class GeofenceView extends StatefulWidget {
  const GeofenceView({super.key});

  @override
  State<GeofenceView> createState() => _GeofenceViewState();
}

class _GeofenceViewState extends State<GeofenceView> {
  int _selectedPage = 1;
  final TextEditingController _searchController = TextEditingController();
  late final GeofenceController _geofenceController;

  @override
  void initState() {
    super.initState();
    _geofenceController = Get.put(GeofenceController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddGeofenceDialog(BuildContext context, {GeofenceModel? geofence}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddGeofenceDialog(geofence: geofence),
    );
  }

  void _showUpdateVehiclesDialog(BuildContext context, int geofenceId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateVehiclesDialog(geofenceId: geofenceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Header Bar (Search Geofence + Add Geofence Button)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 768;

              Widget buildSearchBox({double? width}) {
                return SizedBox(
                  width: width,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      _geofenceController.searchQuery.value = val;
                    },
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1D2939),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search Geofence',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF98A2B3),
                      ),
                      suffixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF00A3E0), width: 1),
                      ),
                    ),
                  ),
                );
              }

              Widget buildAddGeofenceButton() {
                return InkWell(
                  onTap: () => _showAddGeofenceDialog(context),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Add Geofence',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 16 : 24,
                  vertical: isNarrow ? 10 : 11,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
                  ),
                ),
                child: isNarrow
                    ? Row(
                        children: [
                          Expanded(child: buildSearchBox()),
                          const SizedBox(width: 10),
                          buildAddGeofenceButton(),
                        ],
                      )
                    : SizedBox(
                        height: 38,
                        child: Row(
                          children: [
                            buildSearchBox(width: 320),
                            const Spacer(),
                            buildAddGeofenceButton(),
                          ],
                        ),
                      ),
              );
            },
          ),

          // 2. Main Table Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double tableWidth = constraints.maxWidth < 750
                      ? 750
                      : constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEAECF0),
                            width: 1,
                          ),
                        ),
                        child: Obx(() {
                          final items = _geofenceController.filteredGeofences;
                          final isLoading = _geofenceController.isLoading.value;

                          return Column(
                            children: [
                              // Table Header
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFEAECF0),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Name',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D2939),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Type',
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
                                        'Address',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D2939),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Description',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D2939),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Quick Actions',
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

                              // Table Rows Loading or Empty State
                              if (isLoading && items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00A3E0),
                                    ),
                                  ),
                                )
                              else if (items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No geofences found',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF667085),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                for (int i = 0; i < items.length; i++) ...[
                                  _buildTableRow(items[i]),
                                  if (i < items.length - 1)
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFEAECF0),
                                    ),
                                ],
                            ],
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Bottom Pagination Footer
          Obx(() {
            final items = _geofenceController.filteredGeofences;
            final pageCount = (items.length / 10).ceil();
            if (pageCount <= 1) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= pageCount; i++) ...[
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
                    if (_selectedPage < pageCount)
                      InkWell(
                        onTap: () {
                          if (_selectedPage < pageCount) {
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
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableRow(GeofenceModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 2,
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
          ),

          // Type Pill
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      switch (item.shape) {
                        'polygon' => Icons.pentagon_outlined,
                        'rectangle' => Icons.crop_square_rounded,
                        _ => Icons.panorama_fish_eye_rounded,
                      },
                      size: 13,
                      color: const Color(0xFF00A3E0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.type,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A3E0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Address
          Expanded(
            flex: 3,
            child: Text(
              item.address.isNotEmpty ? item.address : 'N/A',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
            ),
          ),

          // Description
          Expanded(
            flex: 4,
            child: Text(
              item.description.isNotEmpty ? item.description : 'No description',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quick Actions Popup Menu Button
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                tooltip: 'Quick Actions',
                offset: const Offset(0, 36),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: const Color(0xFF2B2E35),
                onSelected: (value) {
                  if (value == 'Edit Details') {
                    _showAddGeofenceDialog(context, geofence: item);
                  } else if (value == 'Update Vehicles') {
                    _showUpdateVehiclesDialog(context, item.id);
                  } else if (value == 'Delete') {
                    _geofenceController.deleteGeofence(item.id);
                  }
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 20,
                  color: Color(0xFF00A3E0),
                ),
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem('Edit Details'),
                  _buildPopupMenuItem('Update Vehicles'),
                  _buildPopupMenuItem('Delete'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title) {
    return PopupMenuItem<String>(
      value: title,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Color(0xFF98A2B3),
          ),
        ],
      ),
    );
  }
}

class UpdateVehiclesDialog extends StatefulWidget {
  final int geofenceId;
  const UpdateVehiclesDialog({super.key, required this.geofenceId});

  @override
  State<UpdateVehiclesDialog> createState() => _UpdateVehiclesDialogState();
}

class _UpdateVehiclesDialogState extends State<UpdateVehiclesDialog> {
  bool _selectAll = false;
  late final GeofenceController _geofenceController;
  final Set<int> _selectedVehicleIds = {};
  String _vehicleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _geofenceController = Get.find<GeofenceController>();
    _geofenceController.fetchGeofenceVehicles(widget.geofenceId).then((_) {
      if (mounted) {
        setState(() {
          for (final item in _geofenceController.syncedVehicles) {
            _selectedVehicleIds.add(item.id);
          }
        });
      }
    });
  }

  Future<void> _submitSync() async {
    final success = await _geofenceController.syncGeofenceVehicles(
      widget.geofenceId,
      _selectedVehicleIds.toList(),
      previouslySynced: _geofenceController.syncedVehicles
          .map((v) => v.id)
          .toList(),
    );
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() {
              final allItems = [
                ..._geofenceController.syncedVehicles,
                ..._geofenceController.unsyncedVehicles,
              ];

              final filteredItems = allItems.where((v) {
                if (_vehicleSearchQuery.trim().isEmpty) return true;
                final q = _vehicleSearchQuery.trim().toLowerCase();
                return v.vehicleNumber.toLowerCase().contains(q) || v.name.toLowerCase().contains(q);
              }).toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title
                  const Text(
                    'Update Vehicles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Vehicles Bar
                  SizedBox(
                    height: 38,
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _vehicleSearchQuery = val;
                        });
                      },
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1D2939)),
                      decoration: InputDecoration(
                        hintText: 'Search Vehicles',
                        hintStyle: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF98A2B3),
                        ),
                        suffixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF667085),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F4F7),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFF00A3E0), width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Select All Row
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectAll = !_selectAll;
                        if (_selectAll) {
                          for (final item in filteredItems) {
                            _selectedVehicleIds.add(item.id);
                          }
                        } else {
                          _selectedVehicleIds.clear();
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _selectAll
                                ? const Color(0xFF00A3E0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: _selectAll
                                  ? const Color(0xFF00A3E0)
                                  : const Color(0xFFD0D5DD),
                              width: 1.5,
                            ),
                          ),
                          child: _selectAll
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Vehicle Checkbox Items List
                  if (_geofenceController.isVehicleLoading.value)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF00A3E0)),
                      ),
                    )
                  else if (filteredItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No vehicles available',
                        style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: Column(
                          children: filteredItems.map((item) {
                            final isChecked = _selectedVehicleIds.contains(item.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      _selectedVehicleIds.remove(item.id);
                                    } else {
                                      _selectedVehicleIds.add(item.id);
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? const Color(0xFF00A3E0)
                                            : const Color(0xFFD0D5DD),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: isChecked
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item.vehicleNumber.isNotEmpty
                                          ? item.vehicleNumber
                                          : item.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D2939),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Action Buttons Row (Cancel & Submit)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEAECF0),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _submitSync,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
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
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),

          // Floating Close 'X' Button on Top-Right Corner
          Positioned(
            top: -12,
            right: -12,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD0D5DD),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF1D2939),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
