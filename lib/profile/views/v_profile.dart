import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/theme/theme.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/utils/input_validators.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/profile/views/v_help_support.dart';
import 'package:storagio/profile/viewmodels/vm_profile.dart';
import 'package:storagio/room/vm_room.dart';
import 'package:storagio/user/vm_user.dart';

class VProfile extends ConsumerWidget {
  const VProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileVMProvider);
    final vm = ref.read(profileVMProvider.notifier);
    final user = ref.watch(userProvider).value;
    final roomAsync = ref.watch(roomProvider).value;
    final itemsAsync = ref.watch(itemProvider).value;

    final roomCount = roomAsync != null ? roomAsync.length : 0;
    final itemCount = itemsAsync != null ? itemsAsync.length : 0;
    final isLoggedIn = user != null;

    logger.d(
      'Total items from list: $itemCount\nTotal rooms from list: $roomCount',
    );

    final isEditing = state.isEditing;
    final isDeleting = state.isDeleting;

    final String? imagePath = user?.profileImage;

    final File? file =
        imagePath != null &&
            imagePath.trim().isNotEmpty &&
            File(imagePath).existsSync()
        ? File(imagePath)
        : null;

    return Scaffold(
      appBar: AppBar(title: appBarText("Profile")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// PROFILE HEADER
              Column(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 5,
                    shape: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: file != null
                                  ? FileImage(file)
                                  : null,
                              child: file == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                          ),
                          if (isLoggedIn) ...[
                            // Edit Image
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: imageButtonDecor(),
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                    iconSize: 25,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: isEditing
                                      ? null
                                      : () {
                                          vm.pickProfileImage();
                                        },
                                  icon: isEditing
                                      ? loadingDisplay()
                                      : Icon(
                                          file != null ? Icons.edit : Icons.add,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ),
                            // Delete Image
                            if (file != null)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  decoration: imageButtonDecor(),
                                  child: IconButton(
                                    visualDensity: VisualDensity.compact,
                                    style: IconButton.styleFrom(
                                      iconSize: 25,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: isDeleting
                                        ? null
                                        : () async {
                                            final bool shouldDelete =
                                                await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => const DeleteRecord(
                                                    title:
                                                        'Delete Profile Image',
                                                    message:
                                                        'Are you sure you want to delete profile image? This action cannot be undone.',
                                                  ),
                                                ) ??
                                                false;

                                            if (shouldDelete) {
                                              await vm.deleteProfileImage();
                                            }
                                          },
                                    icon: isDeleting
                                        ? loadingDisplay()
                                        : const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    user?.fullName ?? "Guest",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (isLoggedIn)
                    Text(user.email, style: const TextStyle(fontSize: 16)),
                ],
              ),

              const SizedBox(height: 30),

              /// STATS ROW
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Items',
                      value: '$itemCount',
                      valueColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _StatCard(
                      label: 'Rooms',
                      value: '$roomCount',
                      valueColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// MENU
              Column(
                children: [
                  if (isLoggedIn)
                    _MenuTile(
                      icon: Icons.person_outline,
                      title: 'Edit Fullname',
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => _EditProfileDialog(
                            fullname: user.fullName,
                            onSave: (String? value) async {
                              if (value != null) {
                                logger.d("New fullname $value");
                                // Save to db
                                await vm.updateFullName(value);
                              }
                            },
                          ),
                        );
                      },
                    ),

                  _MenuTile(
                    icon: Icons.security_outlined,
                    title: 'Security & Privacy',
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const _SecurityPrivacyDialog(),
                      );
                    },
                  ),
                  _MenuTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const _HelpSupportDialog(),
                      );
                    },
                  ),

                  /// SHOW ONLY WHEN LOGGED IN
                  if (isLoggedIn)
                    _MenuTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      titleColor: Colors.red,
                      onTap: () async {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => _LogoutDialog(
                            logout: () async {
                              final LogoutStatus ls = await vm.logoutProcess();

                              if (!context.mounted) return;

                              if (ls.success) {
                                Navigator.pop(context);
                              }

                              showSnackBar(
                                ls.message,
                                backgroundColor: Colors.red,
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration imageButtonDecor() {
    return BoxDecoration(
      color: const Color(0xFF1E88E5),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    );
  }

  Widget loadingDisplay() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}

class _LogoutDialog extends ConsumerWidget {
  final VoidCallback logout;

  const _LogoutDialog({required this.logout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(profileVMProvider);
    final isProcessing = state.isProcessing;

    return PopScope(
      // Prevent closing while the logout is in progress.
      canPop: !isProcessing,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WarningIcon(),
                const SizedBox(height: 24),
                const Text(
                  'Log Out?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Logging out will remove all locally stored inventory data from this device. Make sure your latest changes have been synced to the cloud before continuing. You can sign in again later to restore your synced data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade300 : Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: isProcessing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Logging out..."),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            const CCancelButton(),

                            CPositiveButton(
                              text: 'Log Out',
                              callback: logout,
                              iconData: Icons.logout,
                              bgColor: const Color(0xFFC62828),
                            ),
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

// Stateless Widgets
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF0D1B34),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CustomInnerShadow(
                shadowColor: const Color(0xFFB0C4DE).withValues(alpha: 0.5),
                blur: 5,
                offset: const Offset(0, 3),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark
                        ? AppColors.surfaceLight
                        : const Color(0xFF2D4373),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatelessWidget {
  final String fullname;
  final Function(String? value) onSave;
  const _EditProfileDialog({required this.fullname, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final editProfileFK = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController controller = TextEditingController(
      text: fullname,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
        child: SingleChildScrollView(
          child: Form(
            key: editProfileFK,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: .start,
              children: [
                Align(
                  alignment: .topCenter,
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: .topCenter,
                  child: Text(
                    'Update your personal\ndetails',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade300 : Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const CLabel(text: 'FULL NAME'),
                CTextFormField(
                  hint: 'Alex Thorne',
                  validator: AppValidators.fullName,
                  controller: controller,
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: CPositiveButton(
                    text: 'Save Changes',
                    callback: () {
                      if (editProfileFK.currentState?.validate() ?? false) {
                        logger.d("Valid Inputs");
                        Navigator.pop(context);
                        onSave(controller.text.toString());
                      }
                    },
                    iconData: Icons.save,
                  ),
                ),
                const SizedBox(height: 20),
                Align(alignment: .center, child: CCancelButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpSupportDialog extends StatelessWidget {
  const _HelpSupportDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Text(
                'Help & Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              Text(
                'How can we assist you with Storagio today?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade300 : Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              _OptionTile(
                title: 'FAQs',
                icon: Icons.quiz_outlined,
                iconBgColor: Color(0xFFE1EBFD),
                iconColor: Color(0xFF3E69B9),
                callback: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.helpSupport,
                    arguments: {'type': HelpSupportType.faq},
                  );
                },
              ),

              _OptionTile(
                title: 'Contact Support',
                icon: Icons.contact_support,
                iconBgColor: Color(0xFFD1FBF0),
                iconColor: Color(0xFF14B8A6),
                callback: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.helpSupport,
                    arguments: {'type': HelpSupportType.contact},
                  );
                },
              ),

              _OptionTile(
                title: 'Report Bug',
                icon: Icons.bug_report_outlined,
                iconBgColor: Color(0xFFFEE2E2),
                iconColor: Color(0xFFEF4444),
                callback: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.helpSupport,
                    arguments: {'type': HelpSupportType.report},
                  );
                },
              ),

              _OptionTile(
                title: 'User Guide',
                icon: Icons.menu_book_rounded,
                iconBgColor: Color(0xFFFEF3C7),
                iconColor: Color(0xFFF59E0B),
                callback: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.helpSupport,
                    arguments: {'type': HelpSupportType.guide},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String? description;
  final VoidCallback? callback;

  const _OptionTile({
    required this.title,
    required this.icon,
    this.iconBgColor,
    this.iconColor,
    this.callback,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: callback == null
          ? ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: buildLeading(isDark),
              title: buildTitle(title),
              children: [
                Text(
                  description!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: InkWell(
                onTap: () {
                  callback?.call();
                },
                child: Row(
                  children: [
                    buildLeading(isDark),
                    const SizedBox(width: 20),
                    buildTitle(title),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildLeading(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            iconBgColor ??
            (isDark
                ? Colors.blueGrey.withValues(alpha: 0.25)
                : const Color(0xFFEAF2FF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color:
            iconColor ??
            (isDark ? Colors.lightBlueAccent : const Color(0xFF0056B3)),
        size: 28,
      ),
    );
  }

  Widget buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
    );
  }
}

class _SecurityPrivacyDialog extends StatelessWidget {
  const _SecurityPrivacyDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blueGrey.withValues(alpha: 0.2)
                      : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: isDark
                      ? Colors.lightBlueAccent
                      : const Color(0xFF0056B3),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Security & Privacy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  'Your data security and privacy are important to us. Storagio is designed to keep your inventory information safe and protected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF5C6B89),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const _OptionTile(
                icon: Icons.lock_outline,
                title: 'Secure Data Storage',
                description:
                    'Your inventory data is stored securely to help protect your personal information.',
              ),

              const _OptionTile(
                icon: Icons.backup_outlined,
                title: 'Backup Protection',
                description:
                    'Backup and restore features help keep your data safe when switching or reinstalling devices.',
              ),

              const _OptionTile(
                icon: Icons.visibility_off_outlined,
                title: 'Privacy First',
                description:
                    'Storagio does not share your personal inventory details without your permission.',
              ),

              const _OptionTile(
                icon: Icons.update_outlined,
                title: 'Regular Improvements',
                description:
                    'Security and app stability improvements are included through regular updates.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
