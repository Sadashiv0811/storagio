import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/core/deleted_record/r_deleted_record.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/inventory/item/r_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/room/r_room.dart';
import 'package:storagio/room/vm_room.dart';
import 'package:storagio/user/r_user.dart';
import 'package:storagio/user/vm_user.dart';

final clearDataVmProvider = Provider<ClearDataVm>((ref) {
  return ClearDataVm(ref);
});

final clearDataLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await ref.watch(databaseProvider.future);

  return AppDatabase(db);
});

class AppDatabase {
  final Database db;

  AppDatabase(this.db);

  Future<void> clearAllTables() async {
    await db.transaction((txn) async {
      // DELETE CHILD TABLES FIRST
      await txn.delete('custom_reminders');

      await txn.delete('items');

      await txn.delete('rooms');

      await txn.delete('activities');

      await txn.delete('deleted_records');
    });
  }
}

enum ClearStatus { success, error, empty }

class ClearDataVm {
  final Ref ref;

  ClearDataVm(this.ref);

  // =========================================
  // CHECK DEVICE DATA (SQLITE)
  // =========================================
  Future<bool> checkDeviceDataExists({required bool includeAppData}) async {
    final roomRepo = await ref.read(roomRepositoryProvider.future);
    final itemRepo = await ref.read(itemRepositoryProvider.future);

    // When clear data
    if (includeAppData) {
      final activityRepo = await ref.read(activityRepositoryProvider.future);
      final deletedRecordsRepo = await ref.read(
        deletedRecordRepositoryProvider.future,
      );

      // CHECK IF DATA EXISTS
      final counts = await Future.wait([
        roomRepo.getTotalCount(),
        itemRepo.getTotalCount(),
        activityRepo.getTotalCount(),
        deletedRecordsRepo.getTotalCount(),
      ]);

      return counts.any((c) => c > 0);
    }

    // CHECK IF DATA EXISTS
    final counts = await Future.wait([
      roomRepo.getTotalCount(),
      itemRepo.getTotalCount(),
    ]);

    return counts.any((c) => c > 0);
  }

  // =========================================
  // CHECK CLOUD DATA (FIREBASE)
  // =========================================

  /// Checks if the user has any data inside either the 'rooms' or 'items' subcollections.
  Future<bool> checkCloudDataExists(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Run both fetches simultaneously for optimal performance
    final results = await Future.wait([
      firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .limit(1)
          .get(),
      firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .limit(1)
          .get(),
    ]);

    final roomsSnapshot = results[0];
    final itemsSnapshot = results[1];

    // Returns true if either snapshot contains at least one document
    return roomsSnapshot.docs.isNotEmpty || itemsSnapshot.docs.isNotEmpty;
  }

  // =========================================
  // CLEAR DEVICE DATA (SQLITE)
  // =========================================
  // clearDeviceData() → reset local user inventory-related fields + clear other tables
  Future<String> clearDeviceData() async {
    ref.read(clearDataLoadingProvider.notifier).state = true;

    try {
      final bool localDataExists = await checkDeviceDataExists(
        includeAppData: true,
      );

      if (localDataExists) {
        final userRepo = await ref.read(userRepositoryProvider.future);

        // CLEAR DATABASE
        final appDatabase = await ref.read(appDatabaseProvider.future);

        await appDatabase.clearAllTables();

        // RESET USER INVENTORY FIELDS
        await userRepo.resetInventoryFields();
        // Resets below field in user
        // lowStockLimit: 5,

        // REFRESH PROVIDERS
        await ref.read(roomProvider.notifier).refresh();

        await ref.read(itemProvider.notifier).refresh();

        ref.invalidate(customReminderRepositoryProvider);

        await ref.read(activityProvider.notifier).refresh();

        await ref.read(userProvider.notifier).refresh();

        return ClearStatus.success.name;
      } else {
        return ClearStatus.empty.name;
      }
    } catch (e) {
      return ClearStatus.error.name;
    } finally {
      ref.read(clearDataLoadingProvider.notifier).state = false;
    }
  }

  // =========================================
  // DELETE CLOUD BACKUP (FIREBASE)
  // =========================================
  // deleteCloudBackup() → reset Firebase user inventory-related fields + clear other firebase collections
  Future<bool> deleteCloudBackup() async {
    ref.read(clearDataLoadingProvider.notifier).state = true;

    try {
      final firestore = FirebaseFirestore.instance;

      final auth = FirebaseAuth.instance;

      final uid = auth.currentUser?.uid;

      if (uid == null) {
        return false;
      }

      // CHECK CLOUD DATA
      final roomsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('rooms')
          .get();

      final itemsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('items')
          .get();

      final remindersSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('custom_reminders')
          .get();

      // DELETE ITEMS
      for (final doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // DELETE ROOMS
      for (final doc in roomsSnapshot.docs) {
        await doc.reference.delete();
      }

      // DELETE REMINDERS
      for (final doc in remindersSnapshot.docs) {
        await doc.reference.delete();
      }

      final userRepo = await ref.read(userRepositoryProvider.future);

      await userRepo.resetCloudInventoryFields();
      // Resets below field in user
      // lowStockLimit: 5,

      return true;
    } finally {
      ref.read(clearDataLoadingProvider.notifier).state = false;
    }
  }

  // =========================================
  // DELETE EVERYTHING SQLITE + FIREBASE
  // =========================================
  Future<bool> deleteEverything() async {
    ref.read(clearDataLoadingProvider.notifier).state = true;

    try {
      final status = await clearDeviceData();

      final deviceCleared = status == ClearStatus.success.name;

      final cloudDeleted = await deleteCloudBackup();

      return deviceCleared || cloudDeleted;
    } finally {
      ref.read(clearDataLoadingProvider.notifier).state = false;
    }
  }
}
