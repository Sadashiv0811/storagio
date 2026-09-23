import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/user/m_user.dart';
import 'package:storagio/user/r_user.dart';

final userProvider = AsyncNotifierProvider<UserNotifier, MUser?>(
  UserNotifier.new,
);

enum RegisterStatus { login, signup }

class UserNotifier extends AsyncNotifier<MUser?> {
  late UserRepository _repo;

  @override
  Future<MUser?> build() async {
    _repo = await ref.read(userRepositoryProvider.future);
    return _repo.getCurrentUser();
  }

  // ========================
  // LOGIN / SAVE USER
  // ========================
  Future<void> saveUser(MUser user) async {
    await _repo.insertUser(user);
    state = AsyncData(user);
  }

  // ========================
  // UPDATE
  // ========================
  Future<void> updateUser(MUser user) async {
    await _repo.updateUser(user);
    state = AsyncData(user);
  }

  // ========================
  // LOGOUT
  // ========================
  Future<void> logout() async {
    state = const AsyncData(null);
  }

  // ========================
  // REFRESH
  // ========================
  Future<void> refresh() async {
    final repo = await ref.read(userRepositoryProvider.future);

    state = const AsyncLoading();

    state = AsyncData(await repo.getCurrentUser());
  }
}
