import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/settings/dialogs/default_setup/p_default_c_r.dart';
import 'package:storagio/settings/dialogs/default_setup/vm_default_c_r.dart';

// ConsumerStateful and Consumer Widgets
class DefaultCategoryRoomDialog extends ConsumerStatefulWidget {
  final bool isCategory;

  const DefaultCategoryRoomDialog({super.key, required this.isCategory});

  @override
  ConsumerState<DefaultCategoryRoomDialog> createState() =>
      _DefaultCategoryLocationDialogState();
}

class _DefaultCategoryLocationDialogState
    extends ConsumerState<DefaultCategoryRoomDialog> {
  @override
  void initState() {
    super.initState();

    // Automatically select the default when the dialog is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(
        defaultCategoryRoomDialogVMProvider(widget.isCategory),
      );

      // Grab the current global default
      final currentDefault = widget.isCategory
          ? ref.read(defaultCategoryProvider)
          : ref.read(defaultRoomProvider);

      // Initialize the ViewModel with this default
      if (currentDefault != null) {
        vm.selectObject(currentDefault);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(
      defaultCategoryRoomDialogVMProvider(widget.isCategory),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),

      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.65,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogHeader(
                title: widget.isCategory
                    ? 'Set Default Category'
                    : 'Set Default Room',
              ),

              const SizedBox(height: 15),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SearchBarWidget(
                  controller: vm.searchController,
                  hintText: widget.isCategory
                      ? 'Search Categories'
                      : 'Search Rooms',
                  onChanged: vm.onSearchChanged,
                  onTextClear: () {
                    vm.searchController.clear();
                    vm.onSearchChanged("");
                  },
                ),
              ),

              const SizedBox(height: 15),

              ObjectsList(isCategory: widget.isCategory),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: CCancelButton()),

                    const SizedBox(width: 10),

                    Expanded(
                      child: CPositiveButton(
                        text: 'Apply',

                        callback: vm.isLoading
                            ? () {}
                            : () => vm.apply(context),

                        iconData: Icons.approval,
                      ),
                    ),
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

class ObjectsList extends ConsumerWidget {
  final bool isCategory;

  const ObjectsList({super.key, required this.isCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(defaultCategoryRoomDialogVMProvider(isCategory));

    final String? selected =
        vm.selectedValue ??
        (isCategory
            ? ref.watch(defaultCategoryProvider)
            : ref.watch(defaultRoomProvider));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vm.filteredObjects.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final obj = vm.filteredObjects[index];

          final isSelected = isCategory
              ? selected == obj.categoryName
              : selected == obj.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Object(
              title: isCategory ? obj.categoryName : obj.roomName,

              isSelected: isSelected,

              onItemSelected: () {
                isCategory
                    ? vm.selectObject(obj.categoryName)
                    : vm.selectObject(obj.id);
              },

              icon: IconData(int.parse(obj.icon), fontFamily: 'MaterialIcons'),
            ),
          );
        },
      ),
    );
  }
}

// Stateless Widgets
class _Object extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onItemSelected;
  
  const _Object({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shadowColor: isSelected ? null : Theme.of(context).colorScheme.shadow,
      elevation: isSelected ? 0 : 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.5),
        onTap: onItemSelected,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected && isDark ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
