import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/utils/input_validators.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';

enum CardType { expired, empty, lowStock }

final expandedSectionsProvider =
    NotifierProvider<ExpandedSectionsNotifier, Map<CardType, bool>>(
      ExpandedSectionsNotifier.new,
    );

class ExpandedSectionsNotifier extends Notifier<Map<CardType, bool>> {
  @override
  Map<CardType, bool> build() => {};

  bool isExpanded(CardType type) => state[type] ?? false;

  void setExpanded(CardType type, bool expanded) {
    state = {...state, type: expanded};
  }

  void toggle(CardType type) {
    setExpanded(type, !(state[type] ?? false));
  }

  void clear() {
    state = {};
  }
}

class VItemAlerts extends ConsumerWidget {
  const VItemAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: appBarText("Item Alerts")),
      body: SafeArea(
        child: itemAsync.when(
          data: (itemsList) {
            if (itemsList.isEmpty) {
              return Center(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: "No Items or Payments Added",
                  description:
                      "Start adding items/payments to organize your home",
                  actionText:
                      "Tap the floating Add button below\nto insert items/payments.",
                ),
              );
            }

            // Empty Lists
            final List<MItem> expiredList = [],
                emptyStockItemsList = [],
                lowStockItemsList = [];

            for (var item in itemsList) {
              // Expired
              final expiry = item.warrantyExpiry;
              if (expiry != null && expiry.isBefore(today)) {
                expiredList.add(item);
              }

              final quantity = item.quantity;
              final lowStockLimit = item.lowStockLimit;

              if (quantity == null) continue;

              // Empty stock
              if (quantity == 0) {
                emptyStockItemsList.add(item);
                continue;
              }

              // Low stock
              if (lowStockLimit != null && quantity < lowStockLimit) {
                lowStockItemsList.add(item);
              }
            }

            final expiredCount = expiredList.length;
            final emptyStockCount = emptyStockItemsList.length;
            final lowStockCount = lowStockItemsList.length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomScrollView(
                slivers: [
                  if (expiredCount > 0)
                    SliverToBoxAdapter(
                      child: _ExpandableItemSection(
                        title: "Expired Items",
                        subtitle:
                            "⚠️ $expiredCount expired ${expiredCount > 1 ? "items" : "item"} found.\nSome warranties, bills or recharges have expired.",
                        itemsList: expiredList,
                        type: CardType.expired,
                      ),
                    ),

                  if (emptyStockCount > 0)
                    SliverToBoxAdapter(
                      child: _ExpandableItemSection(
                        title: "Empty Stock Items",
                        subtitle:
                            "⚠️ $emptyStockCount empty stock ${emptyStockCount > 1 ? "items" : "item"} found.",
                        itemsList: emptyStockItemsList,
                        type: CardType.empty,
                        showEditAction: true,
                      ),
                    ),

                  if (lowStockCount > 0)
                    SliverToBoxAdapter(
                      child: _ExpandableItemSection(
                        title: "Low Stock Items",
                        subtitle:
                            "⚠️ $lowStockCount low stock ${lowStockCount > 1 ? "items" : "item"} found.",
                        itemsList: lowStockItemsList,
                        type: CardType.lowStock,
                        showEditAction: true,
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                ],
              ),
            );
          },
          loading: () => LoadingDisplay(),

          error: (error, stack) => ErrorDisplay(error: error, stack: stack),
        ),
      ),
    );
  }
}

