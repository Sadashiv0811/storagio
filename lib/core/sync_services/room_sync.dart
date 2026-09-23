import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/room/r_room.dart';

import '../constants/static_values.dart';

final roomSyncServiceProvider = Provider<RoomSyncService>((ref) {
  return RoomSyncService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    repoFuture: ref.read(roomRepositoryProvider.future),
    ref: ref,
  );
});

class RoomSyncService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Future<RoomRepository> repoFuture;
  final Ref ref;
  static String collectionName = 'rooms';

  RoomSyncService({
    required this.firestore,
    required this.auth,
    required this.repoFuture,
    required this.ref,
  });

  // =========================
  // BACKUP ROOMS
  // =========================
  Future<void> backupRooms() async {
    final repo = await repoFuture;
    final user = auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final unsyncedRooms = await repo.getUnsyncedRooms();
    if (unsyncedRooms.isEmpty) return;

    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    for (final room in unsyncedRooms) {
      final firebaseMap = room.toMap(forFirebase: true);

      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection(collectionName)
          .doc(room.id);

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
    await Future.wait(unsyncedRooms.map((room) => repo.markAsSynced(room.id)));
  }

  // =========================
  // RESTORE ROOMS
  // =========================
  Future<List<MRoom>> downloadRooms() async {
    final user = auth.currentUser;

    if (user == null) throw Exception("User not logged in");

    List<MRoom> list = [];

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .get();

    if (snapshot.docs.isEmpty) {
      logger.d("No rooms backup found");
      return list;
    }

    for (final doc in snapshot.docs) {
      final cloudRoom = MRoom.fromMap({...doc.data(), 'synced': 1});
      list.add(cloudRoom);
    }

    return list;
  }

  Future<Map<String, String>> mergeRooms(List<MRoom> cloudRooms) async {
    final repo = await repoFuture;

    final roomIdMap = <String, String>{};

    for (final cloudRoom in cloudRooms) {
      // Match by ID
      final exactMatch = await repo.getRoomById(cloudRoom.id);

      if (exactMatch != null) {
        // If local room has unsynced changes, keep local version
        if (!exactMatch.synced) {
          continue;
        }

        await repo.updateRoomForImport(cloudRoom);
        continue;
      }

      // Match by Name
      final duplicate = await repo.getRoomByName(cloudRoom.roomName);

      if (duplicate != null) {
        roomIdMap[duplicate.id] = cloudRoom.id;

        await repo.deleteRoomForImport(duplicate.id);
        await repo.insertRoom(cloudRoom);
      } else {
        await repo.insertRoom(cloudRoom);
      }
    }

    return roomIdMap;
  }
}
