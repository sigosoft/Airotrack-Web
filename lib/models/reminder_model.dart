class ReminderItem {
  final String id;
  final String type;
  final String period;

  ReminderItem({
    required this.id,
    required this.type,
    required this.period,
  });
}

class ReminderModel {
  final List<ReminderItem> reminders;

  ReminderModel({required this.reminders});
}
