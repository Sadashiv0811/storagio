import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/inventory/item/r_item.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:uuid/uuid.dart';

final itemProvider = AsyncNotifierProvider<ItemNotifier, List<MItem>>(
  ItemNotifier.new,
);

class ItemNotifier extends AsyncNotifier<List<MItem>> {
  late ItemRepository _repo;

  @override
  Future<List<MItem>> build() async {
    _repo = await ref.read(itemRepositoryProvider.future);
    return _repo.getAllItems();
  }

  // ========================
  // ADD
  // ========================
  Future<void> addItem(MItem item) async {
    final now = DateTime.now();

    final result = await _repo.insertItem(item);

    if (result > 0) {
      if (item.warrantyExpiry != null) {
        await NotificationService().scheduleExpiryNotification(
          itemId: item.id,
          itemName: item.name,
          expiryDate: item.warrantyExpiry!,
        );

        // Also if expiry date is passed, then
        // No notification scheduled
        // No immediate notification shown
        // Function exits
      }

      final items = await _repo.getAllItems();

      state = AsyncData(items);

      // Save activity
      final activityRepo = await ref.read(activityRepositoryProvider.future);

      await activityRepo.insertActivity(
        MActivity(
          id: const Uuid().v4(),

          entityId: item.id,
          entityName: item.name,

          entityType: ActivityEntityType.item,
          actionType: ActivityActionType.added,

          createdAt: now,
        ),
      );

      // Refresh activities
      ref.invalidate(activityProvider);
    }
  }

  // ========================
  // GET
  // ========================
  Future<List<MItem>?> getItemsByRId(String roomId) async {
    return _repo.getItemsByRoomId(roomId);
  }

  // ========================
  // UPDATE
  // ========================
  Future<void> updateItem(MItem oldItem, MItem newItem) async {
    await _repo.updateItem(oldItem: oldItem, newItem: newItem);

    state = AsyncData(await _repo.getAllItems());

    final settings = ref.read(settingsVMProvider);

    // Refresh activities and items provider
    ref.invalidate(activityProvider);

    // Custom notification
    if (oldItem.name != newItem.name) {
      await NotificationService().cancelRepeatingCustomNotification(newItem.id);

      final repo = await ref.read(customReminderRepositoryProvider.future);
      final customReminder = await repo.getReminderByItemId(newItem.id);

      logger.d("""Checking
        Old name: ${oldItem.name}
        New name: ${newItem.name}
        Reminder content: ${customReminder?.content}""");

      if (customReminder != null) {
        await NotificationService().scheduleRepeatingCustomNotification(
          itemId: newItem.id,
          itemName: newItem.name,
          content: customReminder.content,
          startDate: customReminder.startDate,
          intervalDays: customReminder.intervalDays,
          isRepeat: customReminder.intervalDays <= 0 ? false : true,
        );
        logger.i("Custom reminder scheduled for updated item ${newItem.id}");
      }
    }

    // Low stock notification
    if (settings.notifyLowStock) {
      final oldQty = oldItem.quantity;
      final oldLimit = oldItem.lowStockLimit;
      final newQty = newItem.quantity;
      final newLimit = newItem.lowStockLimit;
      final newUnit = newItem.unit;

      if (oldQty == null ||
          oldLimit == null ||
          newQty == null ||
          newLimit == null ||
          newUnit == null) {
        return;
      }

      final wasLowStock = oldQty <= oldLimit;

      final isLowStockNow = newQty <= newLimit;

      // Notify only when entering low-stock state
      if (!wasLowStock && isLowStockNow) {
        await NotificationService().showLowStockNotification(
          itemId: newItem.id,
          itemName: newItem.name,
          quantity: newQty,
          unit: newUnit,
        );
        logger.i("Low stock notification shown for updated item ${newItem.id}");
      }
    }

    // Expiry notification
    // Reschedule notification when item updated. The old notification is automatically replaced.
    if (oldItem.name != newItem.name ||
        oldItem.warrantyExpiry != newItem.warrantyExpiry) {
      if (newItem.warrantyExpiry != null) {
        await NotificationService().scheduleExpiryNotification(
          itemId: newItem.id,
          itemName: newItem.name,
          expiryDate: newItem.warrantyExpiry!,
        );
        logger.i(
          "Expiry notification scheduled for updated item ${newItem.id}",
        );
      } else {
        await NotificationService().cancel(
          NotificationService().expiryId(newItem.id),
        );
      }
    }
  }

  // ========================
  // DELETE
  // ========================
  Future<void> deleteItem(MItem item) async {
    // Cancel notification before item deletion.
    await NotificationService().cancel(NotificationService().expiryId(item.id));
    await NotificationService().cancelRepeatingCustomNotification(item.id);

    // Delete item
    await _repo.deleteItem(item);

    final itemsList = await _repo.getAllItems();

    // Update state
    state = AsyncData(itemsList);

    // Refresh activities
    ref.invalidate(activityProvider);
  }

  // ========================
  // DUPLICATE CHECK
  // ========================
  Future<bool> itemExists(String itemName, MItem item) async {
    final existingItems = await _repo.getAllItems();

    if (existingItems.isEmpty) return false;

    final alreadyExists = existingItems.any(
      (e) => e.id != item.id && e.name.toLowerCase() == itemName.toLowerCase(),
    );

    return alreadyExists;
  }

  // ========================
  // REFRESH
  // ========================
  Future<void> refresh() async {
    final repo = await ref.read(itemRepositoryProvider.future);

    state = const AsyncLoading();

    state = AsyncData(await repo.getAllItems());
  }

  // ========================
  // SYNC
  // ========================
  Future<List<MItem>> getUnsynced() async {
    return await _repo.getUnsyncedItems();
  }

  Future<void> markSynced(String id) async {
    await _repo.markAsSynced(id);
  }
}
