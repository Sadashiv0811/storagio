import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/settings/dialogs/clear_data/vm_clear_data.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:storagio/user/vm_user.dart';

class ClearDataDialog extends ConsumerWidget {
  const ClearDataDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(clearDataLoadingProvider);

    final vm = ref.watch(settingsVMProvider);

    final user = ref.watch(userProvider).value;

    final isLoggedIn = user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),

        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WarningIcon(),

            const SizedBox(height: 24),

            const DialogHeader(
              title: 'Manage Stored Data',
              message:
                  'Choose whether to clear data from this device only or permanently delete all stored data including cloud backup.',
            ),

            if (isLoading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ] else ...[
              const SizedBox(height: 32),

              // CLEAR DEVICE DATA
              SizedBox(
                width: double.infinity,
                child: CPositiveButton(
                  text: 'Clear Device Data',
                  iconData: Icons.phone_android,
                  bgColor: Colors.orange,

                  callback: isLoading
                      ? () {}
                      : () async {
                          // Device data cleared
                          final status = await ref
                              .read(clearDataVmProvider)
                              .clearDeviceData();

                          // Cancel all notifications
                          await NotificationService().cancelAll();

                          logger.d("All Scheduled notifications cancelled");

                          if (!context.mounted) return;

                          Navigator.pop(context);

                          if (status == ClearStatus.success.name) {
                            vm.resetThreshold();
                            showSnackBar('Device data cleared');
                          } else if (status == ClearStatus.empty.name) {
                            showSnackBar(
                              'There is no data to clear',
                              backgroundColor: Colors.orange,
                            );
                          } else {
                            showSnackBar(
                              'An error occurred',
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                ),
              ),

              const SizedBox(height: 14),

              // DELETE EVERYTHING
              SizedBox(
                width: double.infinity,
                child: CPositiveButton(
                  text: 'Delete Everything',
                  iconData: Icons.delete_forever,
                  bgColor: Colors.red,

                  callback: isLoading
                      ? () {}
                      : () async {
                          final hasInternet = await ref
                              .read(internetServiceProvider)
                              .isConnected();

                          if (!hasInternet && context.mounted) {
                            showSnackBar(
                              'No internet connection',
                              backgroundColor: Colors.red,
                            );
                            Navigator.pop(context);
                            return;
                          }

                          if (!isLoggedIn && context.mounted) {
                            showSnackBar(
                              'User not logged in',
                              backgroundColor: Colors.red,
                            );
                            Navigator.pop(context);
                            return;
                          }

                          try {
                            final (cloudDataExists, localDataExists) = await (
                              ref
                                  .read(clearDataVmProvider)
                                  .checkCloudDataExists(user!.id),
                              ref
                                  .read(clearDataVmProvider)
                                  .checkDeviceDataExists(includeAppData: true),
                            ).wait;

                            if (cloudDataExists || localDataExists) {
                              // Delete cloud and local data
                              final deleted = await ref
                                  .read(clearDataVmProvider)
                                  .deleteEverything();

                              // Cancel all notifications
                              await NotificationService().cancelAll();
                              logger.d("All Scheduled notifications cancelled");

                              if (deleted && context.mounted) {
                                vm.resetThreshold();
                                showSnackBar(
                                  'All local and cloud data deleted',
                                );
                                Navigator.pop(context);
                              }
                            } else {
                              if (!context.mounted) return;

                              Navigator.pop(context);

                              showSnackBar(
                                'There is no data to clear',
                                backgroundColor: Colors.orange,
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;

                            Navigator.pop(context);

                            showSnackBar(
                              e.toString().replaceFirst('Exception: ', ''),
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                ),
              ),
            ],
            const SizedBox(height: 18),

            const Align(alignment: Alignment.center, child: CCancelButton()),
          ],
        ),
      ),
    );
  }
}
