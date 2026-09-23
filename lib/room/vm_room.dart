import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/r_activity.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/room/r_room.dart';
import 'package:uuid/uuid.dart';

final roomIconIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

final roomColorIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

final roomProvider = AsyncNotifierProvider<RoomNotifier, List<MRoom>>(
  RoomNotifier.new,
);

final roomSearchProvider = StateProvider.autoDispose<String>((ref) => '');

class RoomNotifier extends AsyncNotifier<List<MRoom>> {
  late RoomRepository _repo;

  int totalAssets = 0;

  int get totalRooms => state.value?.length ?? 0;

  @override
  Future<List<MRoom>> build() async {
    _repo = await ref.read(roomRepositoryProvider.future);
    return _repo.getAllRooms();
  }

  // ========================
  // ADD
  // ========================
  Future<void> addRoom(MRoom room) async {
    final now = DateTime.now();

    final result = await _repo.insertRoom(room);

    if (result > 0) {
      final rooms = await _repo.getAllRooms();

      state = AsyncData(rooms);

      // Save activity
      final activityRepo = await ref.read(activityRepositoryProvider.future);

      await activityRepo.insertActivity(
        MActivity(
          id: const Uuid().v4(),

          entityId: room.id,
          entityName: room.roomName,

          entityType: ActivityEntityType.room,
          actionType: ActivityActionType.added,

          createdAt: now,
        ),
      );

      // Refresh activities
      ref.invalidate(activityProvider);
    }
  }

  // ========================
  // UPDATE
  // ========================
  Future<void> updateRoom(MRoom oldRoom, MRoom newRoom) async {
    await _repo.updateRoom(oldRoom: oldRoom, newRoom: newRoom);

    state = AsyncData(await _repo.getAllRooms());

    // Refresh activities
    ref.invalidate(activityProvider);
  }

  // ========================
  // DELETE
  // ========================
  Future<void> deleteRoom(MRoom room) async {
    await _repo.deleteRoom(room);

    final roomsList = await _repo.getAllRooms();

    state = AsyncData(roomsList);

    // Refresh activities
    ref.invalidate(activityProvider);
  }

  // ========================
  // DUPLICATE CHECK
  // ========================
  Future<bool> roomExists(String roomName, MRoom room) async {
    final existingRooms = await _repo.getAllRooms();

    if (existingRooms.isEmpty) return false;

    final alreadyExists = existingRooms.any(
      (e) =>
          e.id != room.id && e.roomName.toLowerCase() == roomName.toLowerCase(),
    );

    return alreadyExists;
  }

  // ========================
  // REFRESH
  // ========================
  Future<void> refresh() async {
    final repo = await ref.read(roomRepositoryProvider.future);

    state = const AsyncLoading();

    state = AsyncData(await repo.getAllRooms());
  }
}
