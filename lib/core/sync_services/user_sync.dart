import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/services/s_image.dart';

import 'package:storagio/user/r_user.dart';

final userSyncServiceProvider = Provider<UserSyncService>((ref) {
  return UserSyncService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    repoFuture: ref.read(userRepositoryProvider.future),
  );
});

class UserSyncService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Future<UserRepository> repoFuture;

  UserSyncService({
    required this.firestore,
    required this.auth,
    required this.repoFuture,
  });

  // =========================
  // BACKUP USER
  // =========================
  Future<void> backupUser() async {
    final repo = await repoFuture;

    final firebaseUser = auth.currentUser;

    if (firebaseUser == null) {
      throw Exception("User not logged in");
    }

    final localUser = await repo.getCurrentUser();

    if (localUser == null) {
      throw Exception("No local user found");
    }

    final imageService = ImageService();

    final base64Image = await imageService.imageToBase64(
      localUser.profileImage,
    );

    final firebaseMap = localUser.toMap(forFirebase: true);

    firebaseMap['profileImageBase64'] = base64Image;

    await firestore.collection('users').doc(firebaseUser.uid).set(firebaseMap);

    await repo.markAsSynced(localUser.id);
  }

  // When user logins with existing account, his data is automatically inserted in users table.
  // So no need to create restoreUser method.
  // DO NOT put profileImageBase64 inside MUser. Because Base64 is NOT local model data.
  // It is transport/sync layer data. Keep it only inside Firebase map.
}
