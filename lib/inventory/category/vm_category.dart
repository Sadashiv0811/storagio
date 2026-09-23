import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/inventory/category/m_category.dart';
import 'package:storagio/inventory/category/r_category.dart';

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<MCategory>>(
      CategoryNotifier.new,
    );

// Category
final categorySearchProvider = StateProvider.autoDispose<String>((ref) => '');

class CategoryNotifier extends AsyncNotifier<List<MCategory>> {
  late CategoryRepository _repo;

  @override
  Future<List<MCategory>> build() async {
    _repo = await ref.read(categoryRepositoryProvider.future);
    return _repo.getAllCategories();
  }

  // ========================
  // ADD
  // ========================
  Future<void> addCategory(MCategory category) async {
    await _repo.insertCategory(category);

    state = AsyncData(await _repo.getAllCategories());
  }

  // ========================
  // REFRESH
  // ========================
  Future<void> refresh() async {
    final repo = await ref.read(categoryRepositoryProvider.future);

    state = const AsyncLoading();

    state = AsyncData(await repo.getAllCategories());
  }
}
