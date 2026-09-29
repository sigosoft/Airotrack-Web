class SensorReadingItem {
  final String label;
  final String value;
  final String iconType;

  SensorReadingItem({
    required this.label,
    required this.value,
    this.iconType = 'default',
  });
}

class VehicleDetailData {
  final String vehicleNumber;
  final String odometerDigits;
  final String timestamp;
  final String distanceKm;
  final int speedKmph;
  final String coordinates;
  final double? latitude;
  final double? longitude;
  final String address;
  final String deviceTime;
  final String serverTime;

  final String runningDuration;
  final String idleDuration;
  final String stoppedDuration;
  final String inactiveDuration;

  final String avgSpeedKmph;
  final String maxSpeedKmph;
  final String todayOdoKm;

  final List<SensorReadingItem> sensors;

  VehicleDetailData({
    required this.vehicleNumber,
    required this.odometerDigits,
    required this.timestamp,
    required this.distanceKm,
    required this.speedKmph,
    required this.coordinates,
    this.latitude,
    this.longitude,
    required this.address,
    required this.deviceTime,
    required this.serverTime,
    required this.runningDuration,
    required this.idleDuration,
    required this.stoppedDuration,
    required this.inactiveDuration,
    required this.avgSpeedKmph,
    required this.maxSpeedKmph,
    required this.todayOdoKm,
    required this.sensors,
  });

  VehicleDetailData copyWith({
    String? vehicleNumber,
    String? odometerDigits,
    String? timestamp,
    String? distanceKm,
    int? speedKmph,
    String? coordinates,
    double? latitude,
    double? longitude,
    String? address,
    String? deviceTime,
    String? serverTime,
    String? runningDuration,
    String? idleDuration,
    String? stoppedDuration,
    String? inactiveDuration,
    String? avgSpeedKmph,
    String? maxSpeedKmph,
    String? todayOdoKm,
    List<SensorReadingItem>? sensors,
  }) {
    return VehicleDetailData(
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      odometerDigits: odometerDigits ?? this.odometerDigits,
      timestamp: timestamp ?? this.timestamp,
      distanceKm: distanceKm ?? this.distanceKm,
      speedKmph: speedKmph ?? this.speedKmph,
      coordinates: coordinates ?? this.coordinates,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      deviceTime: deviceTime ?? this.deviceTime,
      serverTime: serverTime ?? this.serverTime,
      runningDuration: runningDuration ?? this.runningDuration,
      idleDuration: idleDuration ?? this.idleDuration,
      stoppedDuration: stoppedDuration ?? this.stoppedDuration,
      inactiveDuration: inactiveDuration ?? this.inactiveDuration,
      avgSpeedKmph: avgSpeedKmph ?? this.avgSpeedKmph,
      maxSpeedKmph: maxSpeedKmph ?? this.maxSpeedKmph,
      todayOdoKm: todayOdoKm ?? this.todayOdoKm,
      sensors: sensors ?? this.sensors,
    );
  }
}
