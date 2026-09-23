import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_image.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/sync_services/sync.dart';
import 'package:storagio/core/sync_services/user_sync.dart';
import 'package:storagio/inventory/custom_reminder/reminder_scheduler.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:storagio/user/m_user.dart';
import 'package:storagio/user/r_user.dart';

enum SyncStatus { initial, loading, success, error }

class SyncState {
  final SyncStatus status;
  final String? message;

  const SyncState({this.status = SyncStatus.initial, this.message});

  SyncState copyWith({SyncStatus? status, String? message}) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

final syncDataProvider = NotifierProvider.autoDispose<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    return const SyncState();
  }

  // =========================
  // SYNC (Combined backup & restore)
  // =========================
  Future<void> syncData() async {
    state = state.copyWith(status: SyncStatus.loading);

    try {
      // Check internet
      final hasInternet = await ref.read(internetServiceProvider).isConnected();

      if (!hasInternet) {
        state = state.copyWith(
          status: SyncStatus.error,
          message: "No internet connection",
        );
        return;
      }

      final userRepo = await ref.read(userRepositoryProvider.future);
      MUser? currentUser = await userRepo.getCurrentUser();

      if (currentUser != null) {
        final String? imagePath = currentUser.profileImage;

        final File? file =
            imagePath != null &&
                imagePath.trim().isNotEmpty &&
                File(imagePath).existsSync()
            ? File(imagePath)
            : null;

        // If currentUser profile image is does not exists then fetch image from cloud.
        if (file == null) {
          await restoreProfileImage(localUser: currentUser, userRepo: userRepo);
        }

        await ref.read(userSyncServiceProvider).backupUser();
      }

      final success = await ref.read(syncServiceProvider).masterSync();

      // Reset reminders
      if (success) {
        // Reschedule expiry notifications after restoring data.
        final vm = ref.read(settingsVMProvider);
        await vm.refreshExpiryNotifications();

        // Deactivates expired one time reminders, Restore all active reminders
        await ref.read(reminderSchedulerProvider).rescheduleAllReminders();
      }

      state = state.copyWith(
        status: success ? SyncStatus.success : SyncStatus.error,
        message: success ? "Sync completed" : "Sync failed",
      );
    } catch (e, stackTrace) {
      logger.e("Sync failed", error: e, stackTrace: stackTrace);

      state = state.copyWith(status: SyncStatus.error, message: "Sync failed");
    }
  }

  Future<void> restoreProfileImage({
    required MUser localUser,
    required UserRepository userRepo,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      // Download user document
      final snapshot = await firestore
          .collection('users')
          .doc(localUser.id)
          .get();

      // If user has a profile image
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data();

        final imageService = ImageService();

        String? imagePath;

        // Restore image if exists
        if (data!['profileImageBase64'] != null) {
          imagePath = await imageService.base64ToImage(
            data['profileImageBase64'],
          );

          await userRepo.updateProfileImage(
            userId: localUser.id,
            imagePath: imagePath ?? '',
          );
        }
      }
    } catch (e) {
      logger.d("Profile Image Error $e");
    }
  }
}
