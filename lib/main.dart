import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/services/s_notification.dart';

import 'package:storagio/core/theme/p_theme.dart';
import 'package:storagio/core/theme/r_theme.dart';
import 'package:storagio/core/theme/theme.dart';
import 'package:storagio/core/theme/vm_theme.dart';
import 'package:storagio/core/utils/common.dart';

import 'package:storagio/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AppCheck.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),
  );

  // Initialize notifications.
  // This does not request the user for permission.
  await NotificationService().init();

  // Load saved theme.
  final repo = ThemeRepository();
  final savedTheme = await repo.loadTheme();

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeViewModel(repo, savedTheme)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Storagio',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      themeMode: theme == ThemeModeType.light
          ? ThemeMode.light
          : ThemeMode.dark,

      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
