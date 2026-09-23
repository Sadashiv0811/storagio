import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:storagio/activity/m_activity.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';

// Extensions and Providers
extension FilterActivityExtension on FilterActivity {
  String get label {
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData get icon {
    switch (this) {
      case FilterActivity.all:
        return Icons.history_rounded;

      case FilterActivity.added:
        return Icons.add_circle;

      case FilterActivity.updated:
        return Icons.edit;

      case FilterActivity.deleted:
        return Icons.delete;
    }
  }
}

extension ActivityDateExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();

    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

extension FilterActivityMapper on FilterActivity {
  ActivityActionType? get actionType {
    switch (this) {
      case FilterActivity.all:
        return null;

      case FilterActivity.added:
        return ActivityActionType.added;

      case FilterActivity.updated:
        return ActivityActionType.updated;

      case FilterActivity.deleted:
        return ActivityActionType.deleted;
    }
  }
}

final selectedFilterProvider = StateProvider<FilterActivity>(
  (ref) => FilterActivity.all,
);

// Consumer and ConsumerStateful Widgets
class VActivity extends ConsumerWidget {
  const VActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityProvider);

    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      body: activityAsync.when(
        data: (activities) {
          // FILTER BY ACTION TYPE
          final filteredActivities = selectedFilter == FilterActivity.all
              ? activities
              : activities.where((activity) {
                  return activity.actionType == selectedFilter.actionType;
                }).toList();

          // TODAY
          final todaysActivities = filteredActivities.where((activity) {
            return activity.createdAt.isToday;
          }).toList();

          // YESTERDAY
          final yesterdayActivities = filteredActivities.where((activity) {
            return activity.createdAt.isYesterday;
          }).toList();

          return ListView(
            physics: ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            children: [
              const HeaderSection(
                title: 'Activity',
                message: 'Recent changes in your inventory',
              ),

              const SizedBox(height: 24),

              // Filters
              FilterSection(),

              const SizedBox(height: 26),

              // If both are empty
              if (todaysActivities.isEmpty && yesterdayActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Center(
                    child: EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'No Activity Yet',
                      description:
                          'Changes to items, rooms, and categories will appear here.',
                    ),
                  ),
                ),

              // "Today" Section
              if (todaysActivities.isNotEmpty) ...[
                TodaysActivity(activities: todaysActivities),
                Divider(height: 10, thickness: 1.5),
              ],

              if (yesterdayActivities.isNotEmpty) ...[
                YesterdayActivity(activities: yesterdayActivities),
                Divider(height: 10, thickness: 1.5),
              ],

              if (activities.isNotEmpty)
                CustomDateActivity(activities: filteredActivities),
            ],
          );
        },

        loading: () => const LoadingDisplay(),

        error: (error, stack) => ErrorDisplay(error: error, stack: stack),
      ),
    );
  }
}

class FilterSection extends ConsumerWidget {
  const FilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedFilterProvider);

    final filters = FilterActivity.values.toList();

    // Move selected filter to first position
    filters.remove(selectedFilter);
    filters.insert(0, selectedFilter);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _FilterPill(
              label: filter.label,
              icon: filter.icon,
              isActive: isSelected,
              callBack: () {
                ref.read(selectedFilterProvider.notifier).state = filter;
                logger.d("Selected filter: ${filter.name}");
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CustomDateActivity extends ConsumerStatefulWidget {
  final List<MActivity> activities;

  const CustomDateActivity({super.key, required this.activities});

  @override
  ConsumerState<CustomDateActivity> createState() => _CustomDateActivityState();
}

class _CustomDateActivityState extends ConsumerState<CustomDateActivity>
    with AutomaticKeepAliveClientMixin {
  bool isExpanded = false;
  DateTime? selectedDate;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final activitiesForDate = selectedDate == null
        ? <MActivity>[]
        : widget.activities.where((activity) {
            final d = activity.createdAt;

            return d.year == selectedDate!.year &&
                d.month == selectedDate!.month &&
                d.day == selectedDate!.day;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: _SectionRow(title: 'Search by Date', isExpanded: isExpanded),
        ),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,

          firstChild: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Date',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              selectedDate == null
                                  ? 'Tap to choose a date'
                                  : DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate!),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (selectedDate == null)
                const EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'No Date Selected',
                  description: 'Choose a date to view activities.',
                ),

              if (selectedDate != null && activitiesForDate.isEmpty)
                const EmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'No Activities Found',
                  description: 'There are no activities for the selected date.',
                ),

              if (activitiesForDate.isNotEmpty)
                ...List.generate(activitiesForDate.length, (index) {
                  final activity = activitiesForDate[index];

                  return ActivityCard(
                    activity: activity,
                    showLine: index != activitiesForDate.length - 1,
                  );
                }),
            ],
          ),

          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// Stateful Widgets
class TodaysActivity extends StatefulWidget {
  final List<MActivity> activities;

  const TodaysActivity({super.key, required this.activities});

  @override
  State<TodaysActivity> createState() => _TodaysActivityState();
}

