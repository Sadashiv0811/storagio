import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:storagio/activity/v_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/category/bs_all_category.dart';
import 'package:storagio/inventory/category/m_category.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/item/warranty.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/bs_all_rooms.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/room/d_add_edit.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/room/vm_room.dart';

// Consumer and ConsumerStateful Widgets
class VInventory extends ConsumerStatefulWidget {
  const VInventory({super.key});

  @override
  ConsumerState<VInventory> createState() => _VInventoryState();
}

class _VInventoryState extends ConsumerState<VInventory> {
  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryProvider);
    final selectedCategoryName = ref.watch(selectedCategoryProvider).value;

    final roomAsync = ref.watch(roomProvider);
    final selectedRoomId = ref.watch(selectedRoomProvider).value;

    final itemAsync = ref.watch(itemProvider);

    final categoryColorMap = {
      for (final c in categoryAsync.value ?? []) c.categoryName: c.color,
    };

    final roomMap = {for (final r in roomAsync.value ?? []) r.id: r.roomName};

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addEditItem);
          // Already updated the selected room and category provider.
        },
        heroTag: "Inventory",
        backgroundColor: const Color(0xFF0056B3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),

        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const HeaderSection(
                title: "My Inventory & Payments",
                message: "Know what you have, what you need, and what’s due",
              ),
            ),
          ),

          // UnorganizedItemsCard
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: itemAsync.when(
              data: (items) {
                final unknownRoomCount = items.where((item) {
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
                }).length;

                if (unknownRoomCount == 0) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: _UnorganizedItemsCard(
                    unknownRoomCount: unknownRoomCount,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.unorganizedItems);
                    },
                  ),
                );
              },

              loading: () => const SliverToBoxAdapter(child: LoadingDisplay()),

              error: (error, stack) => SliverToBoxAdapter(
                child: ErrorDisplay(error: error, stack: stack),
              ),
            ),
          ),

          // Category Filters
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: categoryAsync.when(
              data: (categoriesData) {
                // No categories
                if (categoriesData.isEmpty) {
                  return SliverToBoxAdapter(child: SizedBox.shrink());
                }

                // Create mutable list
                final reorderedCategories = [...categoriesData];

                // Move selected category to top
                if (selectedCategoryName != null) {
                  final index = reorderedCategories.indexWhere(
                    (e) => e.categoryName == selectedCategoryName,
                  );

                  if (index != -1) {
                    final selected = reorderedCategories.removeAt(index);
                    reorderedCategories.insert(0, selected);
                  }
                }

                // First 4 only
                final visibleCategories = reorderedCategories.take(4).toList();

                return SliverToBoxAdapter(
                  child: _CategorySection(
                    selectedCategoryName: selectedCategoryName,
                    onCategorySelected: (categoryName) async {
                      await ref
                          .read(selectedCategoryProvider.notifier)
                          .setSelectedCategory(categoryName);
                    },
                    list: visibleCategories,
                    showMore: categoriesData.length > 4,
                    onMoreTap: () {
                      showModalBottomSheet(
                        sheetAnimationStyle: const AnimationStyle(
                          duration: Duration(milliseconds: 800),
                          reverseDuration: Duration(milliseconds: 800),
                        ),
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const CategoriesBottomSheet(),
                      );
                    },
                  ),
                );
              },

              loading: () => const SliverToBoxAdapter(child: LoadingDisplay()),

              error: (error, stack) => SliverToBoxAdapter(
                child: ErrorDisplay(error: error, stack: stack),
              ),
            ),
          ),

          // Room Filter
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: roomAsync.when(
              data: (roomsData) {
                // If category is "Bills & Recharges" then hide do not show Room Section
                if (selectedCategoryName == CategoryNames.billsRecharges) {
                  return SliverToBoxAdapter(child: SizedBox.shrink());
                }

                // No rooms
                if (roomsData.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyRooms(
                      addCallback: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => const AddEditRoomDialog(),
                        );
                      },
                      title: "ROOMS",
                      message: "No rooms added yet. Tap + button to add room.",
                      titleFontSize: 14,
                    ),
                  );
                }

                // Create mutable list
                final reorderedRooms = [...roomsData];

                // Move selected room to top
                if (selectedRoomId != null) {
                  final index = reorderedRooms.indexWhere(
                    (e) => e.id == selectedRoomId,
                  );

                  if (index != -1) {
                    final selected = reorderedRooms.removeAt(index);
                    reorderedRooms.insert(0, selected);
                  }
                }

                // First 4 only
                final visibleRooms = reorderedRooms.take(4).toList();

                return SliverToBoxAdapter(
                  child: _RoomSection(
                    selectedRoomId: selectedRoomId,

                    onRoomSelected: (String roomId) async {
                      await ref
                          .read(selectedRoomProvider.notifier)
                          .setSelectedRoom(roomId);
                    },

                    list: visibleRooms,
                    showMore: roomsData.length > 4,

                    onMoreTap: () {
                      showModalBottomSheet(
                        context: context,
                        sheetAnimationStyle: const AnimationStyle(
                          duration: Duration(milliseconds: 800),
                          reverseDuration: Duration(milliseconds: 800),
                        ),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const RoomBottomSheet(),
                      );
                    },

                    addRoom: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const AddEditRoomDialog(),
                      );
                    },
                  ),
                );
              },

              loading: () => const SliverToBoxAdapter(child: LoadingDisplay()),

              error: (error, stack) => SliverToBoxAdapter(
                child: ErrorDisplay(error: error, stack: stack),
              ),
            ),
          ),

          // Inventory List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            sliver: itemAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: "No Items or Payments Added",
                          description:
                              "Start adding items/payments to organize your home",
                          actionText:
                              "Tap the floating Add button below\nto insert items/payments.",
                        ),
                      ),
                    ),
                  );
                }

                final filteredItems = items.where((item) {
                  final isBillsAndRecharges =
                      item.categoryName == CategoryNames.billsRecharges;

                  // Apply conditional filtering based on the category type
                  if (isBillsAndRecharges) {
                    // If it's Bills & Recharges, match the category and ensure the item has no room
                    return item.categoryName == selectedCategoryName &&
                        item.roomId == null;
                  }

                  // Default filtering for everything else
                  final categoryMatch =
                      selectedCategoryName == null ||
                      item.categoryName == selectedCategoryName;

                  final roomMatch =
                      selectedRoomId == null || item.roomId == selectedRoomId;

                  return categoryMatch && roomMatch;
                }).toList();

                if (filteredItems.isEmpty) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: "No Matching Items",
                          description: "No items found for selected filters.",
                          actionText: 'Change category or room',
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredItems[index];

                    final categoryColor =
                        categoryColorMap[item.categoryName] ?? Colors.black;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: _InventoryCard(
                        item: item,
                        categoryColor: categoryColor,
                        roomName: roomMap[item.roomId] ?? "Unknown Room",

                        callback: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.itemDetails,
                            arguments: {'itemId': item.id},
                          );
                        },
                      ),
                    );
                  }, childCount: filteredItems.length),
                );
              },

              loading: () => const SliverToBoxAdapter(child: LoadingDisplay()),

              error: (error, stack) => SliverToBoxAdapter(
                child: ErrorDisplay(error: error, stack: stack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stateless Widgets
class _CategorySection extends StatelessWidget {
  final String? selectedCategoryName;
  final Function(String categoryname) onCategorySelected;
  final List<MCategory> list;
  final bool showMore;
  final VoidCallback onMoreTap;

  const _CategorySection({
    required this.selectedCategoryName,
    required this.onCategorySelected,
    required this.list,
    required this.showMore,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownItems = [
      ...list.map((e) => e.categoryName),

      if (showMore) "More",
    ];

    String selectedValue = dropdownItems.first;

    final selectedCategory = list.where(
      (e) => e.categoryName == selectedCategoryName,
    );

    if (selectedCategory.isNotEmpty) {
      selectedValue = selectedCategory.first.categoryName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Text(
          "CATEGORIES",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 10),

        CDropDown(
          type: "CATEGORY",
          value: selectedValue,
          valueList: dropdownItems,

          onChanged: (String? value) {
            if (value == null) return;

            if (value == "More") {
              onMoreTap();
              return;
            }

            final category = list.firstWhere((e) => e.categoryName == value);

            onCategorySelected(category.categoryName);
          },
        ),
      ],
    );
  }
}

class _RoomSection extends StatelessWidget {
  final String? selectedRoomId;
  final Function(String id) onRoomSelected;
  final List<MRoom> list;
  final VoidCallback addRoom;
  final bool showMore;
  final VoidCallback onMoreTap;

  const _RoomSection({
    required this.selectedRoomId,
    required this.onRoomSelected,
    required this.list,
    required this.addRoom,
    required this.showMore,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownItems = [
      ...list.map((e) => e.roomName),

      if (showMore) "More",
    ];

    String selectedValue = dropdownItems.first;

    final selectedRoom = list.where((e) => e.id == selectedRoomId);

    if (selectedRoom.isNotEmpty) {
      selectedValue = selectedRoom.first.roomName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ROOMS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),

            IconButton(onPressed: addRoom, icon: const Icon(Icons.add)),
          ],
        ),

        CDropDown(
          type: "ROOM",
          value: selectedValue,
          valueList: dropdownItems,

          onChanged: (String? value) {
            if (value == null) return;

            if (value == "More") {
              onMoreTap();
              return;
            }

            final room = list.firstWhere((e) => e.roomName == value);

            onRoomSelected(room.id);
          },
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final int categoryColor;
  final String roomName;
  final MItem item;
  final VoidCallback callback;

  const _InventoryCard({
    required this.categoryColor,
    required this.roomName,
    required this.callback,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final String categoryName = item.categoryName;
    final isBills = categoryName == CategoryNames.billsRecharges;

    bool showExpiryBar =
        item.purchaseDate != null && item.warrantyExpiry != null;

    // Warranty/Expiry status and Bills & Recharge Due date status
    TimeProgress? result;

    if (showExpiryBar) {
      result = calculateTimeProgress(
        startDate: item.purchaseDate!,
        endDate: item.warrantyExpiry!,
      );
    }

    int remainingDays = 0;
    double progress = 0.0;
    Color progressColor = Colors.green;
    bool isExpired = false;
    String expiryText = "";

    if (result != null) {
      remainingDays = result.remainingDays;
      progress = result.progress;
      isExpired = result.expired;
      progressColor = getColor(result.status);
      expiryText = getExpiryText(isExpired, isBills, remainingDays);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Basic
    final String title = item.name;
    final String? imagePath = item.imagePath;

    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    // Stock Status and bar
    final double? qty = item.quantity;
    final double? lowStockLimit = item.lowStockLimit;
    double? stockValue;

    // Progress value for LinearProgressIndicator
    if (qty != null && lowStockLimit != null) {
      stockValue = qty == 0
          ? 0
          : qty >= lowStockLimit
          ? 1
          : qty / lowStockLimit;
    }

    final stockStatus = item.getStockStatus();
    StockInfo stockInfo = getStockInfo(stockStatus);
    Color stockColor = stockInfo.color;
    String stockLabel = stockInfo.label;
    bool showStockBar = !isBills && stockValue != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 1),
      elevation: 5,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Future.delayed(Duration(milliseconds: 1000));
          callback();
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.3),
        child: Ink(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  crossAxisAlignment: .start,
                  children: [
                    // Image
                    if (categoryName != CategoryNames.billsRecharges) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: file != null
                            ? Image.file(
                                File(file.path),
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              )
                            : SizedBox.shrink(),
                      ),
                      SizedBox(width: file != null ? 12 : 0),
                    ],

                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,

                        children: [
                          // Title/Name
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Category name
                          CategoryNameChip(
                            bgColor: Color(categoryColor),
                            categoryName: categoryName,
                          ),
                          const SizedBox(height: 6),

                          if (file != null) ...[
                            // Room name
                            getRoomDisplay(),

                            // Quantity
                            if (qty != null) getQuantityDisplay(qty),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Bills & Recharges
                if (isBills) ...[
                  BillsRechargesFields(item: item),
                  const SizedBox(height: 4),

                  FieldsDisplayRow(title: "", value: expiryText),
                  const SizedBox(height: 4),
                ],

                // Room name & Quantity in a row when image is null
                if (!isBills && imagePath == null)
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      // Room name
                      getRoomDisplay(),

                      // Quantity
                      if (qty != null) ...[getQuantityDisplay(qty)],
                    ],
                  ),

                // Stock bar and status
                if (showStockBar) ...[
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "STOCK LEVEL",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stockLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: stockColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stockValue,
                      backgroundColor: Colors.grey.shade200,
                      color: stockColor,
                      minHeight: 8,
                    ),
                  ),
                ],

                // Expiry bar, Status shown for items which have purchase and expiry date.
                if (showExpiryBar) ...[
                  if (!isBills) ...[
                    SizedBox(height: 6),
                    FieldsDisplayRow(
                      title: item.warrantyExpiry!.isBefore(today)
                          ? "Expired on"
                          : item.warrantyExpiry!.isToday
                          ? "Expires today"
                          : "Expires on",
                      value: item.warrantyExpiry!.isToday
                          ? ""
                          : DateFormat(
                              "dd MMM yyyy",
                            ).format(item.warrantyExpiry!),
                      valueColor: progressColor,
                    ),
                  ],

                  if (!showStockBar) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 12,
                            backgroundColor: const Color(0xFFEEEEEE),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getRoomDisplay() {
    return _RoomQuantityFields(
      iconData: Icons.location_on_outlined,
      text: roomName,
    );
  }

  Widget getQuantityDisplay(double qty) {
    return _RoomQuantityFields(
      iconData: Icons.inventory_outlined,
      text: "Qty: ${formatQuantity(qty)} ${item.unit}",
    );
  }
}

class _UnorganizedItemsCard extends StatelessWidget {
  final int unknownRoomCount;

  final VoidCallback onTap;

  const _UnorganizedItemsCard({
    required this.unknownRoomCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = unknownRoomCount;
    final List<String> details = [];

    if (unknownRoomCount > 0) {
      details.add(
        unknownRoomCount == 1
            ? '• 1 item without room'
            : '• $unknownRoomCount items without room',
      );
    }

    final subtitle = details.join('\n');

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(top: 20),
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalCount > 1
                          ? '$totalCount Items Need Organization'
                          : '$totalCount Item Need Organization',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomQuantityFields extends StatelessWidget {
  final IconData iconData;
  final String text;
  const _RoomQuantityFields({required this.iconData, required this.text});

  @override
  Widget build(BuildContext context) {
    final isRoom = iconData == Icons.location_on_outlined ? true : false;

    return Row(
      mainAxisSize: .min,
      children: [
        Icon(iconData, size: 18),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isRoom ? 120 : double.infinity),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ),
      ],
    );
  }
}
