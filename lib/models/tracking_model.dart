class TrackingCardData {
  final String registrationNumber;
  final int speedKmH;
  final String status;
  final String duration;
  final String timestamp;
  final String locationAddress;
  final String distanceKmText;
  final String validityText;
  final bool isGreenVehicle;
  final bool isLocked;
  final bool isRunning;

  TrackingCardData({
    required this.registrationNumber,
    required this.speedKmH,
    required this.status,
    required this.duration,
    required this.timestamp,
    required this.locationAddress,
    this.distanceKmText = '38.12 Km',
    this.validityText = '599 Days validity',
    this.isGreenVehicle = true,
    this.isLocked = false,
    this.isRunning = true,
  });
}

class TrackingModel {
  final List<TrackingCardData> trackingVehicles;

  TrackingModel({required this.trackingVehicles});
}
