import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/room/vm_room.dart';

class SearchState {
  final String query;
  final List<MItem> filteredItems;

  const SearchState({this.query = '', this.filteredItems = const []});

  bool get isEmptyResult => query.isNotEmpty && filteredItems.isEmpty;

  SearchState copyWith({String? query, List<MItem>? filteredItems}) {
    return SearchState(
      query: query ?? this.query,
      filteredItems: filteredItems ?? this.filteredItems,
    );
  }
}

final searchSuggestionsProvider = Provider<List<String>>((ref) {
  final items = ref.watch(itemProvider).value ?? [];

  final rooms = ref.watch(roomProvider).value ?? [];

  final categories = ref.watch(categoryProvider).value ?? [];

  final suggestions = <String>[
    ...items.map((e) => e.name),
    ...rooms.map((e) => e.roomName),
    ...categories.map((e) => e.categoryName),
  ];

  final unique = suggestions.toSet().toList();

  unique.shuffle(Random());

  return unique.take(8).toList();
});
