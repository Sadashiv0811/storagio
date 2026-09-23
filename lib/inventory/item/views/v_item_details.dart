import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:storagio/activity/v_activity.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_notification.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/inventory/custom_reminder/vm_custom_reminder.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/custom_reminder/v_custom_reminder.dart';
import 'package:storagio/inventory/item/warranty.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/vm_room.dart';

// Consumer and ConsumerStateful Widgets
class VItemDetails extends ConsumerWidget {
  final String itemId;
  final bool disableRoom;
  const VItemDetails({
    super.key,
    required this.itemId,
    required this.disableRoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(customReminderVMProvider);

    final itemsAsync = ref.watch(itemProvider);
    final roomAsync = ref.watch(roomProvider);

    ref.watch(reminderActiveOrNotProvider(itemId));
    // Required to check whether one time reminder scheduled datetime is passed, if passed then update isActive to false.

    final reminderExistsAsync = ref.watch(reminderExistsProvider(itemId));
    // Required to check whether reminder exists for that item or not

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return itemsAsync.when(
      data: (items) {
        final item = items.where((e) => e.id == itemId).firstOrNull;

        if (item == null) {
          return const Center(
            child: Text("Item not found or it may be deleted."),
          );
        }

        final categoryName = item.categoryName;

        String roomName = "",
            editBtnTxt = "Edit Item",
            purchaseDateTxt = "PURCHASE DATE";

        bool notBillsRecharges = categoryName != CategoryNames.billsRecharges;
        bool isElectronic = categoryName == CategoryNames.electronicAppliances;

        if (notBillsRecharges) {
          roomName =
              roomAsync.value
                  ?.firstWhereOrNull((e) => e.id == item.roomId)
                  ?.roomName ??
              "Unknown Room";
        } else {
          editBtnTxt = "Edit";
          purchaseDateTxt = "LAST PAYMENT DATE";
        }

        final String? imagePath = item.imagePath;
        final File? file =
            imagePath != null &&
                imagePath.trim().isNotEmpty &&
                File(imagePath).existsSync()
            ? File(imagePath)
            : null;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: AppBarTitle(),
            actions: isElectronic
                ? reminderExistsAsync.when(
                    data: (exists) => [
                      //  exists == true → Hide the IconButton.
                      //  exists == false → Show the IconButton
                      if (!exists)
                        IconButton(
                          icon: const Icon(Icons.notification_add),
                          onPressed: () async {
                            // To add
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.customReminder,
                              arguments: {'item': item},
                            );

                            // Refresh after returning
                            ref.invalidate(reminderExistsProvider(itemId));
                          },
                        ),
                    ],
                    loading: () => [],
                    error: (_, _) => [],
                  )
                : [],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isElectronic) ...[
                    FutureBuilder(
                      future: vm.fetchReminderByItemId(item.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error loading reminder: ${snapshot.error}',
                          );
                        }

                        final reminder = snapshot.data;

                        // Check if reminder exists and is active
                        if (reminder != null) {
                          return Column(
                            children: [
                              ReminderCard(
                                // Pass the actual dynamic data from the database!
                                reminder: reminder,
                                title: item.name,
                                // Cancels and deletes reminder
                                deleteReminder: () async {
                                  final bool shouldDelete =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (_) => const DeleteRecord(
                                          title: 'Delete Reminder',
                                          message:
                                              'Are you sure you want to delete this reminder? This action cannot be undone.',
                                        ),
                                      ) ??
                                      false;

                                  if (shouldDelete) {
                                    // Cancel reminder
                                    await NotificationService()
                                        .cancelRepeatingCustomNotification(
                                          item.id,
                                        );

                                    // Delete the reminder object
                                    final repo = await ref.read(
                                      customReminderRepositoryProvider.future,
                                    );

                                    await repo.deleteReminder(
                                      reminder: reminder,
                                      itemName: item.name,
                                    );

                                    // Refresh after returning
                                    ref.invalidate(
                                      reminderActiveOrNotProvider(itemId),
                                    );
                                    ref.invalidate(
                                      reminderExistsProvider(itemId),
                                    );
                                    ref.invalidate(activityProvider);
                                  }
                                },
                                // Edit reminder
                                editReminder: () async {
                                  // To edit
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.customReminder,
                                    arguments: {
                                      'item': item,
                                      'reminder': reminder,
                                    },
                                  );

                                  // Refresh after returning
                                  ref.invalidate(
                                    reminderActiveOrNotProvider(itemId),
                                  );
                                  ref.invalidate(
                                    reminderExistsProvider(itemId),
                                  );
                                },
                                // Turn off reminder
                                disableReminder: () async {
                                  // User is allowed to disable reminder when it is enabled
                                  final bool shouldCancel =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (_) => const DeleteRecord(
                                          title: 'Cancel Reminder',
                                          message:
                                              'Are you sure you want to cancel this reminder?',
                                          positiveText: 'Cancel',
                                          negativeText: 'Close',
                                        ),
                                      ) ??
                                      false;

                                  if (shouldCancel) {
                                    // Cancel reminder
                                    await NotificationService()
                                        .cancelRepeatingCustomNotification(
                                          item.id,
                                        );

                                    final repo = await ref.read(
                                      customReminderRepositoryProvider.future,
                                    );

                                    await repo.updateReminderStatus(
                                      reminder.copyWith(
                                        isActive: false,
                                        synced: false,
                                      ),
                                    );

                                    // Refresh after returning
                                    ref.invalidate(
                                      reminderActiveOrNotProvider(itemId),
                                    );
                                  }
                                },
                                // Turn on reminder
                                enableReminder: () async {
                                  // User is allowed to enable reminder when it is disabled

                                  bool isRepeat = reminder.intervalDays != 0;
                                  // Repeating reminder
                                  if (isRepeat) {
                                    await NotificationService()
                                        .scheduleRepeatingCustomNotification(
                                          itemId: itemId,
                                          itemName: item.name,
                                          content: reminder.content,
                                          startDate: reminder.startDate,
                                          intervalDays: reminder.intervalDays,
                                          isRepeat: isRepeat,
                                        );

                                    final repo = await ref.read(
                                      customReminderRepositoryProvider.future,
                                    );

                                    await repo.updateReminderStatus(
                                      reminder.copyWith(
                                        isActive: true,
                                        synced: false,
                                      ),
                                    );
                                  }
                                  // Non-Repeating reminder so navigate to update screen
                                  else {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.customReminder,
                                      arguments: {
                                        'item': item,
                                        'reminder': reminder,
                                      },
                                    );
                                  }

                                  // Refresh after returning
                                  ref.invalidate(
                                    reminderActiveOrNotProvider(itemId),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }

                        // Return an empty box if there is no reminder
                        return const SizedBox.shrink();
                      },
                    ),

                    if (item.warrantyExpiry!.isBefore(today)) ...[
                      _ExpiredItemWarning(onDelete: () {}),
                      const SizedBox(height: 20),
                    ],
                  ],

                  if (notBillsRecharges && file != null) ...[
                    _ItemHeaderImage(file: file),
                    SizedBox(height: 20),
                  ],

                  _CategoryTag(categoryName: categoryName),

                  SizedBox(height: 10),
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 18),
                  _ActionButtonsRow(
                    editText: editBtnTxt,
                    editCB: () async {
                      // Updated the selected room and category provider.
                      if (categoryName != CategoryNames.billsRecharges) {
                        await ref
                            .read(selectedRoomProvider.notifier)
                            .setSelectedRoom(item.roomId!);
                      }

                      await ref
                          .read(selectedCategoryProvider.notifier)
                          .setSelectedCategory(item.categoryName);

                      if (!context.mounted) return;

                      Navigator.pushNamed(
                        context,
                        AppRoutes.addEditItem,
                        arguments: {'item': item, 'disableRoom': disableRoom},
                      );
                      await ref.read(itemProvider.notifier).refresh();
                    },
                    deleteCB: () async {
                      final shouldDelete =
                          await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return DeleteRecord(
                                title: "Delete Item",
                                message:
                                    "Are you sure you want to delete this item?\nThis action cannot be undone.",
                              );
                            },
                          ) ??
                          false;

