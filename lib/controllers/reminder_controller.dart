import 'package:get/get.dart';
import '../models/reminder_model.dart';
import '../utils/app_toast.dart';

class ReminderController extends GetxController {
  final RxInt currentPage = 1.obs;
  final RxString searchQuery = ''.obs;

  final RxList<ReminderItem> reminders = <ReminderItem>[
    ReminderItem(id: '1', type: 'Oil Change', period: '5000 Km'),
    ReminderItem(id: '2', type: 'Oil Change', period: '5000 Km'),
    ReminderItem(id: '3', type: 'Oil Change', period: '5000 Km'),
    ReminderItem(id: '4', type: 'Oil Change', period: '5000 Km'),
    ReminderItem(id: '5', type: 'Oil Change', period: '5000 Km'),
    ReminderItem(id: '6', type: 'Oil Change', period: '5000 Km'),
  ].obs;

  void changePage(int page) {
    currentPage.value = page;
  }

  void nextPage() {
    if (currentPage.value < 10) {
      currentPage.value++;
    }
  }

  void editReminder(ReminderItem item) {
    AppToast.show('Edit reminder: ${item.type}');
  }

  void deleteReminder(ReminderItem item) {
    reminders.removeWhere((element) => element.id == item.id);
    AppToast.show('Reminder deleted');
  }

  void addReminder() {
    AppToast.show('Add new reminder clicked');
  }
}
