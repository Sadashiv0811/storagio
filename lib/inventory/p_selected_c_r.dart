import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/inventory/category/r_category.dart';
import 'package:storagio/room/r_room.dart';
import 'package:storagio/settings/dialogs/default_setup/p_default_c_r.dart';

final selectedCategoryProvider =
    AsyncNotifierProvider<SelectedCategoryNotifier, String?>(() {
      return SelectedCategoryNotifier();
    });

class SelectedCategoryNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    // Correctly watch the default provider.
    // Whenever defaultCategoryProvider changes, this build method re-runs.
    final defaultCategoryName = ref.watch(defaultCategoryProvider);

    if (defaultCategoryName != null) {
      return defaultCategoryName;
    }

    // Fetch from repository if no default is found
    final repo = await ref.read(categoryRepositoryProvider.future);
    final categories = await repo.getAllCategories();

    if (categories.isEmpty) return null;
    return categories.first.categoryName;
  }

  Future<void> setSelectedCategory(String categoryName) async {
    // Prevent unnecessary state updates
    if (state.value == categoryName) return;

    // Manually override the state
    state = AsyncData(categoryName);
  }
}

final selectedRoomProvider =
    AsyncNotifierProvider<SelectedRoomNotifier, String?>(() {
      return SelectedRoomNotifier();
    });

class SelectedRoomNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final defaultRoomId = ref.watch(defaultRoomProvider);

    if (defaultRoomId != null) {
      return defaultRoomId;
    }

    final repo = await ref.read(roomRepositoryProvider.future);
    final rooms = await repo.getAllRooms();

    if (rooms.isEmpty) return null;
    return rooms.first.id;
  }

  Future<void> setSelectedRoom(String id) async {
    if (state.value == id) return;
    state = AsyncData(id);
  }
}