class _ExpandableItemSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final List<MItem> itemsList;
  final CardType type;
  final bool showEditAction;

  const _ExpandableItemSection({
    required this.title,
    required this.subtitle,
    required this.itemsList,
    required this.type,
    this.showEditAction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textThemes = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expanded = ref.watch(
      expandedSectionsProvider.select((state) => state[type] ?? false),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        splashColor: Colors.transparent,
        initiallyExpanded: expanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        iconColor: isDark ? Colors.white : Colors.black,
        title: Text(
          title,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: textThemes.bodySmall?.copyWith(fontSize: 14),
        ),
        children: [
          ListView.builder(
            itemCount: itemsList.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = itemsList[index];

              return Slidable(
                key: ValueKey(item.id),
                endActionPane: deleteActionPane(item: item, ref: ref),
                startActionPane: showEditAction
                    ? editActionPane(item: item, ref: ref)
                    : null,
                child: itemCard(item: item, type: type, textThemes: textThemes),
              );
            },
          ),
        ],
      ),
    );
  }

  ActionPane editActionPane({required MItem item, required WidgetRef ref}) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.25,
      children: [
        SlidableAction(
          onPressed: (context) async {
            final String? value = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return _EditQuantityDialog(item: item);
              },
            );

            if (value == null) return;

            final newQty = double.parse(value.toString());
            final updatedItem = item.copyWith(
              quantity: () => newQty,
              synced: false,
            );

            final notifier = ref.read(itemProvider.notifier);
            // OLD and  NEW item
            await notifier.updateItem(item, updatedItem);

            logger.i("Item updated");
          },
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(10),
          borderRadius: BorderRadius.circular(14),
          icon: Icons.edit_outlined,
          autoClose: true,
          label: 'Edit',
        ),
      ],
    );
  }

  ActionPane deleteActionPane({required MItem item, required WidgetRef ref}) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.25,
      children: [
        SlidableAction(
          onPressed: (context) async {
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
              await ref.read(itemProvider.notifier).deleteItem(item);
            }
          },
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          icon: Icons.delete_outline,
          padding: EdgeInsets.all(10),
          autoClose: true,
          borderRadius: BorderRadius.circular(14),
          label: 'Delete',
        ),
      ],
    );
  }

  Widget coloredBar(Color color) {
    final isEdit = color == Colors.green;
    return Container(
      padding: EdgeInsets.all(8),
      width: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: !isEdit
            ? BorderRadius.only(
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              )
            : BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
      ),
    );
  }

  Widget itemCard({
    required MItem item,
    required CardType type,
    required TextTheme textThemes,
  }) {
    final expirtDT = item.warrantyExpiry;

    final String? imagePath = item.imagePath;

    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    final isExpired = type == CardType.expired;

    return Card(
      shape: isExpired
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: .min,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  crossAxisAlignment: .start,
                  children: [
                    // Image
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

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textThemes.bodyMedium?.copyWith(
                              fontWeight: .bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CategoryNameChip(categoryName: item.categoryName),
                          const SizedBox(height: 8),
                          if (type == CardType.expired)
                            Text(
                              expirtDT == null
                                  ? ""
                                  : "Expired ${DateFormat('dd MMM yyyy').format(expirtDT)}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (type != CardType.expired) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Avl: ${item.quantity}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),

                      if (item.lowStockLimit != null) ...[
                        Text(
                          "Limit: ${item.lowStockLimit}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                      ],

                      Text(
                        "Unit: ${item.unit}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isExpired)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: coloredBar(Colors.green),
            ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: coloredBar(Colors.red),
          ),
        ],
      ),
    );
  }
}

class _EditQuantityDialog extends StatelessWidget {
  final MItem item;
  const _EditQuantityDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final editQuantityFK = GlobalKey<FormState>();
    final TextEditingController controller = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
        child: SingleChildScrollView(
          child: Form(
            key: editQuantityFK,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: .start,
              children: [
                Align(
                  alignment: .topCenter,
                  child: const Text(
                    'Edit Quantity',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 25),
                const CLabel(text: 'CURRENT QUANTITY', requiredField: true),
                CTextFormField(
                  hint: "e.g. 5 or 2.5",
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: AppValidators.quantity,
                  prefixIconData: Icons.inventory_2_outlined,
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: CPositiveButton(
                    text: 'Save',
                    callback: () {
                      if (editQuantityFK.currentState?.validate() ?? false) {
                        Navigator.pop(
                          context,
                          controller.text.toString().trim(),
                        );
                      }
                    },
                    iconData: Icons.save,
                  ),
                ),
                const SizedBox(height: 10),
                Align(alignment: .center, child: CCancelButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
