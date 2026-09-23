import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/theme/theme.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/vm_room.dart';

class RoomBottomSheet extends ConsumerStatefulWidget {
  const RoomBottomSheet({super.key});

  @override
  ConsumerState<RoomBottomSheet> createState() => _RoomBottomSheetState();
}

class _RoomBottomSheetState extends ConsumerState<RoomBottomSheet> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roomAsync = ref.watch(roomProvider);
    final selectedRoomId = ref.watch(selectedRoomProvider).value;

    final itemsAsync = ref.watch(itemProvider);

    final searchQuery = ref.watch(roomSearchProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,

      decoration: AppTheme.bottomSheetDecor(isDark),

      child: Column(
        children: [
          const SizedBox(height: 12),
          // Top Grabber/Handle
          const BSHandle(),

          const SizedBox(height: 20),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                // Header Row
                const BSHeader(
                  title: 'Rooms',
                  subtitle: 'Find items based on where they are stored',
                ),

                const SizedBox(height: 12),

                SearchBarWidget(
                  controller: searchController,
                  hintText: 'Search rooms...',
                  onChanged: (value) =>
                      ref.read(roomSearchProvider.notifier).state = value
                          .trim(),
                  onTextClear: () {
                    searchController.clear();
                    ref.read(roomSearchProvider.notifier).state = "";
                  },
                ),

                const SizedBox(height: 12),

                // Section: Browse by Space
                const Text(
                  'Browse by room',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                // List of rooms
                roomAsync.when(
                  data: (roomsData) {
                    // Extract names
                    final allRooms = roomsData;

                    final filteredRooms = allRooms.where((room) {
                      return room.roomName.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                    }).toList();

                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        itemCount: filteredRooms.length,
                        itemBuilder: (context, index) {
                          final room = filteredRooms[index];

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

                          return CTile(
                            uniqueKey: room.id,

                            isSelected: selectedRoomId == room.id,

                            title: room.roomName,

                            subtitle: '$roomItemCount items',

                            color: room.color,

                            icon: room.icon,

                            onTap: () async {
                              await ref
                                  .read(selectedRoomProvider.notifier)
                                  .setSelectedRoom(room.id);

                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  },

                  loading: () => const LoadingDisplay(),

                  error: (error, stack) =>
                      ErrorDisplay(error: error, stack: stack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
