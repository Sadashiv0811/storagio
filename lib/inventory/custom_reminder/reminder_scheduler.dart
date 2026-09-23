import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(ref);
});

class ReminderScheduler {
  ReminderScheduler(this.ref);

  final Ref ref;

  Future<void> rescheduleAllReminders() async {
    final items = await ref.read(itemProvider.future);

    if (items.isEmpty) {
      return;
    }

    final reminderRepo = await ref.read(
      customReminderRepositoryProvider.future,
    );

    // Make isActive = false if it is one time reminder
    // Deactivate expired one-time reminders.
    reminderRepo.deactivateExpiredOneTimeReminders();

    final notificationService = NotificationService();

    for (final item in items) {
      final reminder = await reminderRepo.getReminderByItemId(item.id);

      if (reminder == null || !reminder.isActive) continue;

      await notificationService.scheduleRepeatingCustomNotification(
        itemId: item.id,
        itemName: item.name,
        content: reminder.content,
        startDate: reminder.startDate,
        intervalDays: reminder.intervalDays,
        isRepeat: reminder.intervalDays > 0,
      );
    }
  }
}
