import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_image.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/r_item.dart';

final itemSyncServiceProvider = Provider<ItemSyncService>((ref) {
  return ItemSyncService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    repoFuture: ref.read(itemRepositoryProvider.future),
  );
});

class ItemSyncService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Future<ItemRepository> repoFuture;

  ItemSyncService({
    required this.firestore,
    required this.auth,
    required this.repoFuture,
  });

  // =========================
  // BACKUP ITEMS
  // =========================
  Future<void> backupItems() async {
    final repo = await repoFuture;
    final user = auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final unsyncedItems = await repo.getUnsyncedItems();
    if (unsyncedItems.isEmpty) return;

    final imageService = ImageService();

    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    for (final item in unsyncedItems) {
      // Compress + convert image
      final base64Image = await imageService.imageToBase64(item.imagePath);

      final firebaseMap = item.toMap(forFirebase: true);

      // Transport-only field
      firebaseMap['imageBase64'] = base64Image;

      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .doc(item.id);

      batch.set(docRef, firebaseMap);
      operationCount++;

      // Firestore batches have a limit of 500 operations.
      // So, commit in chunks.
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
    await Future.wait(unsyncedItems.map((item) => repo.markAsSynced(item.id)));
  }

  // =========================
  // RESTORE ITEMS
  // =========================
  Future<List<MItem>> downloadItems() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    List<MItem> list = [];
    final imageService = ImageService(); // Initialize your image service

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('items')
        .get();

    if (snapshot.docs.isEmpty) {
      logger.d("No items backup found");
      return list;
    }

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());

      // --- Handle Image Processing ---
      String? localImagePath;

      // Safely check if imageBase64 exists in the cloud document
      if (data.containsKey('imageBase64') && data['imageBase64'] != null) {
        localImagePath = await imageService.base64ToImage(data['imageBase64']);
        data.remove('imageBase64'); // Remove transport-only field
      }

      list.add(
        MItem.fromMap({...data, 'imagePath': localImagePath, 'synced': 1}),
      );
    }

    return list;
  }

  Future<Map<String, String>> mergeItems(List<MItem> cloudItems) async {
    final repo = await repoFuture;

    final itemIdMap = <String, String>{};

    for (final cloudItem in cloudItems) {
      // Match by ID
      final exact = await repo.getItemById(cloudItem.id);

      if (exact != null) {
        // If local item has unsynced changes, keep local version
        if (!exact.synced) {
          continue;
        }

        await repo.updateItemForImport(cloudItem);
        continue;
      }

      // Match by Name + Room
      MItem? duplicate;

      if (cloudItem.roomId == null) {
        // Bills & Recharges
        duplicate = await repo.getItemByNameWithoutRoom(cloudItem.name);
      } else {
        // Normal inventory items
        duplicate = await repo.getItemByNameAndRoom(
          cloudItem.name,
          cloudItem.roomId!,
        );
      }

      if (duplicate != null) {
        itemIdMap[duplicate.id] = cloudItem.id;

        await repo.deleteItemForImport(duplicate.id);
        await repo.insertItem(cloudItem);
      } else {
        await repo.insertItem(cloudItem);
      }
    }

    return itemIdMap;
  }
}
