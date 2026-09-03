import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeofenceView extends StatefulWidget {
  const GeofenceView({super.key});

  @override
  State<GeofenceView> createState() => _GeofenceViewState();
}

class _GeofenceViewState extends State<GeofenceView> {
  int _selectedPage = 1;

  final List<Map<String, dynamic>> _geofenceList = [
    {
      'name': 'Vennakkad',
      'type': 'Circle',
      'address': 'Vennakkad,kerala',
      'description':
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
    },
    {
      'name': 'Kodakkad',
      'type': 'Circle',
      'address': 'Kodakkad,kerala',
      'description':
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
    },
  ];

  void _showAddGeofenceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AddGeofenceDialog(),
    );
  }

  void _showUpdateVehiclesDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const UpdateVehiclesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Header Bar (Search Geofence + Add Geofence Button)
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
                // Search Geofence Search Bar
                Container(
                  width: 320,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Search Geofence',
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

                // Add Geofence Button
                InkWell(
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
                ),
              ],
            ),
          ),

          // 2. Main Table Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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

                    // Table Rows
                    for (int i = 0; i < _geofenceList.length; i++) ...[
                      _buildTableRow(_geofenceList[i]),
                      if (i < _geofenceList.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFEAECF0),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Pagination Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 2,
            child: Text(
              item['name'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
          ),

          // Type Pill (Circle)
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
                    const Icon(
                      Icons.panorama_fish_eye_rounded,
                      size: 13,
                      color: Color(0xFF00A3E0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['type'],
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
              item['address'],
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
              item['description'],
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
                  if (value == 'Update Vehicles') {
                    _showUpdateVehiclesDialog(context);
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

class AddGeofenceDialog extends StatefulWidget {
  const AddGeofenceDialog({super.key});

  @override
  State<AddGeofenceDialog> createState() => _AddGeofenceDialogState();
}

class _AddGeofenceDialogState extends State<AddGeofenceDialog> {
  String _selectedShape = 'circle'; // 'circle', 'rectangle', 'polygon'

  final LatLng _center = const LatLng(10.038, 76.325);

  final List<LatLng> _rectanglePoints = const [
    LatLng(10.044, 76.315),
    LatLng(10.044, 76.335),
    LatLng(10.032, 76.335),
    LatLng(10.032, 76.315),
  ];

  final List<LatLng> _polygonPoints = const [
    LatLng(10.044, 76.325),
    LatLng(10.040, 76.335),
    LatLng(10.030, 76.330),
    LatLng(10.030, 76.315),
    LatLng(10.038, 76.312),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 880,
            height: 560,
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
            child: Row(
              children: [
                // Left Column: Map Area & Top Search Header (~58% Width)
                Expanded(
                  flex: 58,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Map Header Bar with Title & Search Input
                        Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.white,
                          child: Row(
                            children: [
                              const Text(
                                'Add Geofence',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F4F7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: const [
                                      Text(
                                        'Search for a Place',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF98A2B3),
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        Icons.search_rounded,
                                        size: 16,
                                        color: Color(0xFF667085),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Interactive Map Area
                        Expanded(
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: _center,
                                  initialZoom: 13.5,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.airotrack.app',
                                  ),
                                  if (_selectedShape == 'circle')
                                    CircleLayer(
                                      circles: [
                                        CircleMarker(
                                          point: _center,
                                          radius: 1200,
                                          useRadiusInMeter: true,
                                          color: const Color(0x3300A3E0),
                                          borderColor: const Color(0xFF00A3E0),
                                          borderStrokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                  if (_selectedShape == 'rectangle')
                                    PolygonLayer(
                                      polygons: [
                                        Polygon(
                                          points: _rectanglePoints,
                                          color: const Color(0x3300A3E0),
                                          borderColor: const Color(0xFF00A3E0),
                                          borderStrokeWidth: 2,
                                          isFilled: true,
                                        ),
                                      ],
                                    ),
                                  if (_selectedShape == 'polygon')
                                    PolygonLayer(
                                      polygons: [
                                        Polygon(
                                          points: _polygonPoints,
                                          color: const Color(0x3300A3E0),
                                          borderColor: const Color(0xFF00A3E0),
                                          borderStrokeWidth: 2,
                                          isFilled: true,
                                        ),
                                      ],
                                    ),
                                  if (_selectedShape == 'circle')
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _center,
                                          width: 12,
                                          height: 12,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00A3E0),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              // Floating Shape Selection Toolbar (Top-Right of Map)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildToolbarButton(
                                        icon: Icons.crop_free_rounded,
                                        isSelected: false,
                                        onTap: () {},
                                      ),
                                      _buildToolbarButton(
                                        icon: Icons.pentagon_outlined,
                                        isSelected: _selectedShape == 'polygon',
                                        onTap: () {
                                          setState(() {
                                            _selectedShape = 'polygon';
                                          });
                                        },
                                      ),
                                      _buildToolbarButton(
                                        icon: Icons.panorama_fish_eye_rounded,
                                        isSelected: _selectedShape == 'circle',
                                        onTap: () {
                                          setState(() {
                                            _selectedShape = 'circle';
                                          });
                                        },
                                      ),
                                      _buildToolbarButton(
                                        icon: Icons.crop_square_rounded,
                                        isSelected:
                                            _selectedShape == 'rectangle',
                                        onTap: () {
                                          setState(() {
                                            _selectedShape = 'rectangle';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Column: Form Controls Area (~42% Width)
                Expanded(
                  flex: 42,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: Color(0xFFEAECF0), width: 1),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field 1: Fence Name
                        _buildFormField(
                          label: 'Fence Name',
                          child: _buildTextInputField('Enter Fence Name'),
                        ),
                        const SizedBox(height: 12),

                        // Field 2: Event Type
                        _buildFormField(
                          label: 'Event Type',
                          child: _buildDropdownField('Entry'),
                        ),
                        const SizedBox(height: 12),

                        // Field 3: Address
                        _buildFormField(
                          label: 'Address',
                          child: _buildTextInputField('Enter your address'),
                        ),
                        const SizedBox(height: 12),

                        // Field 4: Description (Multiline)
                        _buildFormField(
                          label: 'Description',
                          child: Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEAECF0),
                                width: 1,
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Give a short description',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFB0B7C3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Field 5: Tolerance
                        _buildFormField(
                          label: 'Tolerance',
                          child: _buildDropdownField('5'),
                        ),
                        const Spacer(),

                        // Bottom Action Buttons (Cancel & Submit)
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  height: 38,
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
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D2939),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 12.5,
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
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3E0) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : const Color(0xFF667085),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildDropdownField(String valueStr) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Row(
        children: [
          Text(
            valueStr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF344054)),
          ),
          const Spacer(),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF98A2B3),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputField(String placeholder) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          placeholder,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB0B7C3)),
        ),
      ),
    );
  }
}

class UpdateVehiclesDialog extends StatefulWidget {
  const UpdateVehiclesDialog({super.key});

  @override
  State<UpdateVehiclesDialog> createState() => _UpdateVehiclesDialogState();
}

class _UpdateVehiclesDialogState extends State<UpdateVehiclesDialog> {
  bool _selectAll = false;
  final Map<String, bool> _vehicleSelection = {
    'KL 07 D 0518': true,
    'KL 07 D 6788': false,
    'KL 07 D 0510': false,
    'KL 07 Y 6000': false,
    'KL 07 D 9999': false,
    'KL 07 D 3333': false,
  };

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
            child: Column(
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
                Container(
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
                const SizedBox(height: 14),

                // Select All Row
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectAll = !_selectAll;
                      _vehicleSelection.updateAll((key, value) => _selectAll);
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
                Column(
                  children: _vehicleSelection.keys.map((vehicle) {
                    final isChecked = _vehicleSelection[vehicle] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _vehicleSelection[vehicle] = !isChecked;
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
                              vehicle,
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
                        onTap: () {
                          Navigator.of(context).pop();
                        },
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
            ),
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