class _TodaysActivityState extends State<TodaysActivity>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool isTodayExpanded = true;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1,
    );
  }

  void toggle() {
    setState(() {
      isTodayExpanded = !isTodayExpanded;

      if (isTodayExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: .start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: toggle,
          child: _SectionRow(title: 'Todays', isExpanded: isTodayExpanded),
        ),

        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizeTransition(
              sizeFactor: _controller,
              axis: Axis.vertical,
              axisAlignment: -1,
              child: Column(
                children: widget.activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;

                  return ActivityCard(
                    activity: activity,
                    showLine: index != widget.activities.length - 1,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class YesterdayActivity extends StatefulWidget {
  final List<MActivity> activities;

  const YesterdayActivity({super.key, required this.activities});

  @override
  State<YesterdayActivity> createState() => _YesterdayActivityState();
}

class _YesterdayActivityState extends State<YesterdayActivity>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;

  bool isYesterdayExpanded = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1,
    );
  }

  void toggle() {
    setState(() {
      isYesterdayExpanded = !isYesterdayExpanded;

      if (isYesterdayExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: .start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: toggle,
          child: _SectionRow(
            title: 'Yesterdays',
            isExpanded: isYesterdayExpanded,
          ),
        ),

        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizeTransition(
              sizeFactor: _controller,
              axis: Axis.vertical,
              axisAlignment: -1,
              child: Column(
                children: widget.activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;

                  return ActivityCard(
                    activity: activity,
                    showLine: index != widget.activities.length - 1,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Stateless Widgets
class _ChangeDetailsBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ChangeDetailsBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomInnerShadow(
      shadowColor: const Color(0xFFB0C4DE).withValues(alpha: 0.5),
      blur: 3,
      offset: const Offset(0, 3),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final MActivity activity;
  final bool showLine;
  final bool isDT;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.showLine,
    this.isDT = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late IconData icon;
    late Color iconColor;
    late Color bgColor;
    late Color titleColor;

    switch (activity.actionType) {
      case ActivityActionType.added:
        icon = Icons.add;
        iconColor = const Color(0xFF059669);
        bgColor = const Color(0xFFD1FAE5);
        titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        break;

      case ActivityActionType.updated:
        icon = Icons.edit;
        iconColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFDBEAFE);
        titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        break;

      case ActivityActionType.deleted:
        icon = Icons.delete_outline;
        iconColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        titleColor = const Color(0xFFDC2626);
        break;
    }

    return _ActivityTimelineItem(
      icon: Icon(icon, color: iconColor, size: 20),

      iconBgColor: bgColor,

      activity: activity,

      titleColor: titleColor,

      showLine: showLine,

      isDT: isDT,

      details: _buildDetails(),
    );
  }

  Widget? _buildDetails() {
    // Generic field update
    if (activity.fieldName != null) {
      String value = '${activity.oldValue} → ${activity.newValue}';

      if (activity.fieldName == "purchase date" ||
          activity.fieldName == "warranty/expiry date") {
        String formatDate(String? value) {
          if (value == null || value.trim().isEmpty) return '-';

          final date = DateTime.tryParse(value);
          if (date == null) return value;

          return DateFormat('dd MMM yyyy').format(date);
        }

        final String oldValue = formatDate(activity.oldValue);
        final String newValue = formatDate(activity.newValue);

        value = '$oldValue → $newValue';
      }

      return _ChangeDetailsBox(
        label: activity.fieldName!,
        value: value,
        valueColor: const Color(0xFF0F172A),
      );
    }

    return null;
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final Widget icon;
  final Color iconBgColor;
  final Color titleColor;
  final Widget? details;
  final bool showLine;
  final bool isDT;
  final MActivity activity;

  const _ActivityTimelineItem({
    required this.icon,
    required this.iconBgColor,
    required this.titleColor,
    required this.isDT,
    required this.activity,
    this.details,
    this.showLine = true,
  });

  String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }

    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Icon and Continuous Timeline Line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: icon),
              ),
              if (showLine)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFDBEAFE)),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
          const SizedBox(width: 16),
          // Right side: Content Card
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.actionType.name.toUpperCase()}  ${activity.entityName}',
                  maxLines: 2,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),

                if (isDT) ...[
                  Text(
                    DateFormat(
                      'dd MMM yyyy hh:mm a',
                    ).format(activity.createdAt),
                    style: TextStyle(fontSize: 14),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          overflow: .ellipsis,
                          maxLines: 1,
                          '${activity.entityType.name.toUpperCase()}: ${activity.entityName}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 20),
                      Text(
                        ' • ${timeAgo(activity.createdAt)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],

                if (details != null) ...[const SizedBox(height: 12), details!],
                const SizedBox(height: 20), 
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback callBack;

  const _FilterPill({
    required this.label,
    required this.icon,
    this.isActive = false,
    required this.callBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? const Color(0xFF006ADC)
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 3,
        shadowColor: Colors.grey.shade100,
      ),
      onPressed: callBack,
      icon: Icon(
        icon,
        size: 16,
        color: isActive ? Colors.white : Colors.blueGrey.shade300,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isActive
              ? Colors.white
              : isDark
              ? Color(0xFFF1F5F9)
              : Color.fromARGB(255, 60, 60, 60),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final bool isExpanded;
  const _SectionRow({required this.title, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: isExpanded ? 0.5 : 0,
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 25),
          ),
        ],
      ),
    );
  }
}
