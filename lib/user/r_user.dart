import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/core/database/p_database.dart';
import 'package:storagio/user/m_user.dart';

final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);

  return UserRepository(db);
});

class UserRepository {
  final Database db;
  static const String tableName = 'users';

  UserRepository(this.db);

  // ========================
  // CREATE / INSERT
  // ========================
  Future<int> insertUser(MUser user) async {
    return await db.insert(
      tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========================
  // GET CURRENT USER
  // ========================
  Future<MUser?> getCurrentUser() async {
    final result = await db.query(
      tableName,
      limit: 1, // single-user
    );

    if (result.isEmpty) return null;

    return MUser.fromMap(result.first);
  }

  // ========================
  // UPDATE
  // ========================
  Future<int> updateUser(MUser user) async {
    final updatedUser = user.copyWith(synced: false);

    return await db.update(
      tableName,
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [updatedUser.id],
    );
  }

  Future<int> updateFullName({
    required String userId,
    required String fullName,
  }) async {
    return await db.update(
      tableName,
      {'fullName': fullName, 'synced': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    return await db.update(
      tableName,
      {'profileImage': imagePath, 'synced': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ========================
  // CLEAR ALL (Logout full reset)
  // ========================
  Future<void> clearAll() async {
    await db.delete(tableName);
  }

  // ========================
  // UNSYNCED
  // ========================
  Future<List<MUser>> getUnsyncedUsers() async {
    final result = await db.query(
      tableName,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return result.map((e) => MUser.fromMap(e)).toList();
  }

  // ========================
  // MARK SYNCED
  // ========================
  Future<int> markAsSynced(String id) async {
    return await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================
  // RESET INVENTORY RELATED FIELDS ON CLICK CLEAR DATA
  // ========================
  // Local User Reset (SQLite)
  Future<void> resetInventoryFields() async {
    final user = await getCurrentUser();

    if (user == null) return;

    final updatedUser = user.copyWith(lowStockLimit: 4);

    updatedUser.log(false);

    await db.update(
      tableName,
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Firebase User Reset
  Future<void> resetCloudInventoryFields() async {
    final auth = FirebaseAuth.instance;

    final uid = auth.currentUser?.uid;

    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection(tableName).doc(uid);

    // RESET FIELDS
    await userRef.update({'lowStockLimit': 4});

    // FETCH UPDATED USER
    final updatedDoc = await userRef.get();

    final data = updatedDoc.data();

    if (data == null) return;

    final firebaseUser = MUser.fromMap(data);

    firebaseUser.log(true);
  }
}
