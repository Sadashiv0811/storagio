import 'package:flutter/material.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/custom_reminder/v_custom_reminder.dart';
import 'package:storagio/inventory/item/views/v_unorganized_items.dart';
import 'package:storagio/profile/views/v_help_support.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/user/views/v_login.dart';
import 'package:storagio/user/views/v_signup.dart';
import 'package:storagio/inventory/search/v_search.dart';
import 'package:storagio/inventory/item/views/v_add_edit.dart';
import 'package:storagio/v_home.dart';
import 'package:storagio/inventory/item/views/v_item_details.dart';
import 'package:storagio/inventory/item/views/v_item_alerts.dart';
import 'package:storagio/v_splash.dart';
import 'package:storagio/profile/views/v_profile.dart';
import 'package:storagio/room/views/v_room_items.dart';

class AppRoutes {
  // Route Strings
  static const String splash = '/';
  static const String home = '/home';
  static const String addEditItem = '/addEditItem';
  static const String itemDetails = '/itemDetails';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roomItems = '/roomItems';
  static const String unorganizedItems = '/unorganizedItems';
  static const String customReminder = '/customReminder';
  static const String helpSupport = '/helpSupport';
  static const String itemAlerts = '/itemAlerts';

  // Argument Strings
  static const String itemS = 'item';
  static const String disableRoomS = 'disableRoom';
  static const String itemIdS = 'itemId';
  static const String reminderS = 'reminder';
  static const String typeS = 'type';
  static const String roomS = 'room';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const VSplash(), settings);
      case home:
        return _buildRoute(const VHome(), settings);
      case addEditItem:
        final args = settings.arguments as Map<String, dynamic>?;

        final item = args?[itemS] as MItem?;
        final disableRoom = args?[disableRoomS] as bool? ?? false;

        return _buildRoute(
          VAddEditItem(item: item, disableRoom: disableRoom),
          settings,
        );
      case itemDetails:
        final args = settings.arguments as Map<String, dynamic>;

        final String itemId = args[itemIdS];
        final bool disableRoom = args[disableRoomS] ?? false;

        return _buildRoute(
          VItemDetails(itemId: itemId, disableRoom: disableRoom),
          settings,
        );
      case customReminder:
        final args = settings.arguments as Map<String, dynamic>;

        final item = args[itemS] as MItem;
        final reminder = args[reminderS];

        return _buildRoute(
          VCustomReminder(item: item, reminder: reminder),
          settings,
        );
      case helpSupport:
        final args = settings.arguments as Map<String, dynamic>;

        final HelpSupportType type = args[typeS];

        return _buildRoute(VHelpSupportDetails(type: type), settings);
      case search:
        return _buildRoute(const VSearch(), settings);
      case profile:
        return _buildRoute(const VProfile(), settings);
      case login:
        return _buildRoute(const VLogin(), settings);
      case signup:
        return _buildRoute(const VSignup(), settings);
      case roomItems:
        final args = settings.arguments as Map<String, dynamic>;

        final MRoom room = args[roomS];

        return _buildRoute(VRoomItems(room: room), settings);
      case unorganizedItems:
        return _buildRoute(const VUnorganizedItems(), settings);
      case itemAlerts:
        return _buildRoute(const VItemAlerts(), settings);
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05); 
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
