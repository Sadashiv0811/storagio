import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/inventory/item/m_item.dart';

import 'search_state.dart';

final searchVmProvider = NotifierProvider.autoDispose<SearchVm, SearchState>(
  SearchVm.new,
);

class SearchVm extends Notifier<SearchState> {
  @override
  SearchState build() {
    return const SearchState();
  }

  void searchByItemName({
    required String query,
    required List<MItem> allItems,
    required Map<String, String> roomMap,
    required Map<String, String> categoryMap,
  }) {
    final trimmedQuery = query.trim().toLowerCase();

    if (trimmedQuery.isEmpty) {
      state = state.copyWith(query: query, filteredItems: const []);

      return;
    }

    List<MItem> filtered = allItems.where((item) {
      final itemName = item.name.toLowerCase();

      final roomName = (roomMap[item.roomId] ?? '').toLowerCase();

      final categoryName = item.categoryName.trim().toLowerCase();

      final matched =
          itemName.contains(trimmedQuery) ||
          roomName.contains(trimmedQuery) ||
          categoryName.contains(trimmedQuery);

      return matched;
    }).toList();

    state = state.copyWith(query: query, filteredItems: filtered);
  }

  void clearSearch() {
    state = const SearchState();
  }
}
