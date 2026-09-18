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
          veh['name']?.toString() ??
          '';
    }
    if (vehicleNum.isEmpty) {
      vehicleNum = json['vehicle_number']?.toString() ??
          json['plate_number']?.toString() ??
          json['name']?.toString() ??
          json['vehicle_name']?.toString() ??
          json['device_name']?.toString() ??
          json['imei']?.toString() ??
          '';
    }

    final dateStr = json['datetime']?.toString() ??
        json['created_at']?.toString() ??
        json['time']?.toString() ??
        json['timestamp']?.toString() ??
        json['event_time']?.toString() ??
        json['date_time']?.toString() ??
        '';

    final typeStr = json['alert_description']?.toString() ??
        json['alert_type']?.toString() ??
        json['type']?.toString() ??
        json['event']?.toString() ??
        json['title']?.toString() ??
        '';

    final addrStr = json['address']?.toString() ??
        json['location']?.toString() ??
        json['start_address']?.toString() ??
        (json['latitude'] != null
            ? "${json['latitude']}, ${json['longitude']}"
            : '');

    final bool isIgnOn = json['ignition'] == 1 ||
        json['ignition'] == true ||
        json['is_ignition_on'] == true ||
        typeStr.toLowerCase().contains('on');

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
