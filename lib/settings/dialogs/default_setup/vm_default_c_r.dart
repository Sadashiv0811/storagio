import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/inventory/category/r_category.dart';
import 'package:storagio/room/r_room.dart';
import 'package:storagio/settings/dialogs/default_setup/p_default_c_r.dart';

final defaultCategoryRoomDialogVMProvider = ChangeNotifierProvider.autoDispose
    .family<DefaultCategoryRoomDialogVM, bool>((ref, isCategory) {
      final vm = DefaultCategoryRoomDialogVM(ref: ref, isCategory: isCategory);

      vm.init();

      return vm;
    });

class DefaultCategoryRoomDialogVM extends ChangeNotifier {
  final Ref ref;
  final bool isCategory;

  DefaultCategoryRoomDialogVM({required this.ref, required this.isCategory});

  // ---------------------------- CONTROLLERS ----------------------------

  final TextEditingController searchController = TextEditingController();

  // ---------------------------- STATE ----------------------------

  String searchQuery = '';

  bool isLoading = false;

  // Local state to hold the selection until "Apply" is pressed
  String? selectedValue;

  // Store actual models
  List<dynamic> allObjects = [];

  List<dynamic> filteredObjects = [];

  // ---------------------------- INIT ----------------------------

  Future<void> init() async {
    // Initialize the local selection with the current global default
    if (isCategory) {
      selectedValue = ref.read(defaultCategoryProvider);
    } else {
      selectedValue = ref.read(defaultRoomProvider);
    }

    await loadData();
  }

  // ---------------------------- LOAD DATA ----------------------------

  Future<void> loadData() async {
    if (isCategory) {
      final categoryRepo = await ref.read(categoryRepositoryProvider.future);

      allObjects = await categoryRepo.getAllCategories();
    } else {
      final roomRepo = await ref.read(roomRepositoryProvider.future);

      allObjects = await roomRepo.getAllRooms();
    }

    filteredObjects = List.from(allObjects);

    notifyListeners();
  }

  // ---------------------------- SEARCH ----------------------------

  void onSearchChanged(String value) {
    searchQuery = value.trim();

    if (value.trim().isEmpty) {
      filteredObjects = List.from(allObjects);
    } else {
      filteredObjects = allObjects.where((item) {
        final name = isCategory ? item.categoryName : item.roomName;

        return name.toLowerCase().contains(value.toLowerCase());
      }).toList();
    }

    notifyListeners();
  }

  // ---------------------------- SELECT OBJECT ----------------------------
  // Object might be room or category
  Future<void> selectObject(String value) async {
    // Only update the local temporary state, not the global provider
    selectedValue = value;
    notifyListeners();
  }

  // ---------------------------- APPLY ----------------------------

  Future<void> apply(BuildContext context) async {
    if (selectedValue == null) {
      Navigator.pop(context);
      return;
    }

    isLoading = true;
    notifyListeners();

    if (isCategory) {
      await ref
          .read(defaultCategoryProvider.notifier)
          .setDefaultCategory(selectedValue!);
    } else {
      await ref
          .read(defaultRoomProvider.notifier)
          .setDefaultRoom(selectedValue!);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    isLoading = false;
    notifyListeners();

    if (!context.mounted) return;

    Navigator.pop(context);
  }

  // ---------------------------- DISPOSE ----------------------------

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
