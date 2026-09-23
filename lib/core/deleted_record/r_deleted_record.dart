import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/core/deleted_record/m_deleted_record.dart';

final deletedRecordRepositoryProvider = FutureProvider<DeletedRecordRepository>(
  (ref) async {
    final db = await ref.watch(databaseProvider.future);

    return DeletedRecordRepository(db);
  },
);

class DeletedRecordRepository {
  final Database db;

  DeletedRecordRepository(this.db);

  // ========================
  // READ ALL
  // ========================
  Future<List<MDeletedRecord>> getAllDeletedRecords() async {
    final result = await db.query('deleted_records', orderBy: 'deletedAt ASC');

    return result.map((e) => MDeletedRecord.fromMap(e)).toList();
  }

  // ========================
  // CLEAR ALL
  // ========================
  Future<int> clearAll() async {
    return await db.delete('deleted_records');
  }

  // ========================
  // COUNT
  // ========================
  Future<int> getTotalCount() async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM deleted_records'),
    );

    return count ?? 0;
  }
}
