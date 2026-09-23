import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/core/utils/input_validators.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/room/vm_room.dart';
import 'package:uuid/uuid.dart';

// Consumer and ConsumerStateful Widgets
class AddEditRoomDialog extends ConsumerStatefulWidget {
  final MRoom? room;

  const AddEditRoomDialog({super.key, this.room});

  bool get isEdit => room != null;

  @override
  ConsumerState<AddEditRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends ConsumerState<AddEditRoomDialog> {
  final addRoomFK = GlobalKey<FormState>();

  late final TextEditingController roomController;

  bool duplicateError = false;

  @override
  void initState() {
    super.initState();

    roomController = TextEditingController(text: widget.room?.roomName ?? "");

    if (widget.isEdit) {
      final iconIndex = iconsListRoom.indexWhere(
        (e) => e.codePoint.toString() == widget.room!.icon,
      );

      final colorIndex = colorsList.indexWhere(
        (e) => e.toARGB32() == widget.room!.color,
      );

      Future.microtask(() {
        ref.read(roomIconIndexProvider.notifier).state = iconIndex == -1
            ? 0
            : iconIndex;

        ref.read(roomColorIndexProvider.notifier).state = colorIndex == -1
            ? 0
            : colorIndex;
      });
    }
  }

  @override
  void dispose() {
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: SingleChildScrollView(
          child: Form(
            key: addRoomFK,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: .center,
                    child: DialogHeader(
                      title: widget.isEdit ? 'Edit Room' : 'New Room',
                      message: widget.isEdit
                          ? 'Update room details.'
                          : 'Enter name and pick an icon, color for your storage space.',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const CLabel(text: 'ROOM NAME'),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CTextFormField(
                    controller: roomController,
                    hint: 'e.g., Attic, Basement',
                    validator: (value) =>
                        AppValidators.otherNames(value, "Room Name"),
                  ),
                ),

                const SizedBox(height: 20),

                IconSelector(
                  provider: roomIconIndexProvider,
                  icons: iconsListRoom,
                ),

                ColorSelector(
                  provider: roomColorIndexProvider,
                  colors: colorsList,
                ),

                Visibility(
                  visible: duplicateError,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Room with this name already exists",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Expanded(child: CCancelButton()),

                      const SizedBox(width: 5),

                      Expanded(
                        child: CPositiveButton(
                          text: widget.isEdit ? "Update" : "Save",
                          iconData: widget.isEdit ? Icons.edit : Icons.save,
                          callback: () async {
                            setState(() {
                              duplicateError = false;
                            });

                            if (!(addRoomFK.currentState?.validate() ??
                                false)) {
                              return;
                            }

                            final roomName = roomController.text.trim();

                            final iconIndex = ref.read(roomIconIndexProvider);

                            final colorIndex = ref.read(roomColorIndexProvider);

                            final selectedIcon = iconsListRoom[iconIndex];

                            final selectedColor = colorsList[colorIndex];

                            // Only user editable fields are changed.
                            // Rest fields remain same, since their creation.
                            final updatedRoom = MRoom(
                              localId: widget.room?.localId,

                              id: widget.room?.id ?? const Uuid().v4(),

                              roomName: roomController.text.trim(),

                              icon: selectedIcon.codePoint.toString(),

                              color: selectedColor.toARGB32(),

                              synced: false,
                            );

                            final notifier = ref.read(roomProvider.notifier);

                            // Duplicate validation
                            final alreadyExists = await notifier.roomExists(
                              roomName,
                              updatedRoom,
                            );

                            if (alreadyExists) {
                              setState(() {
                                duplicateError = true;
                              });
                              return;
                            }

                            if (widget.isEdit) {
                              await notifier.updateRoom(
                                widget.room as MRoom,
                                updatedRoom,
                              );
                            } else {
                              await notifier.addRoom(updatedRoom);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);

                              showSnackBar(
                                widget.isEdit
                                    ? "Room updated successfully"
                                    : "Room added successfully",
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IconSelector extends ConsumerWidget {
  final StateProvider<int> provider;
  final List<IconData> icons;

  const IconSelector({super.key, required this.provider, required this.icons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(provider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CLabel(text: 'SELECT ICON'),

          CExpandableGrid(
            itemCount: icons.length,

            selectedIndex: selectedIndex,

            provider: provider,

            itemBuilder: (context, index, isSelected, ref) {
              return IconButton(
                onPressed: () {
                  ref.read(provider.notifier).state = index;
                },

                style: IconButton.styleFrom(
                  elevation: 5,
                  shadowColor: Theme.of(context).colorScheme.shadow,

                  backgroundColor: isSelected
                      ? const Color(0xFF005FB0)
                      : Theme.of(context).colorScheme.surface,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                icon: Icon(icons[index]),

                color: isSelected ? Colors.white : Colors.grey.shade500,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ColorSelector extends ConsumerWidget {
  final StateProvider<int> provider;
  final List<Color> colors;

  const ColorSelector({
    super.key,
    required this.provider,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(provider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CLabel(text: 'THEME COLOR'),

          CExpandableGrid(
            itemCount: colors.length,

            selectedIndex: selectedIndex,

            provider: provider,

            itemBuilder: (context, index, isSelected, ref) {
              return InkWell(
                borderRadius: BorderRadius.circular(13),

                onTap: () {
                  ref.read(provider.notifier).state = index;
                },

                child: Container(
                  width: 33,
                  height: 33,

                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,

                    border: isSelected
                        ? Border.all(color: const Color(0xFF005FB0), width: 2)
                        : null,
                  ),

                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Stateful Widgets
class CExpandableGrid extends StatefulWidget {
  const CExpandableGrid({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.provider,
    required this.itemBuilder,
  });

  final int itemCount;
  final int selectedIndex;
  final StateProvider<int> provider;

  final Widget Function(
    BuildContext context,
    int index,
    bool isSelected,
    WidgetRef ref,
  )
  itemBuilder;

  @override
  State<CExpandableGrid> createState() => _CExpandableGridState();
}

class _CExpandableGridState extends State<CExpandableGrid> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = isExpanded
        ? widget.itemCount
        : widget.itemCount > 10
        ? 10
        : widget.itemCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: .start,
      children: [
        GridView.builder(
          shrinkWrap: true,
        
          physics: const NeverScrollableScrollPhysics(),
        
          itemCount: visibleCount,
        
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 6,
            mainAxisSpacing: 12,
          ),
        
          itemBuilder: (context, index) {
            final isSelected = index == widget.selectedIndex;
        
            return Consumer(
              builder: (context, ref, child) {
                return widget.itemBuilder(context, index, isSelected, ref);
              },
            );
          },
        ),
        SizedBox(height: 20),
        if (widget.itemCount > 10) ...[
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },

              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: isDark
                    ? Colors.lightBlueAccent
                    : const Color.fromARGB(255, 0, 60, 255),
              ),

              label: Text(
                isExpanded ? "Show Less" : "Show More",
                style: TextStyle(
                  color: isDark
                      ? Colors.lightBlueAccent
                      : const Color.fromARGB(255, 0, 60, 255),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
