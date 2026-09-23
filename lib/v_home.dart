import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/activity/v_activity.dart';
import 'package:storagio/inventory/custom_reminder/reminder_scheduler.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/v_inventory.dart';
import 'package:storagio/room/views/v_room.dart';
import 'package:storagio/settings/v_settings.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:storagio/user/vm_user.dart';

final itemCountProvider = Provider<ItemCount>((ref) {
  final itemsAsync = ref.watch(itemProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return itemsAsync.when(
    data: (items) {
      int expiredCount = 0;
      int lowStockCount = 0;
      int emptyStockCount = 0;

      for (final item in items) {
        // Expired
        final expiry = item.warrantyExpiry;
        if (expiry != null && expiry.isBefore(today)) {
          expiredCount++;
        }

        final quantity = item.quantity;
        final lowStockLimit = item.lowStockLimit;

        if (quantity == null) continue;

        // Empty stock
        if (quantity == 0) {
          emptyStockCount++;
          continue;
        }

        // Low stock
        if (lowStockLimit != null && quantity < lowStockLimit) {
          lowStockCount++;
        }
      }

      return ItemCount(
        expiredCount: expiredCount,
        lowStockCount: lowStockCount,
        emptyStockCount: emptyStockCount,
      );
    },
    loading: () =>
        const ItemCount(expiredCount: 0, lowStockCount: 0, emptyStockCount: 0),
    error: (_, _) =>
        const ItemCount(expiredCount: 0, lowStockCount: 0, emptyStockCount: 0),
  );
});

class ItemCount {
  final int expiredCount;
  final int emptyStockCount;
  final int lowStockCount;

  const ItemCount({
    required this.expiredCount,
    required this.emptyStockCount,
    required this.lowStockCount,
  });
}

class VHome extends ConsumerStatefulWidget {
  const VHome({super.key});

  @override
  ConsumerState<VHome> createState() => _VHomeState();
}

class _VHomeState extends ConsumerState<VHome> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isDialogShowing = false;
  bool _hasRestoredNotifications = false;

  final List<Widget> _screens = [
    VInventory(),
    VRoom(),
    VActivity(),
    VSettings(),
  ];

  @override
  void initState() {
    super.initState();

    // Register lifecycle observer to detect when user comes back from App Settings
    WidgetsBinding.instance.addObserver(this);

    // Check permission shortly after frame render finishes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().navigateFromPayload(
        NotificationService().pendingPayload,
      );

      _checkAndRequestPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If user returns from device settings, automatically re-evaluate status
    if (state == AppLifecycleState.resumed) {
      _checkAndRequestPermission();
    }
  }

  /// Evaluates permission state and triggers appropriate UI responses
  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      logger.d("Notification Permission Granted");
      // Dismiss the warning dialog if it is currently visible
      if (_isDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isDialogShowing = false);
      }

      // Only run rescheduling logic once, rather than every single time the app is resumed.
      if (!_hasRestoredNotifications) {
        _hasRestoredNotifications = true;

        try {
          // Safe check: Verify widget is still mounted before reading ref providers
          if (!mounted) return;

          final items = await ref.read(itemProvider.future);

          if (items.isEmpty) {
            logger.d(
              'Items are empty, so no scheduling future notifications and reminders.',
            );
            return;
          }

          // Reschedule expiry notifications
          await ref.read(settingsVMProvider).refreshExpiryNotifications();

          // Deactivates expired one-time reminders, Reschedule future custom reminders
          await ref.read(reminderSchedulerProvider).rescheduleAllReminders();

          logger.d(
            'Successfully restored and rescheduled future notifications and reminders.',
          );
        } catch (e) {
          // Reset flag so we can retry if a network/database error occurred
          _hasRestoredNotifications = false;
          logger.e('Failed to reschedule notifications: $e');
        }
      }
      return;
    }

    // Trigger dialog if permission isn't granted and no dialog is currently open
    if (!_isDialogShowing && mounted) {
      _showPermissionDialog(status);
    }
  }

  /// Displays custom dialog depending on whether permission is standard denied or permanently denied
  void _showPermissionDialog(PermissionStatus status) async {
    // 1. Determine if we are on Android 13+ (API 33+)
    bool isAndroid13OrHigher = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      isAndroid13OrHigher = androidInfo.version.sdkInt >= 33;
    }

    if (!mounted) return;

    setState(() => _isDialogShowing = true);

    final isPermanentlyDenied =
        status.isPermanentlyDenied || (!isAndroid13OrHigher && status.isDenied);

    showDialog(
      context: context,
      barrierDismissible: false,
      // Force user to address the permission
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          // Prevents Android physical back button dismissal
          child: _NotificationRequestDialog(
            negativeAction: () {
              Navigator.of(dialogContext).pop();
              setState(() => _isDialogShowing = false);
            },
            positiveAction: () async {
              // Dismiss dialog first before invoking async actions to avoid context leaks
              Navigator.of(dialogContext).pop();
              setState(() => _isDialogShowing = false);

              if (isPermanentlyDenied) {
                // Directs Android 12 users (who turned off notifications) straight to settings
                await openAppSettings();
              } else {
                // This block will run on Android 13+ or if permission is not yet determined
                final result = await Permission.notification.request();

                // If granted, request exact alarms if missing (this may pause the app again)
                if (result.isGranted) {
                  final androidPlugin = NotificationService().plugin
                      .resolvePlatformSpecificImplementation<
                        AndroidFlutterLocalNotificationsPlugin
                      >();

                  final canSchedule =
                      await androidPlugin?.canScheduleExactNotifications() ??
                      true;

                  if (!canSchedule) {
                    // This will temporarily pause the app. When they return,
                    // didChangeAppLifecycleState will trigger the final scheduling check.
                    await Permission.scheduleExactAlarm.request();
                  }
                } else {
                  // If they denied the system prompt, re-evaluate to show the dialog again
                  _checkAndRequestPermission();
                }
              }
            },
            isPermanentlyDenied: isPermanentlyDenied,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider).value;

    final String? imagePath = user?.profileImage;

    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    final itemCount = ref.watch(itemCountProvider);
    final isExpiredOrEmpty =
        itemCount.expiredCount > 0 || itemCount.emptyStockCount > 0;
    final isLow = itemCount.lowStockCount > 0;

    final count = isExpiredOrEmpty
        ? itemCount.expiredCount + itemCount.emptyStockCount
        : itemCount.lowStockCount;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: AppBarTitle(),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.search);
              },
              icon: const Icon(Icons.search),
            ),
          if (isExpiredOrEmpty || isLow)
            Stack(
              fit: .passthrough,
              alignment: .bottomRight,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.itemAlerts);
                  },
                  icon: Icon(Icons.warning_amber),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 4, right: 5),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: isExpiredOrEmpty ? Colors.red : Colors.orange,
                  ),
                  child: Text(
                    count > 9 ? "" : "$count",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: .bold,
                    ),
                  ),
                ),
              ],
            ),
          _ProfileButton(file: file),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationItem.build(
            context: context,
            isSelected: _currentIndex == 0,
            icon: Icons.inventory_2,
            label: "INVENTORY",
            isDark: isDark,
          ),
          BottomNavigationItem.build(
            context: context,
            isSelected: _currentIndex == 1,
            icon: Icons.home_work_outlined,
            label: "ROOMS",
            isDark: isDark,
          ),
          BottomNavigationItem.build(
            context: context,
            isSelected: _currentIndex == 2,
            icon: Icons.history,
            label: "ACTIVITY",
            isDark: isDark,
          ),
          BottomNavigationItem.build(
            context: context,
            isSelected: _currentIndex == 3,
            icon: Icons.settings_outlined,
            label: "SETTINGS",
            isDark: isDark,
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class BottomNavigationItem {
  static BottomNavigationBarItem build({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? isDark
                    ? Color.fromARGB(255, 56, 192, 255).withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: isSelected ? 24 : 22,
          color: isSelected
              ? isDark
                    ? Color.fromARGB(255, 56, 192, 255)
                    : theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      label: label,
    );
  }
}

// Stateless Widgets
class _ProfileButton extends StatelessWidget {
  final File? file;
  const _ProfileButton({this.file});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.profile);
        },
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 15,
            backgroundImage: file != null ? FileImage(file!) : null,
            child: file == null ? const Icon(Icons.person, size: 22) : null,
          ),
        ),
      ),
    );
  }
}

class _NotificationRequestDialog extends StatelessWidget {
  final VoidCallback negativeAction;
  final Future<void> Function() positiveAction;
  final bool isPermanentlyDenied;

  const _NotificationRequestDialog({
    required this.negativeAction,
    required this.positiveAction,
    required this.isPermanentlyDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Notification Permission Required"),
      content: Text(
        isPermanentlyDenied
            ? "Notifications are permanently disabled. To receive expiry and low stock alerts, please enable them in your device settings."
            : "We need notification access to alert you about your inventory's low stock and upcoming item expirations.",
      ),
      actions: [
        TextButton(
          onPressed: negativeAction,
          child: Text(
            "LATER",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await positiveAction();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: Theme.of(context).colorScheme.shadow,
          ),
          child: Text(
            isPermanentlyDenied ? "OPEN SETTINGS" : "GRANT PERMISSION",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
