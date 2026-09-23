import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/m_rooms.dart';

// Consumer Widgets
class VRoomItems extends ConsumerWidget {
  final MRoom room;
  const VRoomItems({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider);
    final selectedCategoryName = ref.watch(selectedCategoryProvider).value;

    return Scaffold(
      appBar: AppBar(title: appBarText(room.roomName)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              sliver: SliverList(
                delegate: SliverChildListDelegate([HeaderSection(room: room)]),
              ),
            ),

            /// Item Cards List
            itemAsync.when(
              data: (itemsList) {
                // Filter items for current room
                final filteredItems = itemsList
                    .where((item) => item.roomId == room.id)
                    .toList();

                if (filteredItems.isEmpty) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: "No Items Added Yet",
                          description:
                              "Start adding items to organize\nyour inventory.",
                          actionText: "Tap the FAB to add item",
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredItems[index];

                      return _ItemCard(
                        item: item,
                        onTapCard: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.itemDetails,
                            arguments: {'itemId': item.id, 'disableRoom': true},
                          );
                        },
                      );
                    }, childCount: filteredItems.length),
                  ),
                );
              },

              error: (error, stack) => SliverToBoxAdapter(
                child: ErrorDisplay(error: error, stack: stack),
              ),

              loading: () => const SliverToBoxAdapter(child: LoadingDisplay()),
            ),

            /// Bottom spacing for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Updated the selected room provider.
          await ref
              .read(selectedRoomProvider.notifier)
              .setSelectedRoom(room.id);

          // Updated the selected category provider if category is billsRecharges.
          if (selectedCategoryName == CategoryNames.billsRecharges) {
            await ref
                .read(selectedCategoryProvider.notifier)
                .setSelectedCategory(CategoryNames.bathroomEssentials);
          }

          if (!context.mounted) return;

          Navigator.pushNamed(
            context,
            AppRoutes.addEditItem,
            arguments: {'disableRoom': true},
          );
        },
        backgroundColor: const Color(0xFF0056A2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

class HeaderSection extends ConsumerWidget {
  final MRoom room;
  const HeaderSection({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemsAsync = ref.watch(itemProvider);

    final roomItemCount = itemsAsync.when(
      data: (items) {
        return items.where((item) => item.roomId == room.id).length;
      },
      loading: () => 0,
      error: (_, _) => 0,
    );

    String subtitle = "";

    if (roomItemCount == 0) {
      subtitle = "";
    } else if (roomItemCount <= 1) {
      subtitle = '$roomItemCount item';
    } else {
      subtitle = '$roomItemCount items';
    }

    return Row(
      crossAxisAlignment: .start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.shadow,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              IconData(int.parse(room.icon), fontFamily: 'MaterialIcons'),
              size: 35,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: .min,
            children: [
              Text(
                '${room.roomName}\nInventory',

                maxLines: 2,
                overflow: .ellipsis,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Stateless Widgets
class _ItemCard extends StatelessWidget {
  final MItem item;
  final VoidCallback onTapCard;

  const _ItemCard({required this.onTapCard, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String title = item.name;
    final double? qty = item.quantity;
    final String category = item.categoryName;

    final String? imagePath = item.imagePath;
    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    final stockStatus = item.getStockStatus();
    StockInfo stockInfo = getStockInfo(stockStatus);
    Color stockColor = stockInfo.color;
    String stockLabel = stockInfo.label;

    return InkWell(
      onTap: onTapCard,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Item Image/Icon Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: file != null
                    ? Image.file(
                        File(file.path),
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      )
                    : const ImagePlaceHolder(size: 80),
              ),

              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: isDark
                                ? const Color.fromARGB(255, 37, 248, 255)
                                : Color(0xFF006B5E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),

                        if (stockStatus != StockStatus.good && qty != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: stockColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              stockLabel,
                              style: TextStyle(
                                color: stockColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (qty != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Current Qty: ${formatQuantity(qty)} ${item.unit}",
                          style: TextStyle(
                            fontSize: 14,
                            color: stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
