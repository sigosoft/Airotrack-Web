import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../controllers/geofence_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/geofence_model.dart';
import '../../../services/app_settings.dart';
import '../../../services/place_search_service.dart';

/// Add / Edit Geofence, matching the mobile app: search a place, pan the
/// map (the fence sits at the centre), pick circle / rectangle / polygon,
/// set its size, event type and tolerance.
class AddGeofenceDialog extends StatefulWidget {
  final GeofenceModel? geofence;
  const AddGeofenceDialog({super.key, this.geofence});

  @override
  State<AddGeofenceDialog> createState() => _AddGeofenceDialogState();
}

class _AddGeofenceDialogState extends State<AddGeofenceDialog> {
  static const _blue = Color(0xFF00A3E0);
  static const _tolerances = [5, 10, 15, 20, 30, 50];
  static const double _minSize = 50;
  static const double _maxSize = 5000;

  final _mapController = MapController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  String _shape = 'circle';
  LatLng _center = const LatLng(10.0159, 76.3419);

  /// Circle radius, or half the width of a rectangle / polygon, in metres.
  double _size = 120;

  /// A saved rectangle / polygon keeps its own corners (moved with the map
  /// centre) until the shape or size is changed.
  List<LatLng>? _savedPoints;
  LatLng? _savedAnchor;

  int _eventCode = 3;
  int _tolerance = 5;
  String? _nameError;

  Timer? _searchDebounce;
  int _searchSeq = 0;
  bool _searching = false;
  List<PlaceSearchResult> _suggestions = const [];

  bool get _isEdit => widget.geofence != null;

  @override
  void initState() {
    super.initState();
    final g = widget.geofence;
    if (g != null) {
      _shape = g.shape;
      _nameController.text = g.name;
      _addressController.text = g.address;
      _descriptionController.text = g.description;
      _eventCode = g.eventCode;
      final tol = g.toleranceMeters.round();
      _tolerance = _tolerances.reduce(
        (a, b) => (a - tol).abs() <= (b - tol).abs() ? a : b,
      );
      _center = g.center ?? _center;
      if (g.shape == 'circle') {
        if (g.radiusMeters > 0) _size = g.radiusMeters;
      } else if (g.outline.length >= 3) {
        _savedPoints = g.outline;
        _savedAnchor = _center;
        _size = g.outline
            .map((p) => const Distance().as(LengthUnit.Meter, _center, p))
            .reduce(math.max);
      }
      _size = _size.clamp(_minSize, _maxSize);
    } else {
      _center = _defaultCenter() ?? _center;
    }
  }

