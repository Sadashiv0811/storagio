import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/search/search_state.dart';
import 'package:storagio/inventory/search/vm_search.dart';
import 'package:storagio/room/vm_room.dart';

// Providers and List
final roomMapProvider = Provider<Map<String, String>>((ref) {
  final rooms = ref.watch(roomProvider).value ?? [];

  return {for (final room in rooms) room.id: room.roomName};
});

final categoryMapProvider = Provider<Map<String, String>>((ref) {
  final categories = ref.watch(categoryProvider).value ?? [];

  return {
    for (final category in categories) category.id: category.categoryName,
  };
});

// Consumer and ConsumerStateful Widgets
class VSearch extends ConsumerStatefulWidget {
  const VSearch({super.key});

  @override
  ConsumerState<VSearch> createState() => _VSearchState();
}

class _VSearchState extends ConsumerState<VSearch> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemProvider);

    final searchState = ref.watch(searchVmProvider);

    final hasQuery = searchState.query.trim().isNotEmpty;

    final roomMap = ref.watch(roomMapProvider);

    final categoryMap = ref.watch(categoryMapProvider);

    return Scaffold(
      body: SafeArea(
        child: itemAsync.when(
          data: (items) {
            return Column(
              mainAxisSize: .min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: SearchBarWidget(
                          controller: _searchController,
                          hintText: 'Search items...',
                          onChanged: (value) {
                            ref
                                .read(searchVmProvider.notifier)
                                .searchByItemName(
                                  query: value.trim(),
                                  allItems: items,
                                  roomMap: roomMap,
                                  categoryMap: categoryMap,
                                );
                          },
                          onTextClear: () {
                            _searchController.clear();

                            ref.read(searchVmProvider.notifier).clearSearch();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),
                  ],
                ),

                Expanded(
                  child: searchState.isEmptyResult
                      ? const _EmptySearch()
                      : hasQuery
                      ? SearchResultsView(items: searchState.filteredItems)
                      : SearchSuggestionView(
                          onRecentSearchTap: (value) {
                            _searchController.value = TextEditingValue(
                              text: value,
                              selection: TextSelection.collapsed(
                                offset: value.length,
                              ),
                            );

                            ref
                                .read(searchVmProvider.notifier)
                                .searchByItemName(
                                  query: value,
                                  allItems: items,
                                  roomMap: roomMap,
                                  categoryMap: categoryMap,
                                );
                          },
                        ),
                ),
              ],
            );
          },
          error: (error, stack) => ErrorDisplay(error: error, stack: stack),
          loading: () => const LoadingDisplay(),
        ),
      ),
    );
  }
}

class SearchSuggestionView extends ConsumerWidget {
  final Function(String value) onRecentSearchTap;

  const SearchSuggestionView({super.key, required this.onRecentSearchTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(searchSuggestionsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              'SUGGESTIONS',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: suggestions.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final s = suggestions[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _RecentSearchChip(
                    label: s,
                    onTap: () => onRecentSearchTap(s),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResultsView extends ConsumerWidget {
  final List<MItem> items;

  const SearchResultsView({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roomMap = ref.watch(roomMapProvider);

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Results',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    '${items.length} Items Found',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade200 : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
            ],
          );
        }

        final item = items[index - 1];

        return _SearchResultCard(
          title: item.name,

          roomName: roomMap[item.roomId] ?? "Unknown Room",

          item: item,

          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.itemDetails,
              arguments: {'itemId': item.id},
            );
          },
        );
      },
    );
  }
}

// Stateless Widget
class _RecentSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RecentSearchChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 200),
        child: Chip(
          avatar: const Icon(Icons.history, size: 16, color: Colors.blue),
          label: Text(
            label,
            overflow: .ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          side: const BorderSide(color: Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          shadowColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final String title;
  final String roomName;
  final MItem item;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.title,
    required this.roomName,
    required this.onTap,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final double? qty = item.quantity;

    final String? imagePath = item.imagePath;
    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    final String categoryName = item.categoryName;
    final isBills = categoryName == CategoryNames.billsRecharges;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 1),
      child: InkWell(
        onTap: () {
          Future.delayed(Duration(milliseconds: 1000));
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.5),
        child: Ink(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (!isBills) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: file != null
                        ? Image.file(
                            File(file.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : const ImagePlaceHolder(size: 80),
                  ),
                  const SizedBox(width: 15),
                ],

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Category name
                      CategoryNameChip(categoryName: categoryName),
                      const SizedBox(height: 6),

                      if (!isBills)
                        // Room and Quantity
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.blueGrey.shade400,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 100),
                              child: Text(
                                roomName,
                                maxLines: 1,
                                overflow: .ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Spacer(),
                            if (qty != null)
                              CustomInnerShadow(
                                shadowColor: const Color(
                                  0xFFB0C4DE,
                                ).withValues(alpha: 0.5),
                                blur: 5,
                                offset: const Offset(0, 3),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    "Qty: ${formatQuantity(qty)} ${item.unit}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1976D2),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      else
                        // Displays Paid On, Last Payment Amount, Due Date
                        BillsRechargesFields(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: [
        const SizedBox(height: 30),
        // Custom graphic
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? Color.fromARGB(255, 0, 140, 204) : Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Color.fromARGB(255, 0, 140, 204)
                      : Colors.grey.shade300,
                  blurRadius: 3,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 100,
                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade500,
                ),
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off,
                      size: 30,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'No items found',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Try searching with a different name or browse through your categories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade300 : Colors.grey,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 40),
        const _TipCard(
          title: 'TIP',
          subtitle: 'Use broad terms like "Kitchen" or "Tools"',
          icon: Icons.lightbulb,
          iconBgColor: Color(0xFFE0F2F1),
          iconColor: Color(0xFF00897B),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const _TipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
