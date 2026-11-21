/// A vehicle reminder from the API (vehicle_reminders / view_vehicle_reminder).
class ReminderItem {
  final String id;
  final String vehicleNumber;
  final String imei;

  /// Reminder type key (reminder_types `key`).
  final String typeKey;
  final String typeLabel;
  final num startOdometer;

  /// Odometer period (km) between reminders.
  final num periodKm;
  final String remarks;

  ReminderItem({
    required this.id,
    this.vehicleNumber = '',
    this.imei = '',
    this.typeKey = '',
    required this.typeLabel,
    this.startOdometer = 0,
    this.periodKm = 0,
    this.remarks = '',
  });

  /// Text shown in the Type column.
  String get type => typeLabel;

  /// Text shown in the Period column.
  String get period => '${formatNum(periodKm)} Km';

  static String formatNum(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  static num _num(dynamic v) => num.tryParse('${v ?? ''}') ?? 0;

  static String _str(dynamic v) {
    final s = (v ?? '').toString();
    return s == 'null' ? '' : s;
  }

  factory ReminderItem.fromJson(Map json) {
    return ReminderItem(
      id: _str(json['id']),
      vehicleNumber: _str(json['vehicle_number']),
      imei: _str(json['imei']),
      typeKey: _str(json['type']),
      typeLabel: _str(json['type_label'] ?? json['type']),
      startOdometer: _num(json['start_odometer']),
      periodKm: _num(json['period']),
      remarks: _str(json['remarks']),
    );
  }
}

class ReminderModel {
  final List<ReminderItem> reminders;

  ReminderModel({required this.reminders});
}
