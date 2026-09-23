import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/main.dart';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService _instance =
      NotificationService._privateConstructor();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Notification channel constants
  static const String _channelId = 'storagio_channel';
  static const String _channelName = 'Storagio Notifications';
  static const String _channelDescription =
      'Notifications for item expiry, low stock alerts and custom reminders';
  static const int maxScheduledOccurrences = 10;

  String? _pendingPayload;

  String? get pendingPayload => _pendingPayload;

  void clearPendingPayload() {
    _pendingPayload = null;
  }

  /// Initialize notification plugin.
  /// Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database.
    tzdata.initializeTimeZones();

    // Set device local timezone.
    final String timeZoneName =
        await FlutterNativeTimezoneLatest.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timeZoneName));

    logger.d('Timezone from device: $timeZoneName');

    // Android initialization settings.
    const androidSettings = AndroidInitializationSettings('ic_not');

    // iOS / macOS settings.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combined initialization settings.
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    // Initialize plugin.
    await plugin.initialize(
      settings: settings,

      // To get the user response on the Notification
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _pendingPayload = response.payload;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateFromPayload(pendingPayload);
        });
      },
    );

    // To check if app is launched by clicking on Notification
    final details = await plugin.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      _pendingPayload = details!.notificationResponse?.payload;
    }

    // Create Android notification channel.
    await _createNotificationChannel();

    // Ensure exact alarm capabilities are checked for Android 13/14+.
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canSchedule =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      logger.d('Can schedule exact notifications: $canSchedule');
    }

    // Notifiaction permission setup is done on home screen.

    _initialized = true;
  }

  void navigateFromPayload(String? payload) {
    if (payload == null) return;

    final data = jsonDecode(payload) as Map<String, dynamic>;

    if (data['type'] == 'Low Stock') {
      clearPendingPayload();
      return;
    }

    navigatorKey.currentState?.pushNamed(
      AppRoutes.itemDetails,
      arguments: {'itemId': data['itemId']},
    );

    clearPendingPayload();
  }

  /// Create Android notification channel.
  Future<void> _createNotificationChannel() async {
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await androidPlugin.createNotificationChannel(channel);
  }

  /// Request notification permissions.
  Future<bool> requestPermissions() async {
    try {
      var status = await Permission.notification.status;
      if (status.isGranted) return true;

      if (!status.isPermanentlyDenied) {
        status = await Permission.notification.request();
        if (status.isGranted) return true;
      }
      return false;
    } catch (e) {
      logger.d('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Specifically handles Android 13/14+ Exact Alarm scheduling access
  Future<bool> checkAndRequestExactAlarms() async {
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return true; // Not Android, skip

    try {
      // Check if we already have exact alarm scheduling permissions
      final bool canSchedule =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      logger.d('Can schedule exact notifications: $canSchedule');

      if (!canSchedule) {
        logger.d(
          'Exact alarm permissions missing. Redirecting user to System Settings...',
        );
        // This directs Android users specifically to the "Alarms & Reminders" section
        // in their system settings where they can toggle it on.
        final status = await Permission.scheduleExactAlarm.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      logger.d('Error handling exact alarm permission: $e');
      return false;
    }
  }

  /// Shared notification details.
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// Generates stable notification IDs from item ID.
  int _generateId(String itemId, int salt) {
    final input = '$itemId-$salt';

    final digest = md5.convert(utf8.encode(input));

    // Use first 4 bytes to create a stable positive int
    final id =
        (digest.bytes[0] << 24) |
        (digest.bytes[1] << 16) |
        (digest.bytes[2] << 8) |
        digest.bytes[3];

    return id & 0x7FFFFFFF;
  }

  /// Low stock notification ID.
  int lowStockId(String itemId) => _generateId(itemId, 1000);

  /// Expiry notification ID.
  int expiryId(String itemId) => _generateId(itemId, 2000);

  /// Custom notification ID.
  int customNotifyId(String itemId, int i) => _generateId(itemId, 3000 + i);

  /// Show low stock notification immediately.
  Future<void> showLowStockNotification({
    required String itemId,
    required String itemName,
    required double quantity,
    required String unit,
  }) async {
    await plugin.show(
      id: lowStockId(itemId),
      title: 'Low Stock',
      body: '$itemName is running low.\nRemaining: $quantity $unit',
      notificationDetails: _notificationDetails(),
      payload: jsonEncode({"type": "Low Stock"}),
    );
  }

  /// Schedule expiry notification.
  /// Existing notification is cancelled first, to prevent duplicate scheduled notifications.
  Future<void> scheduleExpiryNotification({
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    final notificationId = expiryId(itemId);

    // Cancel old notification before rescheduling.
    await cancel(notificationId);

    // Schedule notification at 8:00 AM on expiry date.
    final notificationDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      8, // 8 AM
      0,
    );

    // Converting the intended notification DateTime (local) into a TZ-aware DateTime
    // so the notification fires at 8:00 AM local time on the expiry date.
    final tzDate = tz.TZDateTime.from(notificationDate, tz.local);

    // Prevent scheduling past dates.
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    logger.d("""
      Item: $itemName
      ExpiryDate DB: $expiryDate
      Notification Time: $notificationDate
      Scheduled TZ Date: $tzDate
      Now: ${tz.TZDateTime.now(tz.local)}
      tz.local = ${tz.local.name}
      tzDate = $tzDate
      isUtc = ${expiryDate.isUtc}
    """);

    await plugin.zonedSchedule(
      id: notificationId,
      title: 'Item Expiry',
      body: '$itemName expires now.',
      scheduledDate: tzDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: jsonEncode({"itemId": itemId, "type": "Expiry"}),
    );
  }

  /// Schedule custom notification.
  /// Existing notification is cancelled first, to prevent duplicate scheduled notifications.
  /// Schedule repeating custom notifications
  Future<void> scheduleRepeatingCustomNotification({
    required String itemId,
    required String itemName,
    required String content,
    required DateTime startDate,
    required int intervalDays,
    required bool isRepeat,
  }) async {
    // SCENARIO 1: Schedule Once
    DateTime firstDate = startDate;

    // Single reminder
    if (!isRepeat || intervalDays <= 0) {
      if (firstDate.isBefore(DateTime.now())) return;

      final notificationId = customNotifyId(itemId, 0);
      final tzDate = tz.TZDateTime.from(firstDate, tz.local);

      logger.d(
        "Scheduling SINGLE custom notification for Item: $itemName at $tzDate",
      );

      await plugin.zonedSchedule(
        id: notificationId,
        title: itemName,
        body: content,
        scheduledDate: tzDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: jsonEncode({"itemId": itemId, "type": "Custom"}),
      );

      return;
    }

    // SCENARIO 2: Schedule Repeating (Interval is valid and repeat is true)
    // Find the first occurrence that is in the future.
    final now = DateTime.now();

    if (firstDate.isBefore(now)) {
      final elapsedDays = now.difference(firstDate).inDays;

      // Number of completed intervals since the original start date
      final intervalsPassed = (elapsedDays ~/ intervalDays) + 1;

      firstDate = firstDate.add(Duration(days: intervalsPassed * intervalDays));
    }

    for (int i = 0; i < maxScheduledOccurrences; i++) {
      final scheduleDate = firstDate.add(Duration(days: intervalDays * i));

      final notificationId = customNotifyId(itemId, i);
      final tzDate = tz.TZDateTime.from(scheduleDate, tz.local);

      logger.d("""
      Item: $itemName
      Occurrence #$i
      Date: ${DateFormat('dd MMM yyyy | hh:mm a').format(tzDate)}
      """);

      await plugin.zonedSchedule(
        id: notificationId,
        title: itemName,
        body: content,
        scheduledDate: tzDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: jsonEncode({"itemId": itemId, "type": "Custom"}),
      );
    }
  }

  /// Cancel all pre-scheduled occurrences of a repeating custom notification
  Future<void> cancelRepeatingCustomNotification(String itemId) async {
    for (int i = 0; i < maxScheduledOccurrences; i++) {
      final notificationId = customNotifyId(itemId, i);

      // Cancel each specific ID channel
      await cancel(notificationId);
    }

    logger.d("Cancelled all scheduled custom notifications for item: $itemId");
  }

  /// Cancel notification by ID.
  Future<void> cancel(int id) async {
    await plugin.cancel(id: id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  /// Print all pending scheduled notifications.
  Future<void> printPendingNotifications() async {
    final pending = await plugin.pendingNotificationRequests();

    logger.d('Pending notification count: ${pending.length}');

    if (pending.isEmpty) {
      logger.d('No pending notifications.');
      return;
    }

    final printedBody = <String>{};

    for (final notification in pending) {
      final body = notification.body ?? '';

      // Skip if this notification body has already been printed.
      if (!printedBody.add(body)) continue;

      logger.d('''
      ID: ${notification.id}
      Title: ${notification.title}
      Body: ${notification.body}
      ''');
    }
  }
}
