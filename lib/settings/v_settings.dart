import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/theme/p_theme.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/room/vm_room.dart';
import 'package:storagio/settings/dialogs/default_setup/p_default_c_r.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:storagio/user/vm_user.dart';

// Consumer Widget
class VSettings extends ConsumerWidget {
  const VSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(settingsVMProvider);
    final roomAsync = ref.watch(roomProvider);
    final categoryAsync = ref.watch(categoryProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeProvider);
    final current = currentTheme == ThemeModeType.dark ? "Dark" : "Light";

    final userObj = ref.watch(userProvider).value;

    final isLoggedIn = userObj != null;
    final sliderValue =
        userObj?.lowStockLimit.toDouble() ?? vm.lowStockThreshold;

    final defaultCategoryName = ref.watch(defaultCategoryProvider);

    return Scaffold(
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        children: [
          const HeaderSection(
            title: 'Settings',
            message: 'Manage your home inventory preferences and data.',
          ),

          const SizedBox(height: 32),

          // GENERAL
          const CLabel(text: 'GENERAL'),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.language,
                iconColor: const Color(0xFF4C84FF),
                title: 'Language',
                trailing: CustomInnerShadow(
                  shadowColor: const Color(0xFFB0C4DE).withValues(alpha: 0.5),
                  blur: 5,
                  offset: const Offset(0, 3),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      'English (US)',
                      style: TextStyle(color: Color(0xFF4C84FF)),
                    ),
                  ),
                ),
              ),

              _SettingsTile(
                icon: Icons.dark_mode,
                iconColor: const Color(0xFFFFB067),
                title: 'Theme',

                trailing: AnimatedToggleSwitch<String>.dual(
                  animationDuration: const Duration(seconds: 1),

                  current: current,

                  first: "Light",
                  second: "Dark",

                  borderWidth: 2.0,
                  height: 40,

                  onChanged: (value) {
                    vm.changeTheme(ref, value);
                  },

                  style: ToggleStyle(
                    indicatorColor: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),

                  iconBuilder: (value) => Icon(
                    value == "Light" ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),

                  textBuilder: (value) => Center(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // INVENTORY PREFERENCES
          const CLabel(text: 'INVENTORY PREFERENCES'),

          _SettingsGroup(
            children: [
              Column(
                children: [
                  _SettingsTile(
                    icon: Icons.low_priority,
                    iconColor: const Color(0xFFFF8585),
                    title: 'Low stock threshold',

                    trailing: Text(
                      '${sliderValue.toInt()} units',

                      style: TextStyle(
                        color: isDark
                            ? const Color.fromARGB(255, 0, 234, 255)
                            : const Color(0xFF4C84FF),

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Slider(
                    value: sliderValue,

                    max: 20,
                    divisions: 10,
                    showValueIndicator: ShowValueIndicator.onDrag,

                    label: sliderValue.toInt().toString(),

                    onChanged: vm.updateThresholdUI,
                    onChangeEnd: vm.saveThreshold,

                    activeColor: isDark
                        ? const Color.fromARGB(255, 0, 234, 255)
                        : const Color(0xFF2A67FF),

                    inactiveColor: Colors.grey,
                  ),
                ],
              ),

              categoryAsync.when(
                data: (categoryList) {
                  if (categoryList.isEmpty) {
                    return emptyList(isRoom: false);
                  }

                  final selectedCategory = categoryList.firstWhereOrNull(
                    (c) => c.categoryName == defaultCategoryName,
                  );

                  String trailingText =
                      selectedCategory?.categoryName ??
                      categoryList.first.categoryName;

                  final index = trailingText.lastIndexOf(' ');
                  if (index != -1) {
                    trailingText =
                        '${trailingText.substring(0, index)}\n${trailingText.substring(index + 1)}';
                  }

                  return _SettingsTile(
                    icon: Icons.category,
                    iconColor: const Color(0xFF5D5D5D),
                    title: 'Default category',
                    trailing: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120),
                      child: Text(
                        trailingText,
                        overflow: .ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    callback: () async {
                      await vm.openDefaultCategoryDialog(context);
                    },
                  );
                },

                error: (e, s) => ErrorDisplay(error: e, stack: s),

                loading: () => const LoadingDisplay(),
              ),

              roomAsync.when(
                data: (roomsList) {
                  if (roomsList.isEmpty) {
                    return emptyList(isRoom: true);
                  }

                  // Get the current default room ID from the provider
                  final defaultRoomId = ref.watch(defaultRoomProvider);

                  // Looks up the matching room based on default room id
                  MRoom? selectedRoom = roomsList.firstWhereOrNull(
                    (r) => r.id == defaultRoomId,
                  );

                  // If the room was deleted (not found) or ID was empty, fallback to the first room
                  if (selectedRoom == null) {
                    selectedRoom = roomsList.first;

                    // Automatically update the provider and SharedPreferences in the background
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(defaultRoomProvider.notifier)
                          .setDefaultRoom(selectedRoom!.id);
                    });
                  }

                  // Fallback to the first room if no match is found
                  final String trailingText = selectedRoom.roomName;

                  return _SettingsTile(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFF2A2A2A),
                    title: 'Default room',
                    trailing: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120),
                      child: Text(
                        trailingText,
                        overflow: .ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    callback: () async {
                      await vm.openDefaultRoomDialog(context);
                    },
                  );
                },

                error: (e, s) => ErrorDisplay(error: e, stack: s),

                loading: () => const LoadingDisplay(),
              ),
            ],
          ),

          // NOTIFICATIONS
          const CLabel(text: 'NOTIFICATIONS'),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.notifications,
                iconColor: const Color(0xFF4C84FF),
                title: 'Low stock alerts',

                trailing: Switch(
                  value: vm.notifyLowStock,
                  onChanged: (value) async {
                    await vm.toggleLowStock(value);

                    if (!context.mounted) return;

                    showSnackBar(
                      value
                          ? "Low stock notifications turned on"
                          : "Low stock notifications turned off",
                      backgroundColor: value
                          ? Colors.green
                          : Colors.orangeAccent,
                    );
                  },
                  activeThumbColor: Theme.of(context).colorScheme.secondary,
                  activeTrackColor: Theme.of(context).colorScheme.surface,
                  trackOutlineColor: WidgetStateProperty.all(
                    isDark
                        ? vm.notifyLowStock
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white
                        : vm.notifyLowStock
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          // DATA MANAGEMENT
          const CLabel(text: 'DATA MANAGEMENT'),

          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.sync,
                iconColor: const Color(0xFF2A2A2A),
                title: 'Sync Data',
                callback: () => vm.syncNow(context),
              ),

              _SettingsTile(
                icon: Icons.delete_forever,
                iconColor: const Color(0xFFE53935),
                title: 'Clear Data',
                titleColor: const Color(0xFFE53935),

                callback: () async {
                  await vm.openClearDataDialog(context);
                },
              ),
            ],
          ),

          // ABOUT
          const CLabel(text: 'ABOUT'),

          _SettingsGroup(
            children: [
              _SettingsTile(
                title: 'App version',
                trailing: const Text('v1.0.0-stable'),
              ),

              _SettingsTile(
                title: 'Developer',

                trailing: Text(
                  'Storagio Team',

                  style: TextStyle(
                    color: isDark
                        ? const Color.fromARGB(255, 0, 234, 255)
                        : const Color(0xFF2A67FF),

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (!isLoggedIn) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Navigator.pushNamed(
                  context,
                  AppRoutes.login,
                );

                if (status != RegisterStatus.login.name || !context.mounted) {
                  return;
                }

                final result = await ref
                    .read(settingsVMProvider.notifier)
                    .handleLogin();

                if (!context.mounted) return;

                if (!result.success) {
                  showSnackBar(result.message!, backgroundColor: Colors.red);
                  return;
                }

                if (result.showSyncDialog) {
                  // Show sync dialog
                  await vm.openSyncDialog(
                    context: context,
                    autoShowDialog: true,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.login, size: 22),
              label: const Text(
                "Login",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget emptyList({required bool isRoom}) {
    return _SettingsTile(
      icon: isRoom ? Icons.location_on : Icons.category,
      iconColor: isRoom ? const Color(0xFF2A2A2A) : const Color(0xFF5D5D5D),
      title: isRoom ? 'Default room' : 'Default category',
      trailing: Text(
        isRoom ? 'No rooms' : 'No category',
        overflow: .ellipsis,
        maxLines: 1,
      ),
      callback: null,
    );
  }
}

// Stateless Widgets
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 5,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? callback;

  const _SettingsTile({
    this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.callback,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: callback,
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade100
                      : iconColor?.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: title == "Clear All Data"
                      ? isDark
                            ? Colors.red.shade400
                            : Colors.red
                      : isDark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
