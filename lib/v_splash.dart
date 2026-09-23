import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/activity/vm_activity.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/inventory/category/m_category.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/custom_reminder/r_custom_reminder.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/room/vm_room.dart';
import 'package:storagio/user/vm_user.dart';
import 'package:uuid/uuid.dart';

class VSplash extends ConsumerStatefulWidget {
  const VSplash({super.key});

  @override
  ConsumerState<VSplash> createState() => _VSplashState();
}

class _VSplashState extends ConsumerState<VSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _bottomFadeAnimation;

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),

        // Load app data.
        Future.wait([
          ref.read(userProvider.future),
          ref.read(roomProvider.future),
          ref.read(categoryProvider.future),
          ref.read(itemProvider.future),
          ref.read(activityProvider.future),
          ref.read(customReminderRepositoryProvider.future),
        ]),
      ]);

      final categories = await ref.read(categoryProvider.future);

      if (categories.isEmpty) {
        final notifier = ref.read(categoryProvider.notifier);

        for (final category in createPredefinedCategories()) {
          await notifier.addCategory(category);
        }
      }

      final user = await ref.read(userProvider.future);
      if (user != null) {
        user.log(false);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      logger.d('Initialization error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  List<MCategory> createPredefinedCategories() {
    const uuid = Uuid();

    final List<MCategory> categories = [];

    for (int i = 0; i < CategoryNames.categoryList.length; i++) {
      categories.add(
        MCategory(
          id: uuid.v4(),
          categoryName: CategoryNames.categoryList[i],
          icon: iconsListCategory[i].codePoint.toString(),
          color: colorsList[i % colorsList.length].toARGB32(),
          synced: false,
        ),
      );
    }

    return categories;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _bottomFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background Gradient
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7A84E8), Color(0xFFB55DF3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo & Branding Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Outer Container (Semi-transparent)
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(45),
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Center(
                            child: Image.asset(
                              'res/icon/splash_icon_c.png',
                              width: MediaQuery.sizeOf(context).width * 0.42,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App Name
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SlideTransition(
                      position: _textSlideAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Storagio',
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 1.1,
                              fontFamily: 'amaranth',
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Tagline
                          Text(
                            'Organize Your Home Smartly',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // Loading Indicator
              FadeTransition(
                opacity: _bottomFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: null, // Make it indeterminate for dynamic feeling
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Version Badge
              FadeTransition(
                opacity: _bottomFadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    'VERSION 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