                      if (shouldDelete == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        await ref.read(itemProvider.notifier).deleteItem(item);
                      }
                    },
                  ),
                  SizedBox(height: 18),

                  if (!notBillsRecharges) ...[
                    _InfoCard(
                      icon: Icons.wallet_outlined,
                      label: 'LAST PAYMENT AMOUNT',
                      value: "Rs. ${item.lastPaymentAmount}",
                      iconColor: Colors.teal,
                    ),
                  ],

                  if (notBillsRecharges) ...[
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        if (item.quantity != null)
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.4,
                            child: _InfoCard(
                              icon: Icons.inventory_2_outlined,
                              label: 'CURRENT QUANTITY',
                              value: formatQuantity(item.quantity ?? 0),
                              iconColor: Color(0xFF1E88E5),
                              isCenter: true,
                              unit: item.unit,
                            ),
                          ),
                        if (item.lowStockLimit != null)
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.4,
                            child: _InfoCard(
                              icon: Icons.production_quantity_limits_outlined,
                              label: 'LOW STOCK LIMIT',
                              value: formatQuantity(item.lowStockLimit ?? 0),
                              iconColor: Color(0xFF1E88E5),
                              isCenter: true,
                              unit: item.unit,
                            ),
                          ),
                      ],
                    ),

                    _InfoCard(
                      icon: Icons.location_pin,
                      label: 'ROOM',
                      value: roomName,
                      iconColor: Colors.teal,
                    ),
                  ],

                  if (item.purchaseDate != null)
                    _InfoCard(
                      icon: Icons.calendar_today_outlined,
                      label: purchaseDateTxt,
                      value: item.purchaseDate != null
                          ? DateFormat("dd MMM yyyy").format(item.purchaseDate!)
                          : "N/A",
                      iconColor: Colors.brown,
                    ),

                  if (item.warrantyExpiry != null)
                    WarrantyCard(
                      purchaseDate: item.purchaseDate,
                      warrantyExpiry: item.warrantyExpiry!,
                      categoryName: item.categoryName,
                    ),

                  if (item.notes != null)
                    _NotesCard(
                      note: "${item.notes}",
                      categoryName: categoryName,
                    ),

                  SizedBox(height: 20),
                  HistorySection(itemId: item.id),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (err, stack) =>
          Scaffold(body: Center(child: Text(err.toString()))),
    );
  }
}

