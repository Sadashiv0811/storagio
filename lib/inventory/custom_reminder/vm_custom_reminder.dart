import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/custom_reminder/m_custom_reminder.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/inventory/item/r_item.dart';
import 'package:uuid/uuid.dart';

final customReminderVMProvider =
    ChangeNotifierProvider.autoDispose<CustomReminderViewModel>((ref) {
      return CustomReminderViewModel(ref);
    });

final reminderActiveOrNotProvider = FutureProvider.family
    .autoDispose<bool, String>((ref, itemId) async {
      return ref
          .read(customReminderVMProvider)
          .checkReminderActiveByItemId(itemId);
    });

final reminderExistsProvider = FutureProvider.family.autoDispose<bool, String>((
  ref,
  itemId,
) async {
  return ref.read(customReminderVMProvider).reminderExistsForItem(itemId);
});

class CustomReminderViewModel extends ChangeNotifier {
  CustomReminderViewModel(this.ref);

  final Ref ref;
  final formKey = GlobalKey<FormState>();

  // State variables
  DateTime? _selectedDateTime;
  bool _repeatReminder = false;
  String? _existingReminderId;

  // Controllers 
  final contentController = TextEditingController();
  final daysController = TextEditingController();
  final FocusNode contentFN = FocusNode();

  // Getters to expose state securely
  DateTime? get selectedDateTime => _selectedDateTime;
  bool get repeatReminder => _repeatReminder;
  bool get isEditing => _existingReminderId != null; 

  /// Called when entering the screen in EDIT mode
  void setReminderForEdit(CustomReminder reminder) {
    _existingReminderId = reminder.id;
    _selectedDateTime = reminder.startDate;
    _repeatReminder = reminder.intervalDays > 0;

    contentController.text = reminder.content;
    daysController.text = reminder.intervalDays > 0
        ? reminder.intervalDays.toString()
        : '';

    notifyListeners();
  }

  /// Called when creating a fresh reminder to clear previous edit states
  void resetForm() {
    _existingReminderId = null;
    _selectedDateTime = null;
    _repeatReminder = false;
    contentController.clear();
    daysController.clear();
    notifyListeners();
  }

  // Pick Date and Time Business Logic
  Future<void> pickDateTime(BuildContext context) async {
    contentFN.nextFocus();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Prevent the date picker from receiving a date before firstDate.
    final DateTime initialDate =
        _selectedDateTime != null && !_selectedDateTime!.isBefore(today)
        ? _selectedDateTime!
        : today;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 70),
    );

    if (pickedDate == null || !context.mounted) return;

    // If the reminder is still in the future, preserve its time.
    // Otherwise, start from the current time.
    final TimeOfDay initialTime =
        _selectedDateTime != null && _selectedDateTime!.isAfter(now)
        ? TimeOfDay.fromDateTime(_selectedDateTime!)
        : TimeOfDay.fromDateTime(now);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !context.mounted) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Prevent selecting a time in the past when today's date is chosen.
    if (selectedDateTime.isBefore(now) && context.mounted) {
      showSnackBar(
        
        'Please select a future date and time.',
        backgroundColor: Colors.red,
      );

      return;
    }

    _selectedDateTime = selectedDateTime;
    notifyListeners();
  }

  // Toggle repeat setting
  void setRepeatReminder(bool value) {
    _repeatReminder = value;
    if (!_repeatReminder) {
      daysController.clear();
    }
    notifyListeners();
  }

  // Save/Submit method
  void saveReminder({
    required String itemId,
    required String itemName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (formKey.currentState?.validate() ?? false) {
      // Check if date and time are null
      if (selectedDateTime == null) {
        onError("Date and time not set");
        return;
      }

      // Check if the selected date and time are in the past
      if (selectedDateTime!.isBefore(DateTime.now())) {
        onError("Cannot set a reminder in the past");
        return;
      }

      if (_repeatReminder && daysController.text.isEmpty) {
        onError("Please specify repeat interval");
        return;
      }

      // Securely formatted matching your preferred presentation style
      final formattedTime = DateFormat(
        'yyyy-MM-dd hh:mm a',
      ).format(_selectedDateTime!);

      logger.d('''
        Title: $itemName
        Content: ${contentController.text}
        Time: $formattedTime
        Repeating: $_repeatReminder
        ${_repeatReminder ? "Repeat every: ${daysController.text} days" : "0"}
      ''');

      try {
        // Calculate interval safely
        final interval = _repeatReminder ? int.parse(daysController.text) : 0;
        final notifierService = NotificationService();

        // CANCEL OLD NOTIFICATIONS FIRST
        // This stops ghost alarms if the user changed the date/interval
        await notifierService.cancelRepeatingCustomNotification(itemId);

        // REUSE ID IF EDITING, OTHERWISE GENERATE NEW
        final reminderId = _existingReminderId ?? const Uuid().v4();

        // Create the Database Object
        final newReminder = CustomReminder(
          id: reminderId,
          itemId: itemId,
          content: contentController.text,
          startDate: selectedDateTime!,
          intervalDays: interval,
          isActive: true,
          synced: false
        );

        // Save to SQLite via Repository
        final repo = await ref.read(customReminderRepositoryProvider.future);
        final repoItem = await ref.read(itemRepositoryProvider.future);

        final MItem? item = await repoItem.getItemById(itemId);

        // Insert and update using single function
        await repo.insertReminder(
          newCR: newReminder,
          isEdit: _existingReminderId != null,
          itemName: item != null ? item.name : 'Item',
          // If true then edit mode, else add mode
        );

        // Schedule custom Notification
        await NotificationService().scheduleRepeatingCustomNotification(
          itemId: itemId,
          itemName: itemName,
          content: contentController.text,
          startDate: selectedDateTime!,
          intervalDays: interval,
          isRepeat: _repeatReminder,
        );

        ref.invalidate(activityProvider);

        // Trigger success
        onSuccess();
      } catch (e) {
        logger.e("Notification scheduling failed: $e");
        onError("Failed to set reminder. Please try again.");
      }
    }
  }

  Future<CustomReminder?> fetchReminderByItemId(String itemId) async {
    // Get the repository (awaiting the future provider just like before)
    final repo = await ref.read(customReminderRepositoryProvider.future);

    // Fetch and return the reminder using the itemId
    return await repo.getReminderByItemId(itemId);
  }

  Future<bool> checkReminderActiveByItemId(String itemId) async {
    final repo = await ref.read(customReminderRepositoryProvider.future);

    return await repo.reminderActiveForItem(itemId);
  }

  Future<bool> reminderExistsForItem(String itemId) async {
    final repo = await ref.read(customReminderRepositoryProvider.future);

    final reminder = await repo.getReminderByItemId(itemId);
    return reminder != null;
  }

  @override
  void dispose() {
    contentController.dispose();
    daysController.dispose();
    super.dispose();
  }
}
