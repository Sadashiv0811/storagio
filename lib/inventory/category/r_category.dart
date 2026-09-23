import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/inventory/category/m_category.dart';

final categoryRepositoryProvider = FutureProvider<CategoryRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);

  final activityRepo = await ref.watch(activityRepositoryProvider.future);

  return CategoryRepository(db, activityRepo);
});

class CategoryRepository {
  final Database db;
  final ActivityRepository activityRepo;
  static const String tableName = 'categories';

  CategoryRepository(this.db, this.activityRepo);

  // ========================
  // CREATE
  // ========================
  Future<int> insertCategory(MCategory category) async {
    final result = await db.insert(
      tableName,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return result;
  }

  // ========================
  // READ (All)
  // ========================
  Future<List<MCategory>> getAllCategories() async {
    final result = await db.query(tableName, orderBy: 'categoryName ASC');

    return result.map((e) => MCategory.fromMap(e)).toList();
  }

  // ========================
  // READS FIRST CATEGORY
  // ========================
  Future<MCategory?> getFirstCategory() async {
    final result = await db.query(
      tableName,
      orderBy: 'categoryName ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return MCategory.fromMap(result.first);
    }
    return null; // Returns null if the table is empty
  }
}
