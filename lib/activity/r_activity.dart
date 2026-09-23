import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/core/database/p_database.dart';

final activityRepositoryProvider = FutureProvider<ActivityRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);

  return ActivityRepository(db);
});

class ActivityRepository {
  final Database db;
  static const String tableName = 'activities';

  ActivityRepository(this.db);

  // ========================
  // NORMAL INSERT
  // ========================
  Future<int> insertActivity(MActivity activity) async {
    return await db.insert(
      tableName,
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========================
  // TRANSACTION INSERT
  // ========================
  Future<int> insertActivityTxn(Transaction txn, MActivity activity) async {
    return await txn.insert(
      tableName,
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========================
  // READ (All)
  // ========================
  Future<List<MActivity>> getAllActivities() async {
    final result = await db.query(tableName, orderBy: 'createdAt DESC');

    return result.map((e) => MActivity.fromMap(e)).toList();
  }

  // ========================
  // CLEAR (Optional Debug)
  // ========================
  Future<void> clearAll() async {
    await db.delete(tableName);
  }

  // ========================
  // COUNT
  // ========================
  Future<int> getTotalCount() async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM activities'),
    );

    return count ?? 0;
  }
}
