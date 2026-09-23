import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/theme/p_theme.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/item/r_item.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/settings/dialogs/clear_data/vm_clear_data.dart';
import 'package:storagio/settings/dialogs/sync_data/d_sync_data.dart';
import 'package:storagio/settings/dialogs/clear_data/d_clear_data.dart';
import 'package:storagio/settings/dialogs/default_setup/d_default_c_r.dart';
import 'package:storagio/user/vm_user.dart';

final settingsVMProvider = ChangeNotifierProvider<SettingsVM>((ref) {
  return SettingsVM(ref)..loadSettings();
});

class SettingsVM extends ChangeNotifier {
  final Ref ref;

  SettingsVM(this.ref);

  double lowStockThreshold = 0;

  // ---------------------------- VALUES ----------------------------
  bool notifyLowStock = true;

  // ---------------------------- LOAD SETTINGS ----------------------------
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    notifyLowStock = prefs.getBool(notifyLowStockKey) ?? true;
    lowStockThreshold = prefs.getDouble(lowStockLimitKey) ?? 5.0;

    notifyListeners();
  }

  // ---------------------------- THEME ----------------------------
  void changeTheme(WidgetRef ref, String value) {
    ref.read(themeProvider.notifier).updateThemeFromString(value);
  }

  // ---------------------------- NOTIFICATION ----------------------------
  Future<void> toggleLowStock(bool value) async {
    notifyLowStock = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notifyLowStockKey, value);
  }

  Future<void> refreshExpiryNotifications() async {
    final notificationService = NotificationService();
    final itemRepo = await ref.read(itemRepositoryProvider.future);
    final items = await itemRepo.getAllItems();

    if (items.isEmpty) {
      return;
    }

    // Reset scheduled notifications.
    final now = DateTime.now();

    for (final item in items) {
      if (item.warrantyExpiry == null) continue;

      if (item.warrantyExpiry!.isAfter(now)) {
        await notificationService.scheduleExpiryNotification(
          itemId: item.id,
          itemName: item.name,
          expiryDate: item.warrantyExpiry!,
        );
      }
    }

    await notificationService.printPendingNotifications();
  }

  // ---------------------------- INVENTORY PREFERENCES ----------------------------
  void updateThresholdUI(double value) {
    logger.d("Limit $value");
    lowStockThreshold = value;
    notifyListeners();
  }

  Future<void> saveThreshold(double value) async {
    final user = ref.read(userProvider).value;

    if (user == null) {
      logger.d("User is null.");
      await saveDefaultLowStockLimit(lowStockLimitKey, lowStockThreshold);
      return;
    }

    lowStockThreshold = value;

    notifyListeners();

    final updatedUser = user.copyWith(lowStockLimit: value.toInt());

    await ref.read(userProvider.notifier).updateUser(updatedUser);
  }

  void resetThreshold() {
    lowStockThreshold = 0;
    notifyListeners();
  }

  Future<void> openDefaultCategoryDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DefaultCategoryRoomDialog(isCategory: true),
    );
  }

  Future<void> openDefaultRoomDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DefaultCategoryRoomDialog(isCategory: false),
    );
  }

  // ---------------------------- DATA MANAGEMENT ----------------------------
  Future<void> syncNow(BuildContext context) async {
    // Check internet
    final hasInternet = await ref.read(internetServiceProvider).isConnected();

    if (!hasInternet) {
      showSnackBar("No internet connection", backgroundColor: Colors.red);
      return;
    }

    // Check user
    final user = ref.read(userProvider).value;

    if (user == null) {
      showSnackBar("User not logged in", backgroundColor: Colors.red);
      return;
    }

    if (!context.mounted) return;

    await openSyncDialog(context: context, autoShowDialog: false);
  }

  Future<void> openSyncDialog({
    required BuildContext context,
    required bool autoShowDialog,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncDataDialog(autoShowDialog: autoShowDialog),
    );
  }

  Future<void> openClearDataDialog(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ClearDataDialog(),
    );
  }

  // ---------------------------- AFTER LOGIN ----------------------------
  Future<LoginFlowResult> handleLogin() async {
    try {
      // Check internet
      final hasInternet = await ref.read(internetServiceProvider).isConnected();

      if (!hasInternet) {
        return const LoginFlowResult(
          success: false,
          message: "No internet connection",
        );
      }

      // Get user
      final user = ref.read(userProvider).value;

      if (user == null) {
        return const LoginFlowResult(success: false, message: "User not found");
      }

      user.log(true);
      user.log(false);

      await saveDefaultLowStockLimit(
        lowStockLimitKey,
        double.parse(user.lowStockLimit.toString()),
      );

      // Check if data exists
      final cloudDataExists = await ref
          .read(clearDataVmProvider)
          .checkCloudDataExists(user.id);

      return LoginFlowResult(success: true, showSyncDialog: cloudDataExists);
    } catch (e, s) {
      logger.e("Login flow failed", error: e, stackTrace: s);

      return const LoginFlowResult(
        success: false,
        message: "Something went wrong",
      );
    }
  }
}

class LoginFlowResult {
  final bool success;
  final bool showSyncDialog;
  final String? message;

  const LoginFlowResult({
    required this.success,
    this.showSyncDialog = false,
    this.message,
  });
}
