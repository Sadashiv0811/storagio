import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/room/vm_room.dart';

// Consumer Widgets
class VUnorganizedItems extends ConsumerWidget {
  const VUnorganizedItems({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider);
    final itemAsync = ref.watch(itemProvider);

    final roomMap = {for (final r in roomAsync.value ?? []) r.id: r.roomName};

    return Scaffold(
      appBar: AppBar(title: appBarText("Unorganized Items")),
      body: itemAsync.when(
        data: (items) {
          final unknownRoomItems = items.where((item) {
            final categoryExists = CategoryNames.categoryList.contains(
              item.categoryName,
            );

            final roomMissing = !roomMap.containsKey(item.roomId);

            // Check if the item belongs to "Bills & Recharges"
            final isBillsAndRecharges =
                item.categoryName == CategoryNames.billsRecharges;

            // If it's Bills & Recharges, it's allowed to not have a room, so don't count it
            if (isBillsAndRecharges) return false;

            return categoryExists && roomMissing;
          }).toList();

          if (unknownRoomItems.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: const EmptyState(
                  icon: Icons.verified_rounded,
                  title: "Great Job!",
                  description:
                      "There are no unorganized items. Every item is organized.",
                ),
              ),
            );
          }

          logger.d("Room unknown: ${unknownRoomItems.length}");

          final String subtitle = unknownRoomItems.length == 1
              ? "${unknownRoomItems.length} item need attention"
              : "${unknownRoomItems.length} items need attention";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                SizedBox(height: 10),
                const Text(
                  'Inventory Cleanup',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 30,
                      color: Color(0xFFC81E1E),
                    ),
                    SizedBox(width: 6),
                    Text(subtitle, style: TextStyle(fontSize: 16)),
                  ],
                ),
                SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: unknownRoomItems.length,
                  itemBuilder: (context, index) {
                    final item = unknownRoomItems[index];

                    return _ItemCard(item: item);
                  },
                ),
                SizedBox(height: 32),
              ],
            ),
          );
        },

        loading: () => const LoadingDisplay(),

        error: (error, stack) => ErrorDisplay(error: error, stack: stack),
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final MItem item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProvider);
    final categoryColorMap = {
      for (final c in categoryAsync.value ?? []) c.categoryName: c.color,
    };
    final categoryColor = categoryColorMap[item.categoryName] ?? Colors.black;

    final String title = item.name;

    final String? imagePath = item.imagePath;
    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: file != null
                      ? Image.file(
                          File(file.path),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        )
                      : ImagePlaceHolder(size: 80),
                ),
                SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Category name
                      CategoryNameChip(
                        bgColor: Color(categoryColor),
                        categoryName: item.categoryName,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Assign Room
            SizedBox(
              height: 48,
              width: double.infinity,
              child: CPositiveButton(
                callback: () async {
                  // Show dialog and update room
                  await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => _SelectRoomDialog(item: item),
                  );
                },
                iconData: Icons.location_on_outlined,
                text: "Assign Room",
              ),
            ),
            const SizedBox(height: 20),
            // Delete Item
            SizedBox(
              height: 48,
              width: double.infinity,
              child: CPositiveButton(
                callback: () async {
                  if (!context.mounted) return;

                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return DeleteRecord(
                        title: "Delete Item",
                        message:
                            "Are you sure you want to delete this item?\nThis action cannot be undone.",
                      );
                    },
                  );

                  if (shouldDelete == true) {
                    await ref.read(itemProvider.notifier).deleteItem(item);
                  }
                },
                bgColor: Colors.red,
                iconData: Icons.delete,
                text: "Delete Item",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectRoomDialog extends ConsumerWidget {
  final MItem item;
  const _SelectRoomDialog({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider);

    final List<MRoom> roomList = List<MRoom>.from(roomAsync.value ?? <MRoom>[]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Room',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Room List
            ListView.builder(
              shrinkWrap: true,
              itemCount: roomList.length,
              itemBuilder: (context, index) {
                final room = roomList[index];
                return CTile(
                  uniqueKey: room.id,
                  isSelected: false,
                  title: room.roomName,
                  color: room.color,
                  icon: room.icon,
                  onTap: () async {
                    // Update items room id
                    final updatedItem = item.copyWith(
                      roomId: () => room.id,
                      synced: false,
                    );
                    
                    final notifier = ref.read(itemProvider.notifier);
                    // OLD and  NEW item
                    await notifier.updateItem(item, updatedItem);

                    logger.i("Item updated");

                    await ref.read(itemProvider.notifier).refresh();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Close dialog
            const CCancelButton(),
          ],
        ),
      ),
    );
  }
}
