import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:storagio/core/theme/theme.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/custom_reminder/m_custom_reminder.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/custom_reminder/vm_custom_reminder.dart';

class VCustomReminder extends ConsumerStatefulWidget {
  final MItem item;
  final CustomReminder? reminder;
  const VCustomReminder({super.key, required this.item, this.reminder});

  @override
  ConsumerState<VCustomReminder> createState() => _VCustomReminderState();
}

class _VCustomReminderState extends ConsumerState<VCustomReminder> {
  @override
  void initState() {
    super.initState();

    // Schedule initialization right after the widget is laid out safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(customReminderVMProvider);

      if (widget.reminder != null) {
        // If an existing reminder is passed, seed the form data
        vm.setReminderForEdit(widget.reminder!);
      } else {
        // Otherwise, make sure we clean up old states for a new record
        vm.resetForm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(customReminderVMProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: appBarText('${widget.item.name} Reminder')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: vm.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Text('Reminder Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              // Text Content Input
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(18),
                shadowColor: Theme.of(context).colorScheme.shadow,
                child: TextFormField(
                  controller: vm.contentController,
                  maxLines: 3,
                  focusNode: vm.contentFN,
                  keyboardType: TextInputType.text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  cursorColor: isDark ? Colors.lightBlueAccent : Colors.black,
                  decoration: AppTheme.inputDecoration(
                    hint: 'What do you want to be reminded about?',
                  ),

                  validator: (value) => value == null || value.isEmpty
                      ? 'Content cannot be empty'
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Date and Time Picker
              InkWell(
                onTap: () => vm.pickDateTime(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.primary.withValues(alpha: 0.6)
                        : theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.lightBlue.withValues(alpha: 0.7)
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: isDark
                            ? Colors.lightBlueAccent
                            : theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule Date & Time',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.lightBlueAccent
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vm.selectedDateTime == null
                                  ? 'Tap to select...'
                                  : DateFormat(
                                      'dd-MM-yyyy, hh:mm a',
                                    ).format(vm.selectedDateTime!),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark
                            ? Colors.lightBlueAccent
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Checkbox for repeating reminder
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Repeat constantly',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: vm.repeatReminder,
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                      activeTrackColor: Theme.of(context).colorScheme.surface,
                      trackOutlineColor: WidgetStateProperty.all(
                        isDark
                            ? vm.repeatReminder
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.white
                            : vm.repeatReminder
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.black,
                      ),
                      onChanged: (bool value) => vm.setRepeatReminder(value),
                    ),
                  ],
                ),
              ),

              // Conditional Number Input for Days
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: vm.repeatReminder
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          children: [
                            CLabel(text: "Repeat Interval"),
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(18),
                              shadowColor: Theme.of(context).colorScheme.shadow,
                              child: TextFormField(
                                controller: vm.daysController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                cursorColor: isDark
                                    ? Colors.lightBlueAccent
                                    : Colors.black,
                                decoration: AppTheme.inputDecoration(
                                  hint: 'Repeat interval (in days)',
                                  prefixIcon: Icon(Icons.av_timer_rounded),
                                  alignLabelWithHint: false,
                                ),
                                validator: (value) {
                                  if (vm.repeatReminder &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please specify repeat interval';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CPositiveButton(
                  callback: () => vm.saveReminder(
                    itemId: widget.item.id,
                    itemName: widget.item.name,
                    onError: (message) {
                      showSnackBar(message, backgroundColor: Colors.red);
                    },
                    onSuccess: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  iconData: Icons.notifications,
                  text: widget.reminder != null
                      ? "Edit Reminder"
                      : 'Add Reminder',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  final String title;
  final CustomReminder reminder;
  final VoidCallback deleteReminder;
  final VoidCallback editReminder;
  final VoidCallback enableReminder;
  final VoidCallback disableReminder;

  const ReminderCard({
    super.key,
    required this.title,
    required this.deleteReminder,
    required this.editReminder,
    required this.reminder,
    required this.enableReminder,
    required this.disableReminder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateTime dateTime = reminder.startDate;
    final String content = reminder.content;
    final bool active = reminder.isActive;
    final bool isRepeat = reminder.intervalDays != 0;
    final int days = reminder.intervalDays;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
            ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
            : BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary,
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Bar (dynamically matches your primary brand color)
              Container(width: 6, color: theme.colorScheme.primary),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reminder Title and Status(Active) card
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              "$title Reminder",
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 5),
                          _buildStatusChip(context, active),
                        ],
                      ),

                      // Content
                      Text(content, style: theme.textTheme.titleSmall),

                      // Date & Time Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Date Block
                            Expanded(
                              child: _buildDateTimeBlock(
                                context,
                                icon: Icons.calendar_today_rounded,
                                label: isRepeat ? 'SET ON' : 'DATE',
                                value: DateFormat(
                                  'dd MMM yyyy',
                                ).format(dateTime),
                              ),
                            ),

                            // Vertical Divider matching theme thickness
                            Container(
                              height: 28,
                              width: theme.dividerTheme.thickness ?? 0.6,
                              color: theme.dividerTheme.color,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),

                            // Time Block
                            Expanded(
                              child: _buildDateTimeBlock(
                                context,
                                icon: Icons.access_time_rounded,
                                label: 'TIME',
                                value: DateFormat('hh:mm a').format(dateTime),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Repeated
                      if (isRepeat) ...[
                        const Divider(),
                        Center(
                          child: Text(
                            "This reminder repeats every $days ${days == 1 ? 'day' : 'days'}.",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const Divider(),
                      // Edit, Delete, Enable(on)/Disable(off) button
                      Row(
                        children: [
                          // Edit Button
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.edit_calendar_rounded,
                              text: "Edit",
                              color: theme.colorScheme.secondary,
                              onPressed: editReminder,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Delete BUTTON
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.delete_outline_rounded,
                              text: "Delete",
                              color: theme.colorScheme.error,
                              onPressed: deleteReminder,
                            ),
                          ),

                          // Turn on/off Button (Only available for repeating reminders)
                          // if (isRepeat) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: reminder.isActive
                                  ? Icons.notifications_off_rounded
                                  : Icons.notifications_active_rounded,
                              text: reminder.isActive ? "Turn Off" : "Turn On",
                              color: reminder.isActive
                                  ? Colors.orange
                                  : Colors.green,
                              onPressed: reminder.isActive
                                  ? disableReminder
                                  : enableReminder,
                            ),
                          ),
                          // ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeBlock(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, bool active) {
    final theme = Theme.of(context);

    final bgColor = active
        ? Colors.green.withValues(alpha: 0.1)
        : theme.colorScheme.error.withValues(alpha: 0.1);

    final borderColor = active ? Colors.green : theme.colorScheme.error;

    final textColor = active ? Colors.green.shade700 : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            size: 15,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            active ? "Active" : "Inactive",
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
