import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/inventory/category/r_category.dart';
import 'package:storagio/room/r_room.dart';

final defaultCategoryProvider =
    StateNotifierProvider<DefaultCategoryNotifier, String?>((ref) {
      return DefaultCategoryNotifier(ref);
    });

class DefaultCategoryNotifier extends StateNotifier<String?> {
  final Ref ref;

  DefaultCategoryNotifier(this.ref) : super(null) {
    init();
  }

  Future<void> init() async {
    // Get name from shared preference
    final categoryName = await getDefaultCategoryNameFromSP(defaultCategoryKey);

    if (categoryName != null && categoryName.isNotEmpty) {
      state = categoryName;
      return;
    }

    // If shared preference is empty or null then fetch the first category
    final repo = await ref.read(categoryRepositoryProvider.future);
    final firstCategory = await repo.getFirstCategory();

    if (firstCategory == null) return;

    final firstCategoryName = firstCategory.categoryName;

    // Save locally
    state = firstCategoryName;

    await saveDefaultCategoryNameInSP(defaultCategoryKey, firstCategoryName);
  }

  Future<void> setDefaultCategory(String categoryName) async {
    if (state == categoryName) return;

    state = categoryName;

    await saveDefaultCategoryNameInSP(
      defaultCategoryKey,
      categoryName,
    ); // Saving id in shared preference
    return;
  }

  Future<String?> getDefaultCategoryNameFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultCategoryName = prefs.getString(key);
    return defaultCategoryName;
  }

  Future<void> saveDefaultCategoryNameInSP(
    String key,
    String categoryName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, categoryName);
  }
}

final defaultRoomProvider = StateNotifierProvider<DefaultRoomNotifier, String?>(
  (ref) {
    return DefaultRoomNotifier(ref);
  },
);

class DefaultRoomNotifier extends StateNotifier<String?> {
  final Ref ref;

  DefaultRoomNotifier(this.ref) : super(null) {
    init();
  }

  Future<void> init() async {
    // Get id from shared preference
    final localId = await getDefaultRoomIdFromSP(defaultRoomKey);

    if (localId != null && localId.isNotEmpty) {
      state = localId;
      return;
    }

    try {
      // If shared preference is empty or null then fetch the first room
      final repo = await ref.read(roomRepositoryProvider.future);
      final firstRoom = await repo.getFirstRoom();

      if (firstRoom == null) return;

      final firstRoomId = firstRoom.id;

      // Save locally
      state = firstRoomId;

      await saveDefaultRoomIdInSP(defaultRoomKey, firstRoomId);
    } catch (e) {
      // Handle potential DB initialization errors gently
      logger.d("Error initializing default room: $e");
    }
  }

  Future<void> setDefaultRoom(String id) async {
    if (state == id) return;

    state = id;

    // Saving id in shared preference
    await saveDefaultRoomIdInSP(defaultRoomKey, id);
  }

  Future<String?> getDefaultRoomIdFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString(key);
    return defaultId;
  }

  Future<void> saveDefaultRoomIdInSP(String key, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, id);
  }
}
