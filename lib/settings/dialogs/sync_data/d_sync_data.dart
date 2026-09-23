import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/settings/dialogs/sync_data/vm_sync_data.dart';

class SyncDataDialog extends ConsumerWidget {
  final bool autoShowDialog;
  const SyncDataDialog({super.key, required this.autoShowDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),

        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.blue : Colors.grey.shade200,
                    blurRadius: 4,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 48,
                      color: Color(0xFF065F46),
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_done,
                          size: 16,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            DialogHeader(
              title: autoShowDialog ? "Cloud backup found" : "Sync Data",
              message: autoShowDialog
                  ? "We found inventory data associated with this account.\n\nSync now to restore and merge your latest cloud data with this device. This may take a few moments."
                  : "Synchronize your inventory with the cloud.\n\n"
                        "This will upload your local changes, download cloud updates, and merge data safely across devices.\n\n"
                        "Activity history is not included in sync.",
            ),

            const SizedBox(height: 20),

            // =========================
            // INITIAL
            // =========================
            if (syncState.status == SyncStatus.initial)
              SizedBox(
                width: double.infinity,
                child: CPositiveButton(
                  callback: () async {
                    await ref.read(syncDataProvider.notifier).syncData();

                    final updatedState = ref.read(syncDataProvider);

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    showSnackBar(
                      updatedState.message ?? '',
                      backgroundColor: updatedState.status == SyncStatus.success
                          ? Colors.green
                          : Colors.red,
                    );
                  },
                  text: 'Sync Now',
                  iconData: Icons.sync_rounded,
                ),
              ),

            // =========================
            // LOADING
            // =========================
            if (syncState.status == SyncStatus.loading)
              const CircularProgressIndicator(),

            const SizedBox(height: 16),

            // Hide cancel button while loading
            if (syncState.status != SyncStatus.loading)
              Align(alignment: Alignment.center, child: CCancelButton()),
          ],
        ),
      ),
    );
  }
}
