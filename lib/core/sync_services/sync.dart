import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/deleted_record/r_deleted_record.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/core/sync_services/custom_reminder_sync.dart';
import 'package:storagio/core/sync_services/item_sync.dart';
import 'package:storagio/inventory/item/r_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/core/sync_services/room_sync.dart';
import 'package:storagio/room/vm_room.dart';
import 'package:storagio/user/vm_user.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref: ref);
});

class SyncService {
  final Ref ref;

  SyncService({required this.ref});

  // =========================
  // THE MASTER SYNC
  // =========================
  // Duplicate rooms are merged by ID or name.
  // Duplicate items are merged by ID or name+room.
  // Reminder references are repaired before reminder merging.
  // Running masterSync() multiple times converges to the same final state.
  Future<bool> masterSync() async {
    try {
      logger.i("========== MASTER SYNC START ==========");

      // STEP 1: Sync deletions

      logger.i("Syncing deleted records...");
      await syncDeletedRecords();

      // STEP 2: Download latest cloud data

      logger.i("Downloading cloud data...");

      final roomSync = ref.read(roomSyncServiceProvider);
      final itemSync = ref.read(itemSyncServiceProvider);
      final reminderSync = ref.read(reminderSyncServiceProvider);

      final (cloudRooms, cloudItems, cloudReminders) = await (
        roomSync.downloadRooms(),
        itemSync.downloadItems(),
        reminderSync.downloadCustomReminders(),
      ).wait;

      // STEP 3: Merge Rooms

      logger.i("Merging rooms...");

      final roomIdMap = await roomSync.mergeRooms(cloudRooms);

      // STEP 4: Update Item.roomId

      if (roomIdMap.isNotEmpty) {
        logger.i(
          "Updating ${roomIdMap.length} room references in local items...",
        );

        final itemRepo = await ref.read(itemRepositoryProvider.future);

        await itemRepo.updateRoomIds(roomIdMap);
      }

      // STEP 5: Merge Items

      logger.i("Merging items...");

      final itemIdMap = await itemSync.mergeItems(cloudItems);

      // STEP 6: Update Reminder.itemId

      if (itemIdMap.isNotEmpty) {
        logger.i(
          "Updating ${itemIdMap.length} item references in reminders...",
        );

        final reminderRepo = await ref.read(
          customReminderRepositoryProvider.future,
        );

        await reminderRepo.updateItemIds(itemIdMap);
      }

      // STEP 7: Merge Reminders

      logger.i("Merging reminders...");

      await reminderSync.mergeCustomReminders(cloudReminders);

      // STEP 8: Upload local changes

      logger.i("Uploading local changes...");

      await roomSync.backupRooms();
      await itemSync.backupItems();
      await reminderSync.backupCustomReminder();

      // STEP 9: Refresh UI

      logger.i("Refreshing providers...");

      await _refreshAllProviders();

      logger.i("========== MASTER SYNC SUCCESS ==========");

      return true; // Sync completed successfully
    } catch (e, stackTrace) {
      logger.e(
        "========== MASTER SYNC FAILED ==========",
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // =========================
  // HELPER: REFRESH PROVIDERS
  // =========================
  Future<void> _refreshAllProviders() async {
    await ref.read(userProvider.notifier).refresh();
    await ref.read(roomProvider.notifier).refresh();
    await ref.read(itemProvider.notifier).refresh();

    // Invalidate re-triggers the FutureProvider to fetch fresh DB data
    ref.invalidate(customReminderRepositoryProvider);

    await ref.read(activityProvider.notifier).refresh();
  }

  // =========================
  // DELETE RECORDS
  // =========================
  Future<void> syncDeletedRecords() async {
    final deletedRepo = await ref.read(deletedRecordRepositoryProvider.future);
    final deletedRecords = await deletedRepo.getAllDeletedRecords();

    if (deletedRecords.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    for (final record in deletedRecords) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(record.collectionName)
          .doc(record.recordId)
          .delete();
    }

    await deletedRepo.clearAll();
  }
}
