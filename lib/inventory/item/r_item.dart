import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:uuid/uuid.dart';

final itemRepositoryProvider = FutureProvider<ItemRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);

  final activityRepo = await ref.watch(activityRepositoryProvider.future);

  return ItemRepository(db, activityRepo);
});

class ItemRepository {
  final Database db;
  final ActivityRepository activityRepo;
  static const String tableName = 'items';

  ItemRepository(this.db, this.activityRepo);

  // ========================
  // INSERT
  // ========================
  Future<int> insertItem(MItem item) async {
    final result = await db.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return result;
  }

  // ========================
  // READ
  // ========================
  Future<List<MItem>> getAllItems() async {
    final result = await db.query(tableName, orderBy: 'name ASC');

    return result.map((e) => MItem.fromMap(e)).toList();
  }

  Future<MItem?> getItemById(String itemId) async {
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return MItem.fromMap(result.first);
  }

  Future<List<MItem>?> getItemsByRoomId(String roomId) async {
    final result = await db.query(
      tableName,
      where: 'roomId = ?',
      whereArgs: [roomId],
    );

    if (result.isEmpty) return null;

    return result.map((e) => MItem.fromMap(e)).toList();
  }

  Future<MItem?> getItemByNameAndRoom(String itemName, String roomId) async {
    final result = await db.query(
      tableName,
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND roomId = ?',
      whereArgs: [itemName, roomId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return MItem.fromMap(result.first);
  }

  Future<MItem?> getItemByNameWithoutRoom(String itemName) async {
    final result = await db.query(
      tableName,
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND roomId IS NULL',
      whereArgs: [itemName],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return MItem.fromMap(result.first);
  }

  // ========================
  // UPDATE
  // ========================
  Future<int> updateItem({
    required MItem oldItem,
    required MItem newItem,
  }) async {
    final now = DateTime.now();

    return await db.transaction((txn) async {
      final updatedMap = newItem.toMap();
      updatedMap['synced'] = 0; // local change, needs cloud backup

      final result = await txn.update(
        tableName,
        updatedMap,
        where: 'id = ?',
        whereArgs: [newItem.id],
      );

      if (result > 0) {
        // When room id is set to null, do not track that activity
        // ========================
        // CHECK CHANGED FIELDS
        // ========================
        final changedField = await _getUpdatedField(
          txn: txn,
          oldItem: oldItem,
          newItem: newItem,
        );

        // Item changed
        if (changedField != null) {
          await activityRepo.insertActivityTxn(
            txn,
            MActivity(
              id: const Uuid().v4(),

              entityId: newItem.id,
              entityName: newItem.name,

              entityType: ActivityEntityType.item,
              actionType: ActivityActionType.updated,

              fieldName: changedField['fieldName'],

              oldValue: changedField['oldValue'],
              newValue: changedField['newValue'],

              createdAt: now,
            ),
          );
        }
      }

      return result;
    });
  }

  Future<int> updateItemForImport(MItem item) async {
    final map = item.toMap(forFirebase: false);
    map.remove('localId');

    return await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateRoomIds(Map<String, String> roomIdMap) async {
    if (roomIdMap.isEmpty) return;

    // Updates roomId of items
    await db.transaction((txn) async {
      for (final entry in roomIdMap.entries) {
        await txn.update(
          tableName,
          {'roomId': entry.value},
          where: 'roomId = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }

  // ========================
  // DELETE
  // ========================
  Future<int> deleteItem(MItem item) async {
    final now = DateTime.now();

    return await db.transaction((txn) async {
      final result = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [item.id],
      );

      // Store deletion record
      if (result > 0) {
        await txn.insert('deleted_records', {
          'recordId': item.id,
          'collectionName': tableName,
          'deletedAt': now.millisecondsSinceEpoch,
        });

        // Save activity
        await activityRepo.insertActivityTxn(
          txn,
          MActivity(
            id: const Uuid().v4(),

            entityId: item.id,
            entityName: item.name,

            entityType: ActivityEntityType.item,
            actionType: ActivityActionType.deleted,

            createdAt: now,
          ),
        );
      }

      logger.d(
        "Record added in deleted_records table.\nDeleted record id: ${item.id}\nItem name: ${item.name}",
      );

      return result;
    });
  }

  Future<int> deleteItemForImport(String itemId) async {
    return await db.delete(tableName, where: 'id = ?', whereArgs: [itemId]);
  }

  // ========================
  // SYNCED
  // ========================
  Future<List<MItem>> getUnsyncedItems() async {
    final result = await db.query(
      tableName,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return result.map((e) => MItem.fromMap(e)).toList();
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
  // COUNT
  // ========================
  Future<int> getTotalCount() async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM items'),
    );

    return count ?? 0;
  }

  // ========================
  // HELPER: LOOKUP NAMES FROM IDS
  // ========================
  Future<String> _getRoomNameById(String id, {DatabaseExecutor? txn}) async {
    final executor = txn ?? db;
    final result = await executor.query(
      'rooms',
      columns: ['roomName'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return 'Unknown Room';
    return result.first['roomName'] as String;
  }

  // ========================
  // FIND FIRST CHANGE AND RETURN
  // ========================
  Future<Map<String, String>?> _getUpdatedField({
    required DatabaseExecutor txn,
    required MItem oldItem,
    required MItem newItem,
  }) async {
    final oldCategoryName = oldItem.categoryName;
    final newCategoryName = newItem.categoryName;

    // Common for each category
    // Name check
    if (oldItem.name != newItem.name) {
      return {
        'fieldName': newCategoryName != CategoryNames.billsRecharges
            ? 'name'
            : 'product name',
        'oldValue': oldItem.name,
        'newValue': newItem.name,
      };
    }

    // Category check
    if (oldCategoryName != newCategoryName) {
      return {
        'fieldName': 'category',
        'oldValue': oldCategoryName,
        'newValue': newCategoryName,
      };
    }

    // Except for billsRecharges - Room check, Image path check
    if (newCategoryName != CategoryNames.billsRecharges) {
      // Room check
      if (oldItem.roomId != newItem.roomId) {
        final oldRoomName = oldItem.roomId != null
            ? await _getRoomNameById(oldItem.roomId!, txn: txn)
            : "Unknown Room";

        final newRoomName = newItem.roomId != null
            ? await _getRoomNameById(newItem.roomId!, txn: txn)
            : "Unknown Room";

        return {
          'fieldName': 'room',
          'oldValue': oldRoomName,
          'newValue': newRoomName,
        };
      }

      // Image path check
      if (oldItem.imagePath != newItem.imagePath) {
        String oldValue = '';
        String newValue = '';

        if (oldItem.imagePath == null && newItem.imagePath != null) {
          oldValue = 'No image';
          newValue = 'Image added';
        } else if (oldItem.imagePath != null && newItem.imagePath == null) {
          oldValue = 'Image existed';
          newValue = 'Image removed';
        } else {
          oldValue = 'Old image';
          newValue = 'New image';
        }

        return {
          'fieldName': 'image',
          'oldValue': oldValue,
          'newValue': newValue,
        };
      }
    }

    // Note check except for grocery
    if (newCategoryName != CategoryNames.grocery) {
      if (oldItem.notes != newItem.notes) {
        String oldValue = oldItem.notes.toString();
        if (oldValue == "" || oldValue == "null") {
          oldValue = "-";
        }

        String newValue = newItem.notes.toString();
        if (newValue == "" || newValue == "null") {
          newValue = "-";
        }

        String fieldName = 'notes';

        if (newCategoryName == CategoryNames.electronicAppliances) {
          fieldName = 'maintenance details';
        }
        if (newCategoryName == CategoryNames.medicines) {
          fieldName = 'purpose';
        }

        return {
          'fieldName': fieldName,
          'oldValue': oldValue,
          'newValue': newValue,
        };
      }
    }

    // Other field check based on category
    if (newCategoryName == CategoryNames.billsRecharges) {
      // Purchase, Expiry date check
      final purchaseResult = _purchaseWarrantyCheck(
        oldItem,
        newItem,
        newCategoryName,
      );

      if (purchaseResult != null) {
        return purchaseResult;
      }

      // Last payment amount check
      if (oldItem.lastPaymentAmount != newItem.lastPaymentAmount) {
        return {
          'fieldName': 'last payment amount',
          'oldValue': oldItem.lastPaymentAmount.toString(),
          'newValue': newItem.lastPaymentAmount.toString(),
        };
      }
    }
    //
    if (newCategoryName == CategoryNames.electronicAppliances) {
      // Purchase, Expiry date check
      final purchaseResult = _purchaseWarrantyCheck(
        oldItem,
        newItem,
        newCategoryName,
      );

      if (purchaseResult != null) {
        return purchaseResult;
      }
    }
    //
    if (newCategoryName == CategoryNames.bathroomEssentials ||
        newCategoryName == CategoryNames.grocery ||
        newCategoryName == CategoryNames.hairEssentials ||
        newCategoryName == CategoryNames.kitchen ||
        newCategoryName == CategoryNames.medicines) {
      // Purchase, Expiry date check
      // UQL check
      final result =
          _purchaseWarrantyCheck(oldItem, newItem, newCategoryName) ??
          _uqlCheck(oldItem, newItem, newCategoryName);

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  // Purchase date, warranty/expiry date check
  Map<String, String>? _purchaseWarrantyCheck(
    MItem oldItem,
    MItem newItem,
    String newCategoryName,
  ) {
    String field1 = 'purchase date';
    String field2 = 'warranty/expiry date';

    if (newCategoryName == CategoryNames.billsRecharges) {
      field1 = 'last payment date';
      field2 = 'due date';
    }

    if (oldItem.purchaseDate != newItem.purchaseDate) {
      return {
        'fieldName': field1,
        'oldValue': oldItem.purchaseDate != null
            ? DateFormat('dd MMM yyyy').format(oldItem.purchaseDate!)
            : "-",
        'newValue': newItem.purchaseDate != null
            ? DateFormat('dd MMM yyyy').format(newItem.purchaseDate!)
            : "-",
      };
    }

    if (oldItem.warrantyExpiry != newItem.warrantyExpiry) {
      return {
        'fieldName': field2,
        'oldValue': oldItem.warrantyExpiry != null
            ? DateFormat('dd MMM yyyy').format(oldItem.warrantyExpiry!)
            : "-",
        'newValue': newItem.warrantyExpiry != null
            ? DateFormat('dd MMM yyyy').format(newItem.warrantyExpiry!)
            : "-",
      };
    }

    return null;
  }

  // Unit, Quantity, Low stock limit check
  Map<String, String>? _uqlCheck(
    MItem oldItem,
    MItem newItem,
    String newCategoryName,
  ) {
    if (oldItem.unit != newItem.unit) {
      return {
        'fieldName': 'measuring unit',
        'oldValue': oldItem.unit ?? 'unit',
        'newValue': newItem.unit ?? 'unit',
      };
    }

    if (oldItem.quantity != newItem.quantity) {
      return {
        'fieldName': 'current quantity',
        'oldValue': oldItem.quantity.toString(),
        'newValue': newItem.quantity.toString(),
      };
    }

    if (oldItem.lowStockLimit != newItem.lowStockLimit) {
      return {
        'fieldName': 'low stock limit',
        'oldValue': oldItem.lowStockLimit.toString(),
        'newValue': newItem.lowStockLimit.toString(),
      };
    }

    return null;
  }
}