  /// Where the first vehicle with a position is, for a new fence.
  LatLng? _defaultCenter() {
    if (!Get.isRegistered<HomeController>()) return null;
    for (final v in Get.find<HomeController>().vehicles) {
      if (v.latitude != null &&
          v.longitude != null &&
          (v.latitude != 0 || v.longitude != 0)) {
        return LatLng(v.latitude!, v.longitude!);
      }
    }
    return null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Shape geometry
  // ---------------------------------------------------------------------

  static double _dLat(double m) => m / 111320.0;
  static double _dLng(double m, double lat) =>
      m / (111320.0 * math.cos(lat * math.pi / 180).abs().clamp(0.01, 1));

  List<LatLng> get _points {
    if (_shape == 'circle') return const [];
    final saved = _savedPoints;
    final anchor = _savedAnchor;
    if (saved != null && anchor != null) {
      final dy = _center.latitude - anchor.latitude;
      final dx = _center.longitude - anchor.longitude;
      return saved
          .map((p) => LatLng(p.latitude + dy, p.longitude + dx))
          .toList();
    }
    final c = _center;
    if (_shape == 'rectangle') {
      final la = _dLat(_size);
      final ln = _dLng(_size, c.latitude);
      return [
        LatLng(c.latitude + la, c.longitude - ln),
        LatLng(c.latitude + la, c.longitude + ln),
        LatLng(c.latitude - la, c.longitude + ln),
        LatLng(c.latitude - la, c.longitude - ln),
      ];
    }
    // Polygon: a pentagon around the centre (as the mobile app draws).
    return List.generate(5, (i) {
      final a = (2 * math.pi * i / 5) - math.pi / 2;
      return LatLng(
        c.latitude + _dLat(_size) * math.cos(a),
        c.longitude + _dLng(_size, c.latitude) * math.sin(a),
      );
    });
  }

  /// What the API stores: rectangle = two opposite corners, polygon = all.
  List<LatLng> get _apiCoordinates {
    final pts = _points;
    if (_shape == 'rectangle' && pts.length == 4) {
      final r = GeofenceModel.rectangleFromCorners(pts[0], pts[2]);
      return [r[0], r[2]];
    }
    return pts;
  }

  void _setShape(String shape) {
    if (shape == _shape) return;
    setState(() {
      _shape = shape;
      _savedPoints = null;
      _savedAnchor = null;
    });
  }

  // ---------------------------------------------------------------------
  // Place search
  // ---------------------------------------------------------------------

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _searching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final seq = ++_searchSeq;
      setState(() => _searching = true);
      final results = await PlaceSearchService.instance.search(
        text,
        proximity: _center,
      );
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    });
  }

  void _pickPlace(PlaceSearchResult place) {
    _searchSeq++;
    setState(() {
      _center = place.location;
      _suggestions = const [];
      _searching = false;
      _searchController.text = place.name;
      if (_addressController.text.trim().isEmpty) {
        _addressController.text = place.address;
      }
    });
    _mapController.move(place.location, 16);
  }

  // ---------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Geofence name is required');
      return;
    }
    setState(() => _nameError = null);
    final ok = await Get.find<GeofenceController>().saveGeofence(
      id: widget.geofence?.id,
      name: name,
      shape: _shape,
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      center: _center,
      radiusMeters: _size,
      coordinates: _apiCoordinates,
      toleranceMeters: _tolerance,
      eventCode: _eventCode,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  String get _sizeLabel {
    final m = _size;
    final text = m >= 1000
        ? '${(m / 1000).toStringAsFixed(2)} km'
        : '${m.round()} m';
    return _shape == 'circle' ? 'Radius: $text' : 'Size: $text';
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isMobile = screen.width < 768;

    final dialogBody = isMobile
        ? SingleChildScrollView(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(height: 360, child: _mapSection(true)),
                ),
                _formSection(isMobile),
              ],
            ),
          )
        : Row(
            children: [
              Expanded(
                flex: 58,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: _mapSection(false),
                ),
              ),
              Expanded(flex: 42, child: _formSection(isMobile)),
            ],
          );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: isMobile ? screen.width - 24 : 920,
            height: isMobile ? null : 600,
            constraints: isMobile
                ? BoxConstraints(maxHeight: screen.height - 32)
                : null,
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
            child: dialogBody,
          ),
          Positioned(
            top: isMobile ? 11 : -12,
            right: isMobile ? 10 : -12,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD0D5DD),
                    width: 1.5,
                  ),
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

  Widget _mapSection(bool isMobileLayout) {
    final points = _points;
    return Column(
      children: [
        Container(
          height: 54,
          padding: EdgeInsets.only(left: 16, right: isMobileLayout ? 48 : 16),
          alignment: Alignment.centerLeft,
          color: Colors.white,
          child: Text(
            _isEdit ? 'Edit Geofence' : 'Add Geofence',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: _size > 1500 ? 13 : 15.5,
                  onPositionChanged: (pos, hasGesture) {
                    final c = pos.center;
                    if (hasGesture && c != null) setState(() => _center = c);
                  },
                  onTap: (_, point) {
                    setState(() {
                      _center = point;
                      _suggestions = const [];
                    });
                    _mapController.move(point, _mapController.camera.zoom);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppSettings.to.tileUrl,
                    subdomains: AppSettings.tileSubdomains,
                    userAgentPackageName: 'com.airotrack.app',
                  ),
                  if (_shape == 'circle')
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _center,
                          radius: _size,
                          useRadiusInMeter: true,
                          color: const Color(0x3300A3E0),
                          borderColor: _blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    )
                  else
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: points,
                          color: const Color(0x3300A3E0),
                          borderColor: _blue,
                          borderStrokeWidth: 2,
                          isFilled: true,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _center,
                        width: 14,
                        height: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Place search
              Positioned(
                top: 12,
                left: 12,
                right: 64,
                child: _searchBox(),
              ),
              // Shape picker
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      _shapeButton('circle', Icons.panorama_fish_eye_rounded, 'Circle'),
                      _shapeButton('rectangle', Icons.crop_square_rounded, 'Rectangle'),
                      _shapeButton('polygon', Icons.pentagon_outlined, 'Polygon'),
                    ],
                  ),
                ),
              ),
              // Size slider
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          _sizeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          // Log scale so small fences are easy to set.
                          value: math.log(_size),
                          min: math.log(_minSize),
                          max: math.log(_maxSize),
                          activeColor: _blue,
                          onChanged: (v) => setState(() {
                            _size = math.exp(v).roundToDouble();
                            _savedPoints = null;
                            _savedAnchor = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x1F000000), blurRadius: 8),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF1D2939)),
            decoration: InputDecoration(
              hintText: 'Search Location',
              hintStyle: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF98A2B3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _blue,
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF667085),
                    ),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0x1F000000), blurRadius: 8),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFEAECF0)),
              itemBuilder: (_, i) {
                final p = _suggestions[i];
                return InkWell(
                  onTap: () => _pickPlace(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: _blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                              Text(
                                p.address,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _shapeButton(String shape, IconData icon, String tooltip) {
    final selected = _shape == shape;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _setShape(shape),
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  Widget _formSection(bool isMobile) {
    final controller = Get.find<GeofenceController>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isMobile
            ? const Border(top: BorderSide(color: Color(0xFFEAECF0)))
            : const Border(left: BorderSide(color: Color(0xFFEAECF0))),
        borderRadius: isMobile
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : const BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(
              'Fence Name',
              _input(_nameController, 'Enter Fence Name', error: _nameError),
            ),
            const SizedBox(height: 12),
            _field(
              'Event Type',
              _dropdown<int>(
                value: _eventCode,
                items: GeofenceModel.eventLabels,
                onChanged: (v) => setState(() => _eventCode = v),
              ),
            ),
            const SizedBox(height: 12),
            _field('Address', _input(_addressController, 'Enter your address')),
            const SizedBox(height: 12),
            _field(
              'Description',
              _input(
                _descriptionController,
                'Give a short description',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            _field(
              'Tolerance',
              _dropdown<int>(
                value: _tolerance,
                items: {for (final t in _tolerances) t: '$t m'},
                onChanged: (v) => setState(() => _tolerance = v),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      side: const BorderSide(color: Color(0xFFEAECF0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isSaving.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: _blue,
                        disabledBackgroundColor: const Color(0xFF7FD1EF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) => Column(
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

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: c, width: w),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    String? error,
  }) => TextField(
    controller: c,
    maxLines: maxLines,
    onChanged: error != null ? (_) => setState(() => _nameError = null) : null,
    style: const TextStyle(fontSize: 12, color: Color(0xFF1D2939)),
    decoration: InputDecoration(
      hintText: hint,
      errorText: error,
      isDense: true,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB0B7C3)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: _border(const Color(0xFFEAECF0)),
      focusedBorder: _border(_blue),
      errorBorder: _border(const Color(0xFFF04438)),
      focusedErrorBorder: _border(const Color(0xFFF04438)),
    ),
  );

  Widget _dropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) => Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFEAECF0)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: items.containsKey(value) ? value : items.keys.first,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: Color(0xFF98A2B3),
        ),
        items: items.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF344054),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}
