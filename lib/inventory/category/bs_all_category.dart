import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/theme/theme.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';

class CategoriesBottomSheet extends ConsumerStatefulWidget {
  const CategoriesBottomSheet({super.key});

  @override
  ConsumerState<CategoriesBottomSheet> createState() =>
      _CategoriesBottomSheetState();
}

class _CategoriesBottomSheetState extends ConsumerState<CategoriesBottomSheet> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryAsync = ref.watch(categoryProvider);
    final selectedCategoryName = ref.watch(selectedCategoryProvider).value;

    final itemsAsync = ref.watch(itemProvider);

    final searchQuery = ref.watch(categorySearchProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: AppTheme.bottomSheetDecor(isDark),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Top Grabber/Handle
          const BSHandle(),

          const SizedBox(height: 20),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                // Header Row
                const BSHeader(
                  title: 'Categories',
                  subtitle: 'Find items based on their category',
                ),

                const SizedBox(height: 12),

                SearchBarWidget(
                  controller: searchController,
                  hintText: 'Search categories...',
                  onChanged: (value) =>
                      ref.read(categorySearchProvider.notifier).state = value
                          .trim(),
                  onTextClear: () {
                    searchController.clear();
                    ref.read(categorySearchProvider.notifier).state = "";
                  },
                ),

                const SizedBox(height: 12),

                // Section: Browse by category
                const Text(
                  'Browse by Category',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                // List of categories
                categoryAsync.when(
                  data: (categoriesData) {
                    // Extract names
                    final allCategories = categoriesData;

                    final filteredCategory = allCategories.where((c) {
                      return c.categoryName.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                    }).toList();

                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        itemCount: filteredCategory.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategory[index];

                          // Count items for this category
                          final categoryItemCount = itemsAsync.when(
                            data: (items) {
                              return items
                                  .where(
                                    (item) =>
                                        item.categoryName ==
                                        category.categoryName,
                                  )
                                  .length;
                            },
                            loading: () => 0,
                            error: (_, _) => 0,
                          );

                          return CTile(
                            uniqueKey: category.id,

                            isSelected:
                                selectedCategoryName == category.categoryName,

                            title: category.categoryName,

                            subtitle: '$categoryItemCount items',

                            color: category.color,

                            icon: category.icon,

                            onTap: () async {
                              await ref
                                  .read(selectedCategoryProvider.notifier)
                                  .setSelectedCategory(category.categoryName);

                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  },

                  loading: () => const LoadingDisplay(),

                  error: (error, stack) =>
                      ErrorDisplay(error: error, stack: stack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
