import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/d_add_edit.dart';
import 'package:storagio/room/vm_room.dart';

// Consumer Widgets
class VRoom extends ConsumerWidget {
  const VRoom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider);

    final itemsAsync = ref.watch(itemProvider);
    final itemsList = itemsAsync.value;

    final itemCount = itemsList != null ? itemsList.length : 0;

    return Scaffold(
      body: roomAsync.when(
        data: (rooms) {
          return rooms.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: "No Rooms Added Yet",
                    description:
                        "Create your first storage room\nusing the + button below.",
                    actionText:
                        "Tap the floating Add button below\nto insert room.",
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const HeaderSection(
                          title: 'Rooms',
                          message: 'Browse items by location',
                        ),
                      ),

                      const SizedBox(height: 24),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: rooms.length,

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.92,
                            ),

                        itemBuilder: (context, index) {
                          final room = rooms[index];

                          // Count items for this room
                          final roomItemCount = itemsAsync.when(
                            data: (items) {
                              return items
                                  .where((item) => item.roomId == room.id)
                                  .length;
                            },
                            loading: () => 0,
                            error: (_, _) => 0,
                          );

                          final stockCounts = itemsAsync.when(
                            data: (items) {
                              int low = 0;
                              int empty = 0;

                              for (final item in items) {
                                if (item.roomId != room.id) continue;

                                // Skip items that don't track stock
                                if (item.quantity == null &&
                                    item.lowStockLimit == null) {
                                  continue;
                                }

                                switch (item.getStockStatus()) {
                                  case StockStatus.low:
                                    low++;
                                    break;

                                  case StockStatus.empty:
                                    empty++;
                                    break;

                                  case StockStatus.good:
                                    break;
                                }
                              }

                              return (low: low, empty: empty);
                            },
                            loading: () => (low: 0, empty: 0),
                            error: (_, _) => (low: 0, empty: 0),
                          );

                          final lowStockCount = stockCounts.low;
                          final emptyStockCount = stockCounts.empty;

                          return Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: _RoomCard(
                                  title: room.roomName,

                                  itemCount: roomItemCount,

                                  icon: IconData(
                                    int.parse(room.icon),
                                    fontFamily: 'MaterialIcons',
                                  ),

                                  iconColor: Color(room.color),

                                  lowStockCount: lowStockCount,

                                  emptyStockCount: emptyStockCount,

                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.roomItems,
                                      arguments: {'room': room},
                                    );
                                  },
                                ),
                              ),
                              Align(
                                alignment: .topRight,
                                child: PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (builder) {
                                    return [
                                      PopupMenuItem(
                                        onTap: () async {
                                          await showDialog(
                                            context: context,
                                            builder: (context) =>
                                                AddEditRoomDialog(room: room),
                                          );
                                        },
                                        child: Row(
                                          mainAxisSize: .min,
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 10),
                                            Text("Edit"),
                                          ],
                                        ),
                                      ),

                                      PopupMenuItem(
                                        onTap: () async {
                                          Future.microtask(() async {
                                            if (!context.mounted) return;

                                            final shouldDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (context) {
                                                return DeleteRecord(
                                                  title: "Delete Room",
                                                  message:
                                                      "Are you sure you want to delete this room?\n\n"
                                                      "Items in this room will remain in your inventory but will no longer be associated with this room.\n\n"
                                                      "This action cannot be undone.",
                                                );
                                              },
                                            );

                                            if (shouldDelete == true) {
                                              await ref
                                                  .read(roomProvider.notifier)
                                                  .deleteRoom(room);

                                              ref.invalidate(
                                                selectedRoomProvider,
                                              );
                                            }
                                          });
                                        },

                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,

                                          children: [
                                            Icon(Icons.delete),

                                            SizedBox(width: 10),

                                            Text("Delete"),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      if (itemCount == 0)
                        SizedBox(height: 10)
                      else
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Text(
                                'Quick Stats',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _StatCard(
                                label: 'Total Assets',
                                value: "$itemCount",
                                icon: Icons.inventory_2,
                                iconBg: Color(0xFF0056D2),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
        },

        error: (error, stack) => ErrorDisplay(error: error, stack: stack),

        loading: () => const LoadingDisplay(),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AddEditRoomDialog(),
          );
        },

        heroTag: "Room",

        backgroundColor: const Color(0xFF0056D2),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}

// Stateless Widgets
class _RoomCard extends StatelessWidget {
  final String title;
  final int itemCount;
  final IconData icon;
  final Color iconColor;
  final int lowStockCount;
  final int emptyStockCount;
  final VoidCallback onTap;

  const _RoomCard({
    required this.title,
    required this.itemCount,
    required this.icon,

    required this.iconColor,
    required this.onTap,
    required this.lowStockCount,
    required this.emptyStockCount,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBg = iconColor.withValues(alpha: 0.3);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                maxLines: 1,
                overflow: .ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text('$itemCount items', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  if (lowStockCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stockColors[1].withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$lowStockCount LOW',
                        style: TextStyle(
                          color: stockColors[1],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (emptyStockCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stockColors[0].withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$emptyStockCount EMPTY',
                        style: TextStyle(
                          color: stockColors[0],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return CustomInnerShadow(
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
      blur: 3,
      offset: const Offset(0, 3),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
