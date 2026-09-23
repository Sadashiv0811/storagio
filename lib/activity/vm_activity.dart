import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/r_activity.dart';

final activityProvider =
    AsyncNotifierProvider<ActivityNotifier, List<MActivity>>(
      ActivityNotifier.new,
    );

class ActivityNotifier extends AsyncNotifier<List<MActivity>> {
  late ActivityRepository _repo;

  @override
  Future<List<MActivity>> build() async {
    _repo = await ref.read(activityRepositoryProvider.future);
    return _repo.getAllActivities();
  }

  // ========================
  // REFRESH
  // ========================
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.getAllActivities());
  }
}
