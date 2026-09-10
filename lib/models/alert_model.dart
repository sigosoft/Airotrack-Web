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
    return AlertModel(
      id: 0,
      deviceName: json['vehicle_number'] ?? '',
      plateNumber: json['vehicle_number'] ?? '',
      date: json['datetime'] ?? '',
      type: json['alert_description'] ?? json['alert_type'] ?? '',
      address:
          json['address'] ??
          (json['latitude'] != null
              ? "${json['latitude']}, ${json['longitude']}"
              : ''),
      isIgnitionOn: json['ignition'] == 1,
    );
  }
}
