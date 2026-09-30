import 'alert_model.dart';

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

  factory NotificationItemData.fromAlertModel(AlertModel alert) {
    return NotificationItemData(
      vehicleNumber: alert.plateNumber.isNotEmpty
          ? alert.plateNumber
          : (alert.deviceName.isNotEmpty ? alert.deviceName : 'Vehicle'),
      ignitionStatus: alert.type.isNotEmpty
          ? alert.type
          : (alert.isIgnitionOn ? 'Ignition On' : 'Ignition Off'),
      isIgnitionOn: alert.isIgnitionOn,
      locationAddress: alert.address.isNotEmpty
          ? alert.address
          : 'Location unavailable',
      timestamp: alert.date.isNotEmpty ? alert.date : 'N/A',
    );
  }

  factory NotificationItemData.fromJson(Map<String, dynamic> json) {
    return NotificationItemData.fromAlertModel(AlertModel.fromJson(json));
  }
}

class NotificationModel {
  final List<NotificationItemData> notifications;

  NotificationModel({required this.notifications});
}
