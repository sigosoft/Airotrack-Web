class NotificationItemData {
  final String vehicleNumber;
  final String ignitionStatus;
  final bool isIgnitionOn;
  final String locationAddress;
  final String timestamp;

  NotificationItemData({
    required this.vehicleNumber,
    required this.ignitionStatus,
    required this.isIgnitionOn,
    required this.locationAddress,
    required this.timestamp,
  });
}

class NotificationModel {
  final List<NotificationItemData> notifications;

  NotificationModel({required this.notifications});
}
