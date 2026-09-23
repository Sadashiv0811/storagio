import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:uuid/uuid.dart';

final roomRepositoryProvider = FutureProvider<RoomRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);

  final activityRepo = await ref.watch(activityRepositoryProvider.future);

  return RoomRepository(db, activityRepo);
});

class RoomRepository {
  final Database db;
  final ActivityRepository activityRepo;
  static const String tableName = 'rooms';

  RoomRepository(this.db, this.activityRepo);

  // ========================
  // INSERT
  // ========================
  Future<int> insertRoom(MRoom room) async {
    final result = await db.insert(
      tableName,
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return result;
  }

  // ========================
  // READ
  // ========================
  Future<List<MRoom>> getAllRooms() async {
    final result = await db.query(tableName, orderBy: 'roomName ASC');

    return result.map((e) => MRoom.fromMap(e)).toList();
  }

  Future<MRoom?> getRoomById(String id) async {
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return MRoom.fromMap(result.first);
  }

  Future<MRoom?> getRoomByName(String roomName) async {
    final result = await db.query(
      tableName,
      where: 'LOWER(TRIM(roomName)) = LOWER(TRIM(?))',
      whereArgs: [roomName],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return MRoom.fromMap(result.first);
  }

  Future<MRoom?> getFirstRoom() async {
    final result = await db.query(tableName, orderBy: 'roomName ASC', limit: 1);

    if (result.isNotEmpty) {
      return MRoom.fromMap(result.first);
    }
    return null; // Returns null if the table is empty
  }

  // ========================
  // COUNT
  // ========================
  Future<int> getTotalCount() async {
    // Using 'sqflite' built-in helper for counting
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM rooms'),
    );

    return count ?? 0;
  }

  // ========================
  // UPDATE
  // ========================
  Future<int> updateRoom({
    required MRoom oldRoom,
    required MRoom newRoom,
  }) async {
    final now = DateTime.now();

    return await db.transaction((txn) async {
      final result = await txn.update(
        tableName,
        newRoom.toMap(),
        where: 'id = ?',
        whereArgs: [newRoom.id],
      );

      if (result > 0) {
        // ========================
        // CHECK CHANGED FIELDS
        // ========================
        final changedField = _getUpdatedField(
          oldRoom: oldRoom,
          newRoom: newRoom,
        );

        // Room changed
        if (changedField != null) {
          await activityRepo.insertActivityTxn(
            txn,
            MActivity(
              id: const Uuid().v4(),

              entityId: newRoom.id,
              entityName: newRoom.roomName,

              entityType: ActivityEntityType.room,
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

  Future<int> updateRoomForImport(MRoom room) async {
    final map = room.toMap(forFirebase: false);
    map.remove('localId');

    return await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  // ========================
  // DELETE
  // ========================
  Future<int> deleteRoom(MRoom room) async {
    final now = DateTime.now();

    return await db.transaction((txn) async {
      final result = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [room.id],
      );

      if (result > 0) {
        // Store deletion record
        await txn.insert('deleted_records', {
          'recordId': room.id,
          'collectionName': tableName,
          'deletedAt': now.millisecondsSinceEpoch,
        });

        // Save activity
        await activityRepo.insertActivityTxn(
          txn,
          MActivity(
            id: const Uuid().v4(),

            entityId: room.id,
            entityName: room.roomName,

            entityType: ActivityEntityType.room,
            actionType: ActivityActionType.deleted,

            createdAt: now,
          ),
        );
      }

      logger.d(
        "Record added in deleted_records table. Deleted record id: ${room.id} room name ${room.roomName}",
      );

      return result;
    });
  }

  Future<int> deleteRoomForImport(String roomId) async {
    return await db.delete(tableName, where: 'id = ?', whereArgs: [roomId]);
  }

  // ========================
  // SYNCED
  // ========================
  Future<List<MRoom>> getUnsyncedRooms() async {
    final result = await db.query(
      tableName,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return result.map((e) => MRoom.fromMap(e)).toList();
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
  // FIND FIRST CHANGE AND RETURN
  // ========================
  Map<String, String>? _getUpdatedField({
    required MRoom oldRoom,
    required MRoom newRoom,
  }) {
    if (oldRoom.roomName != newRoom.roomName) {
      return {
        'fieldName': 'room name',
        'oldValue': oldRoom.roomName,
        'newValue': newRoom.roomName,
      };
    }

    if (oldRoom.icon != newRoom.icon) {
      // In rooms table, icon is stored as Material icon codePoint.
      // In activities table, icon changes are stored as readable icon names.
      return {
        'fieldName': 'icon',
        'oldValue': _getRoomIconName(oldRoom.icon),
        'newValue': _getRoomIconName(newRoom.icon),
      };
    }

    if (oldRoom.color != newRoom.color) {
      // In rooms table, color is stored as ARGB32 integer.
      // In activities table, color changes are stored as HEX string.
      return {
        'fieldName': 'color',
        'oldValue': _colorToHex(oldRoom.color),
        'newValue': _colorToHex(newRoom.color),
      };
    }

    return null;
  }
}

String _colorToHex(int color) {
  return '#${color.toRadixString(16).padLeft(8, '0')}';
}

String _getRoomIconName(String codePoint) {
  return roomIconNames[codePoint] ?? 'unknown_room_icon';
}
