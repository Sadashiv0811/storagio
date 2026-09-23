import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_authentication.dart';
import 'package:storagio/core/services/s_image.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/settings/dialogs/clear_data/vm_clear_data.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:storagio/user/r_user.dart';
import 'package:storagio/user/vm_user.dart';

final profileVMProvider = StateNotifierProvider<ProfileVM, ProfileState>((ref) {
  return ProfileVM(ref);
});

class ProfileState {
  final bool isEditing;
  final bool isDeleting;
  final bool isProcessing;

  const ProfileState({
    this.isEditing = false,
    this.isDeleting = false,
    this.isProcessing = false,
  });

  ProfileState copyWith({
    bool? isEditing,
    bool? isDeleting,
    bool? isProcessing,
  }) {
    return ProfileState(
      isEditing: isEditing ?? this.isEditing,
      isDeleting: isDeleting ?? this.isDeleting,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class ProfileVM extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileVM(this.ref) : super(const ProfileState());

  bool get isEditing => state.isEditing;
  bool get isDeleting => state.isDeleting;

  final ImageService _imageService = ImageService();

  void setEditing(bool value) {
    state = state.copyWith(isEditing: value);
  }

  void setDeleting(bool value) {
    state = state.copyWith(isDeleting: value);
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  // ========================
  // ADD/EDIT PROFILE IMAGE
  // ========================
  Future<void> pickProfileImage() async {
    setEditing(true);

    try {
      final repo = await ref.read(userRepositoryProvider.future);

      final user = await repo.getCurrentUser();

      if (user == null) {
        logger.d("User not found");
        return;
      }

      // Pick image
      final File? image = await _imageService.pickImage();

      if (image == null) return;

      // Save image locally
      final String savedPath = await _imageService.saveImage(image);

      // Update DB
      await repo.updateProfileImage(userId: user.id, imagePath: savedPath);

      // Refresh user state
      await ref.read(userProvider.notifier).refresh();

      logger.d("Profile image updated");
    } catch (e) {
      logger.d(e.toString());
    } finally {
      setEditing(false);
    }
  }

  // ========================
  // DELETE PROFILE IMAGE
  // ========================
  Future<void> deleteProfileImage() async {
    setDeleting(true);

    try {
      final repo = await ref.read(userRepositoryProvider.future);

      final user = await repo.getCurrentUser();

      if (user == null) {
        logger.d("User not found");
        return;
      }

      final bool result = await _imageService.deleteImage(
        user.profileImage ?? '',
      );

      if (result == false) return;

      logger.d("Profile image deleted");

      // Update DB
      await repo.updateProfileImage(userId: user.id, imagePath: '');

      // Refresh user state
      await ref.read(userProvider.notifier).refresh();
    } catch (e) {
      logger.d(e.toString());
    } finally {
      setDeleting(false);
    }
  }

  // ========================
  // UPDATE FULL NAME
  // ========================
  Future<void> updateFullName(String fullName) async {
    setEditing(true);

    try {
      // Repository
      final repo = await ref.read(userRepositoryProvider.future);

      // Current user
      final user = await repo.getCurrentUser();

      if (user == null) {
        logger.d("User not found");
        return;
      }

      // Update DB
      await repo.updateFullName(userId: user.id, fullName: fullName.trim());

      // Refresh userProvider
      await ref.read(userProvider.notifier).refresh();

      logger.d("Full name updated successfully");
    } catch (e) {
      logger.d(e.toString());
    } finally {
      setEditing(false);
    }
  }

  // ========================
  // LOGOUT PROCESS
  // ========================
  Future<LogoutStatus> logoutProcess() async {
    setProcessing(true);

    try {
      // Check internet
      final hasInternet = await ref.read(internetServiceProvider).isConnected();

      if (!hasInternet) {
        return const LogoutStatus(success: false, message: "No internet connection");
      }

      // Authentication service
      final auth = await ref.read(authenticationProvider.future);

      // Clear local data
      await ref.read(clearDataVmProvider).clearDeviceData();

      // Cancel notifications
      await NotificationService().cancelAll();

      logger.d("All scheduled notifications cancelled");

      // Firebase logout
      await auth.logout();

      // Clear user provider
      await ref.read(userProvider.notifier).logout();

      // Refresh 
      ref.invalidate(settingsVMProvider);
      ref.invalidate(userProvider);

      return const LogoutStatus(success: true, message: "Logged out successfully");
    } catch (e, s) {
      logger.e("Logout failed", error: e, stackTrace: s);
      return const LogoutStatus(success: false, message: "Failed to log out");
    } finally {
      setProcessing(false);
    }
  }
}

class LogoutStatus {
  final bool success;
  final String message;
  const LogoutStatus({required this.success, required this.message});
}
