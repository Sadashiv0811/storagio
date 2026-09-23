import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/inventory/custom_reminder/m_custom_reminder.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';

final reminderSyncServiceProvider = Provider<CustomReminderSyncService>((ref) {
  return CustomReminderSyncService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    repoFuture: ref.read(customReminderRepositoryProvider.future),
  );
});

class CustomReminderSyncService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Future<CustomReminderRepository> repoFuture;
  static String collectionName = 'custom_reminders';

  CustomReminderSyncService({
    required this.firestore,
    required this.auth,
    required this.repoFuture,
  });

  // =========================
  // BACKUP CUSTOM REMINDERS
  // =========================
  Future<void> backupCustomReminder() async {
    final repo = await repoFuture;
    final user = auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final unsyncedReminders = await repo.getUnsyncedCustomReminder();
    if (unsyncedReminders.isEmpty) return;

    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    for (final reminder in unsyncedReminders) {
      final firebaseMap = reminder.toMap(forFirebase: true);

      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection(collectionName)
          .doc(reminder.id);

      batch.set(docRef, firebaseMap);
      operationCount++;

      if (operationCount == 500) {
        await batch.commit();
        batch = firestore.batch();
        operationCount = 0;
      }
    }

    // Commit any remaining operations
    if (operationCount > 0) {
      await batch.commit();
    }

    // Run all local updates concurrently
    await Future.wait(
      unsyncedReminders.map((reminder) => repo.markAsSynced(reminder.id)),
    );
  }

  // =========================
  // RESTORE CUSTOM REMINDERS
  // =========================
  Future<List<CustomReminder>> downloadCustomReminders() async {
    final user = auth.currentUser;

    if (user == null) throw Exception("User not logged in");

    List<CustomReminder> list = [];

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .get();

    if (snapshot.docs.isEmpty) {
      logger.d("No reminders backup found");
      return list;
    }

    for (final doc in snapshot.docs) {
      final cloudReminder = CustomReminder.fromMap({
        ...doc.data(),
        'synced': 1,
      });

      list.add(cloudReminder);
    }

    return list;
  }

  Future<void> mergeCustomReminders(List<CustomReminder> cloudReminders) async {
    final repo = await repoFuture;

    for (final cloudReminder in cloudReminders) {
      // Match by ID
      final exactMatch = await repo.getReminderById(cloudReminder.id);

      if (exactMatch != null) {
        // If local reminder has unsynced changes, keep local version
        if (!exactMatch.synced) {
          continue;
        }
        await repo.updateReminderForImport(cloudReminder);
        continue;
      }

      // Match by Content + Item
      final duplicateReminder = await repo.getReminderByContentAndItem(
        cloudReminder.content,
        cloudReminder.itemId,
      );

      if (duplicateReminder != null) {
        await repo.deleteReminderForimport(duplicateReminder.id);

        await repo.insertReminderForImport(cloudReminder);
      } else {
        await repo.insertReminderForImport(cloudReminder);
      }
    }
  }
}
