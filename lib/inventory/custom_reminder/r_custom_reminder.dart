import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/inventory/custom_reminder/m_custom_reminder.dart';
import 'package:uuid/uuid.dart';

final customReminderRepositoryProvider =
    FutureProvider<CustomReminderRepository>((ref) async {
      final db = await ref.watch(databaseProvider.future);

      final activityRepo = await ref.watch(activityRepositoryProvider.future);

      return CustomReminderRepository(db, activityRepo);
    });

class CustomReminderRepository {
  final Database db;
  final ActivityRepository activityRepo;
  static const String tableName = 'custom_reminders';

  CustomReminderRepository(this.db, this.activityRepo);

  // ========================
  // INSERT
  // ========================
  Future<void> insertReminder({
    required CustomReminder newCR,
    required bool isEdit,
    required String itemName,
  }) async {
    final now = DateTime.now();

    // Edit
    if (isEdit) {
      final oldCR = await getReminderByItemId(newCR.itemId);

      return await db.transaction((txn) async {
        final result = await txn.insert(
          tableName,
          newCR.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (result > 0) {
          final changedField = await _getUpdatedField(
            txn: txn,
            oldCR: oldCR!,
            newCR: newCR,
          );

          if (changedField != null) {
            await activityRepo.insertActivityTxn(
              txn,
              MActivity(
                id: const Uuid().v4(),

                entityId: newCR.id,
                entityName: '$itemName reminder',

                entityType: ActivityEntityType.reminder,
                actionType: ActivityActionType.updated,

                fieldName: changedField['fieldName'],

                oldValue: changedField['oldValue'],
                newValue: changedField['newValue'],

                createdAt: now,
              ),
            );
          }

          return;
        }
      });
    }
    // Add
    else {
      return await db.transaction((txn) async {
        final result = await txn.insert(
          tableName,
          newCR.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (result > 0) {
          await activityRepo.insertActivityTxn(
            txn,
            MActivity(
              id: const Uuid().v4(),

              entityId: newCR.id,
              entityName: '$itemName reminder',

              entityType: ActivityEntityType.reminder,
              actionType: ActivityActionType.added,

              createdAt: now,
            ),
          );
          return;
        }
      });
    }
  }

  Future<int> insertReminderForImport(CustomReminder reminder) async {
    return await db.insert(
      tableName,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========================
  // READ
  // ========================
  Future<CustomReminder?> getReminderByItemId(String itemId) async {
    // Get a specific reminder by the Item ID
    // Useful for populating the UI when a user edits an item
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'itemId = ?',
      whereArgs: [itemId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CustomReminder.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CustomReminder>> getAllCustomReminders() async {
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    return List.generate(maps.length, (i) {
      return CustomReminder.fromMap(maps[i]);
    });
  }

  Future<CustomReminder?> getReminderById(String reminderId) async {
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [reminderId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return CustomReminder.fromMap(result.first);
  }

  Future<CustomReminder?> getReminderByContentAndItem(
    String content,
    String itemId,
  ) async {
    final result = await db.query(
      tableName,
      where: 'LOWER(TRIM(content)) = LOWER(TRIM(?)) AND itemId = ?',
      whereArgs: [content, itemId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return CustomReminder.fromMap(result.first);
  }

  // ========================
  // UPDATE
  // ========================
  Future<void> updateReminderStatus(CustomReminder reminder) async {
    await db.update(
      tableName,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> updateReminderForImport(CustomReminder reminder) async {
    final map = reminder.toMap(forFirebase: false);
    map.remove('localId');

    return await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> updateItemIds(Map<String, String> itemIdMap) async {
    if (itemIdMap.isEmpty) return;

    // Updates itemId of the reminders
    await db.transaction((txn) async {
      for (final entry in itemIdMap.entries) {
        await txn.update(
          tableName,
          {'itemId': entry.value},
          where: 'itemId = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }

  // ========================
  // DELETE
  // ========================
  Future<void> deleteReminder({
    required CustomReminder reminder,
    required String itemName,
  }) async {
    final now = DateTime.now();

    return await db.transaction((txn) async {
      final result = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [reminder.id],
      );

      if (result > 0) {
        await txn.insert('deleted_records', {
          'recordId': reminder.id,
          'collectionName': tableName,
          'deletedAt': now.millisecondsSinceEpoch,
        });

        await activityRepo.insertActivityTxn(
          txn,
          MActivity(
            id: const Uuid().v4(),

            entityId: reminder.id,
            entityName: '$itemName reminder',

            entityType: ActivityEntityType.reminder,
            actionType: ActivityActionType.deleted,

            createdAt: now,
          ),
        );
      }

      logger.d(
        "Record added in deleted_records table.\nDeleted record id: ${reminder.id}\nItem name: ${reminder.content}",
      );
    });
  }

  Future<int> deleteReminderForimport(String id) async {
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ========================
  // CHECK REMINDER STATUS OF ITEM
  // ========================
  Future<bool> reminderActiveForItem(String itemId) async {
    // Returns true if reminder exists and it is active for an item
    final reminder = await getReminderByItemId(itemId);

    if (reminder == null) {
      return false;
    }

    final now = DateTime.now();

    // One-time reminder has already fired
    if (reminder.intervalDays == 0 &&
        reminder.isActive &&
        reminder.startDate.compareTo(now) <= 0) {
      await updateReminderStatus(reminder.copyWith(isActive: false));

      return false;
    }

    return reminder.isActive;
  }

  // ========================
  // DEACTIVATE EXPIRED ONE TIME CUSTOM REMINDERS
  // ========================
  Future<void> deactivateExpiredOneTimeReminders() async {
    /// Updates isActive to false for One Time Reminders when scheduled date time is passed
    await db.update(
      tableName,
      {'isActive': 0},
      where: '''
      intervalDays = 0
      AND isActive = 1
      AND startDate <= ?
    ''',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  // ========================
  // SYNCED
  // ========================
  Future<List<CustomReminder>> getUnsyncedCustomReminder() async {
    final result = await db.query(
      tableName,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return result.map((e) => CustomReminder.fromMap(e)).toList();
  }

  Future<int> markAsSynced(String id) async {
    return await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================
  // CLEAR
  // ========================
  Future<void> clearAll() async {
    await db.delete(tableName);
  }

  // ========================
  // FIND FIRST CHANGE AND RETURN
  // ========================
  Future<Map<String, String>?> _getUpdatedField({
    required DatabaseExecutor txn,
    required CustomReminder oldCR,
    required CustomReminder newCR,
  }) async {
    if (oldCR.content != newCR.content) {
      return {
        'fieldName': 'content',
        'oldValue': oldCR.content,
        'newValue': newCR.content,
      };
    }

    if (oldCR.intervalDays != newCR.intervalDays) {
      return {
        'fieldName': 'repeat interval',
        'oldValue': oldCR.intervalDays.toString(),
        'newValue': newCR.intervalDays.toString(),
      };
    }

    if (oldCR.startDate != newCR.startDate) {
      return {
        'fieldName': 'scheduled date',
        'oldValue': DateFormat('dd MMM yyyy hh:mm a').format(oldCR.startDate),
        'newValue': DateFormat('dd MMM yyyy hh:mm a').format(newCR.startDate),
      };
    }

    return null;
  }

  // NO need of `deleteRemindersByItemId` method here because
  // we used `ON DELETE CASCADE` in the table schema. If the item is deleted SQLite automatically wipes the reminder!
}