class HistorySection extends ConsumerStatefulWidget {
  final String itemId;

  const HistorySection({super.key, required this.itemId});

  @override
  ConsumerState<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<HistorySection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityAsync = ref.watch(activityProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: isDark ? Colors.grey.shade100 : Colors.grey,
                ),
                SizedBox(width: 20),
                const Expanded(
                  child: Text(
                    'History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  icon: AnimatedRotation(
                    turns: isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                ),
              ],
            ),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  const SizedBox(height: 20),
                  activityAsync.when(
                    data: (activities) {
                      // Filter by itemId
                      final filteredActivities =
                          activities
                              .where(
                                (activity) =>
                                    activity.entityId == widget.itemId,
                              )
                              .toList()
                            ..sort(
                              (a, b) => b.createdAt.compareTo(a.createdAt),
                            ); // Sort new -> old

                      if (filteredActivities.isEmpty) {
                        return const Center(child: Text('No history found'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          final activity = filteredActivities[index];

                          return ActivityCard(
                            activity: activity,
                            showLine: index != filteredActivities.length - 1,
                            isDT: true,
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),

                    error: (e, _) => Center(child: Text(e.toString())),
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateless Widgets
class _CategoryTag extends StatelessWidget {
  final String categoryName;
  const _CategoryTag({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String note;
  final String categoryName;

  const _NotesCard({required this.note, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    String title = 'NOTES';
    if (categoryName == CategoryNames.medicines) {
      title = 'PURPOSE';
    }
    if (categoryName == CategoryNames.electronicAppliances) {
      title = 'MAINTENANCE DETAILS';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CLabel(text: title),
            const SizedBox(height: 12),
            CustomInnerShadow(
              shadowColor: const Color(0xFFB0C4DE).withValues(alpha: 0.5),
              blur: 5,
              offset: const Offset(0, 3),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '"$note"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isCenter;
  final String? unit;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isCenter = false,
    this.unit = "",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: isCenter ? .center : .start,
            children: [
              CLabel(text: label),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: .min,
                crossAxisAlignment: .center,
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: label == 'ROOM' ? 1 : 0,
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (unit != "") ...[
                    const SizedBox(width: 6),
                    Text(
                      unit.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final VoidCallback editCB;
  final VoidCallback deleteCB;
  final String editText;
  const _ActionButtonsRow({
    required this.editCB,
    required this.deleteCB,
    required this.editText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CPositiveButton(
            callback: editCB,
            iconData: Icons.edit,
            text: editText,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: deleteCB,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.transparent),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
              shadowColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemHeaderImage extends StatelessWidget {
  final File file;
  const _ItemHeaderImage({required this.file});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: isDark ? Color.fromARGB(255, 0, 140, 204) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              blurRadius: 6,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(file.path), height: 200, width: 200),
          ),
        ),
      ),
    );
  }
}

class _ExpiredItemWarning extends StatelessWidget {
  const _ExpiredItemWarning({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade400, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_rounded,
            color: Colors.redAccent.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Action Required",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "This item has expired.\nYou can either update or delete it from your inventory",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade900,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
