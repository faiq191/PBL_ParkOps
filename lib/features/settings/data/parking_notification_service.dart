import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../parking/data/seed_zones.dart';
import 'parking_notification_content.dart';

class ParkingNotificationService {
  ParkingNotificationService._();

  static final instance = ParkingNotificationService._();
  static const _dailySummaryId = 4101;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final platformPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (platformPlugin == null) {
          throw StateError('Android notifications are not available.');
        }
        final notificationsAllowed = await platformPlugin
            .requestNotificationsPermission();
        if (notificationsAllowed == false) return false;
        final exactAlarmsAllowed = await platformPlugin
            .canScheduleExactNotifications();
        if (exactAlarmsAllowed == true) return true;
        return await platformPlugin.requestExactAlarmsPermission() ?? false;
      case TargetPlatform.iOS:
        final platformPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (platformPlugin == null) {
          throw StateError('iOS notifications are not available.');
        }
        return await platformPlugin.requestPermissions(alert: true) ?? false;
      case TargetPlatform.macOS:
        final platformPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        if (platformPlugin == null) {
          throw StateError('macOS notifications are not available.');
        }
        return await platformPlugin.requestPermissions(alert: true) ?? false;
      default:
        throw UnsupportedError(
          'Daily notifications are supported on Android, iOS, and macOS.',
        );
    }
  }

  Future<void> scheduleDailySummary({
    required String favoriteLotId,
    required int minuteOfDay,
  }) async {
    _ensureSupportedPlatform();
    await _ensureInitialized();

    // Local demo data only: replace seedZones with Firebase parking zones
    // when available. Re-schedule this recurring notification whenever that
    // live data changes, or move the daily summary to a server push function.
    final content = ParkingNotificationContent.fromZones(
      zones: seedZones,
      favoriteLotId: favoriteLotId,
    );
    final localNow = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      localNow.year,
      localNow.month,
      localNow.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (!scheduled.isAfter(localNow)) {
      scheduled = timezone.TZDateTime(
        timezone.local,
        localNow.year,
        localNow.month,
        localNow.day + 1,
        minuteOfDay ~/ 60,
        minuteOfDay % 60,
      );
    }

    await _plugin.zonedSchedule(
      id: _dailySummaryId,
      title: content.title,
      body: content.body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_parking_summary',
          'Daily parking summary',
          channelDescription: 'Daily available spaces for your favorite lot.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
        macOS: DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailySummary() async {
    _ensureSupportedPlatform();
    await _ensureInitialized();
    await _plugin.cancel(id: _dailySummaryId);
  }

  void _ensureSupportedPlatform() {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      throw UnsupportedError(
        'Daily notifications are supported on Android, iOS, and macOS.',
      );
    }
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _ensureSupportedPlatform();
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized != true) {
      throw StateError('Could not initialize local notifications.');
    }
  }
}
