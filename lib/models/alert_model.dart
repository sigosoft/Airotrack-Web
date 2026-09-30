class AlertModel {
  final int id;
  final String deviceName;
  final String plateNumber;
  final String date;
  final String type;
  final String address;
  final bool isIgnitionOn;

  AlertModel({
    required this.id,
    required this.deviceName,
    required this.plateNumber,
    required this.date,
    required this.type,
    required this.address,
    this.isIgnitionOn = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final veh = json['vehicle'];
    String vehicleNum = '';
    if (veh is Map) {
      vehicleNum = veh['vehicle_number']?.toString() ??
          veh['plate_number']?.toString() ??
          veh['vehicle_no']?.toString() ??
          veh['name']?.toString() ??
          '';
    }
    if (vehicleNum.isEmpty) {
      final dev = json['device'];
      if (dev is Map) {
        vehicleNum = dev['name']?.toString() ??
            dev['device_name']?.toString() ??
            dev['plate_number']?.toString() ??
            dev['vehicle_number']?.toString() ??
            '';
      }
    }
    if (vehicleNum.isEmpty) {
      vehicleNum = json['vehicle_number']?.toString() ??
          json['plate_number']?.toString() ??
          json['vehicle_no']?.toString() ??
          json['reg_no']?.toString() ??
          json['name']?.toString() ??
          json['vehicle_name']?.toString() ??
          json['device_name']?.toString() ??
          json['imei']?.toString() ??
          '';
    }

    final dateStr = json['datetime']?.toString() ??
        json['created_at']?.toString() ??
        json['device_time']?.toString() ??
        json['server_time']?.toString() ??
        json['time']?.toString() ??
        json['timestamp']?.toString() ??
        json['event_time']?.toString() ??
        json['date_time']?.toString() ??
        json['updated_at']?.toString() ??
        json['alert_time']?.toString() ??
        '';

    final typeStr = json['alert_description']?.toString() ??
        json['alert_type']?.toString() ??
        json['message']?.toString() ??
        json['title']?.toString() ??
        json['type']?.toString() ??
        json['event']?.toString() ??
        json['description']?.toString() ??
        '';

    String addrStr = json['address']?.toString() ??
        json['location']?.toString() ??
        json['formatted_address']?.toString() ??
        json['start_address']?.toString() ??
        json['addr']?.toString() ??
        '';

    if (addrStr.isEmpty) {
      final lat = json['latitude'] ?? json['lat'];
      final lng = json['longitude'] ?? json['lng'] ?? json['long'];
      if (lat != null && lng != null) {
        addrStr = "$lat, $lng";
      }
    }

    final lowerType = typeStr.toLowerCase();
    final bool isIgnOn = json['ignition'] == 1 ||
        json['ignition'] == true ||
        json['ignition'] == '1' ||
        json['is_ignition_on'] == true ||
        json['is_ignition_on'] == 1 ||
        json['status'] == '1' ||
        lowerType.contains('ignition on') ||
        lowerType.contains('engine on') ||
        (lowerType.contains('on') && !lowerType.contains('off'));

    return AlertModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      deviceName: vehicleNum,
      plateNumber: vehicleNum,
      date: dateStr,
      type: typeStr,
      address: addrStr,
      isIgnitionOn: isIgnOn,
    );
  }
}
