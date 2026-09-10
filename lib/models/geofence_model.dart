class GeofenceModel {
  final int id;
  final String name;
  final String type; // 'Circle' or 'Polygon'
  final String address;
  final String description;
  final double? latitude;
  final double? longitude;
  final double radius;
  final int tolerance;
  final String eventType;

  GeofenceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.description,
    this.latitude,
    this.longitude,
    this.radius = 0.0,
    this.tolerance = 0,
    this.eventType = 'both',
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    // Type conversion: 1 -> Circle, 2 -> Polygon, or String
    String rawType = 'Circle';
    final t = json['type'];
    if (t != null) {
      if (t.toString() == '1' || t.toString().toLowerCase() == 'circle') {
        rawType = 'Circle';
      } else if (t.toString() == '2' || t.toString().toLowerCase() == 'polygon') {
        rawType = 'Polygon';
      } else {
        rawType = t.toString();
      }
    }

    final lat = double.tryParse(json['latitude']?.toString() ?? json['lat']?.toString() ?? '');
    final lng = double.tryParse(json['longitude']?.toString() ?? json['lng']?.toString() ?? '');
    final rad = double.tryParse(json['radius']?.toString() ?? '0') ?? 0.0;
    final tol = int.tryParse(json['tolerance']?.toString() ?? '0') ?? 0;

    return GeofenceModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? json['geofence_name'] ?? '').toString(),
      type: rawType,
      address: (json['address'] ?? json['location'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      radius: rad,
      tolerance: tol,
      eventType: (json['event_type'] ?? 'both').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'tolerance': tolerance,
      'event_type': eventType,
    };
  }
}

class GeofenceVehicleItem {
  final int id;
  final String name;
  final String vehicleNumber;
  bool isSelected;

  GeofenceVehicleItem({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    this.isSelected = false,
  });

  factory GeofenceVehicleItem.fromJson(Map<String, dynamic> json, {bool isSelected = false}) {
    return GeofenceVehicleItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      vehicleNumber: (json['vehicle_number'] ?? json['plate_number'] ?? json['name'] ?? '').toString(),
      isSelected: isSelected,
    );
  }
}
