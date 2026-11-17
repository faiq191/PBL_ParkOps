import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../parking/data/camera_feeds.dart';
import '../../parking/data/repositories/parking_repository_impl.dart';
import '../../parking/domain/entities/camera_inference_result.dart';
import '../../parking/domain/repositories/parking_repository.dart';
import 'notification_repeat.dart';
import 'parking_notification_content.dart';

class ParkingNotificationService {
  ParkingNotificationService._(this._repository);

  /// Reuses the app's Firestore-backed repository so the daily summary reads
  /// the same live ML results that the Home/Camera tabs display.
  static ParkingNotificationService? _instance;

  static ParkingNotificationService get instance {
    return _instance ??= ParkingNotificationService._(
      ParkingRepositoryImpl(firestore: FirebaseFirestore.instance),
    );
  }

  final ParkingRepository _repository;

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
    required int repeatDays,
  }) async {
    if (!isValidNotificationRepeatMask(repeatDays)) {
      throw StateError(
        'Select at least one day for the notification schedule.',
      );
    }
    _ensureSupportedPlatform();
    await _ensureInitialized();

    // The ML summary is read once and reused for every selected day so adding
    // repeat days never increases Firestore reads.
    final content = await _buildContent(favoriteLotId: favoriteLotId);
    final localNow = timezone.TZDateTime.now(timezone.local);

    // Cancel the legacy single schedule and all per-day ids before adding the
    // new ones, otherwise changing days would leave duplicate notifications.
    await _cancelSummarySchedules();

    for (final weekday in notificationWeekdaysFromMask(repeatDays)) {
      final scheduled = nextNotificationDate(
        now: localNow,
        weekday: weekday,
        minuteOfDay: minuteOfDay,
      );
      await _plugin.zonedSchedule(
        id: notificationIdForWeekday(weekday),
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Reads the same `camera_inference` documents the Home tab watches. The
  /// favorite lot is used only as a label; every count comes from live ML data.
  Future<ParkingNotificationContent> _buildContent({
    required String favoriteLotId,
  }) async {
    final results = <CameraInferenceResult>[];
    try {
      for (final feed in cameraFeeds) {
        final result = await _repository.watchCameraInference(feed.id).first;
        if (result != null) results.add(result);
      }
    } on Object {
      // SettingsPage already reports StateError to the user; FirestoreFailure
      // would otherwise bypass its catch clauses.
      throw StateError('Could not load the latest ML camera results.');
    }
    if (results.isEmpty) {
      throw StateError(
        'No ML camera results are available yet. '
        'Ask the laptop operator to start the ML worker.',
      );
    }

    String? favoriteLotName;
    try {
      final zones = await _repository.watchZones().first;
      for (final zone in zones) {
        if (zone.id == favoriteLotId) favoriteLotName = zone.name;
      }
    } on Object {
      // The label is optional; never block the summary because zones failed.
    }

    return buildSummaryContent(
      results: results,
      favoriteLotName: favoriteLotName,
    );
  }

  Future<void> cancelDailySummary() async {
    _ensureSupportedPlatform();
    await _ensureInitialized();
    await _cancelSummarySchedules();
  }

  /// Clears the legacy daily schedule (4101) and every per-weekday schedule
  /// (4102..4108) so disabling or rescheduling can never leave stale alerts.
  Future<void> _cancelSummarySchedules() async {
    await _plugin.cancel(id: notificationSummaryBaseId);
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: notificationIdForWeekday(weekday));
    }
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

/// Pure mapping from live ML results to the notification text. Kept separate
/// so it can be tested without the notification plugin or Firestore.
ParkingNotificationContent buildSummaryContent({
  required List<CameraInferenceResult> results,
  required String? favoriteLotName,
}) {
  final emptySpaces = results.fold<int>(
    0,
    (total, result) => total + result.emptySpaceCount,
  );
  final vehicles = results.fold<int>(
    0,
    (total, result) => total + result.vehicleCount,
  );
  final latest = results
      .map((result) => result.processedAt)
      .whereType<DateTime>()
      .fold<DateTime?>(
        null,
        (latest, time) =>
            latest == null || time.isAfter(latest) ? time : latest,
      );

  final spaceLabel = emptySpaces == 1 ? 'space' : 'spaces';
  final vehicleLabel = vehicles == 1 ? 'vehicle' : 'vehicles';
  final perCamera = results
      .map((result) {
        final feed = cameraFeeds.where((item) => item.id == result.cameraId);
        final name = feed.isEmpty ? result.cameraId : feed.first.title;
        return '$name: ${result.emptySpaceCount} empty';
      })
      .join(' · ');

  final body = StringBuffer();
  if (favoriteLotName != null && favoriteLotName.isNotEmpty) {
    body.write('$favoriteLotName · ');
  }
  body.write(perCamera);
  body.write(' · $vehicles $vehicleLabel detected');
  if (latest != null) body.write(' · Updated ${_formatClock(latest)}');

  return ParkingNotificationContent(
    title: '$emptySpaces $spaceLabel detected by parking cameras',
    body: body.toString(),
  );
}

/// HH:MM:SS in local time, matching the clock format used on the other pages.
String _formatClock(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}
