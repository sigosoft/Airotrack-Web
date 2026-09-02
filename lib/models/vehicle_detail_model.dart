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
}
