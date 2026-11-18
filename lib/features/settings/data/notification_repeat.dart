import 'package:timezone/timezone.dart' as timezone;

/// Base id used by the daily parking summary. The original implementation
/// scheduled a single repeating notification with this id; it is cancelled
/// when rescheduling so older installs never receive duplicate summaries.
const int notificationSummaryBaseId = 4101;

const int _allDaysMask = 0x7F; // bits 0..6 == Monday..Sunday
const int _weekdaysMask = 0x1F; // Monday..Friday

/// Sunday-first chip labels, matching the Android alarm repeat picker. The
/// stored bitmask still uses `DateTime.weekday` (1=Mon..7=Sun) internally.
const List<String> notificationWeekdayLabels = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

/// Converts a Sunday-first chip index (0..6) to `DateTime.weekday`.
int notificationWeekdayFromChipIndex(int index) => index == 0 ? 7 : index;

String notificationWeekdayLabel(int weekday) =>
    notificationWeekdayLabels[weekday == 7 ? 0 : weekday];

const int everyDayNotificationRepeatMask = _allDaysMask;
const int weekdaysNotificationRepeatMask = _weekdaysMask;

enum NotificationRepeatPreset { everyDay, weekdays, custom }

/// Converts a stored bitmask into `DateTime.weekday` values (1=Mon..7=Sun).
Set<int> notificationWeekdaysFromMask(int mask) {
  final days = <int>{};
  for (var weekday = 1; weekday <= 7; weekday++) {
    if (mask & (1 << (weekday - 1)) != 0) days.add(weekday);
  }
  return days;
}

int notificationMaskFromWeekdays(Set<int> weekdays) {
  var mask = 0;
  for (final weekday in weekdays) {
    if (weekday >= 1 && weekday <= 7) mask |= 1 << (weekday - 1);
  }
  return mask;
}

NotificationRepeatPreset notificationPresetFromMask(int mask) {
  final normalized = mask & _allDaysMask;
  if (normalized == _allDaysMask) return NotificationRepeatPreset.everyDay;
  if (normalized == _weekdaysMask) return NotificationRepeatPreset.weekdays;
  return NotificationRepeatPreset.custom;
}

int notificationMaskForPreset(
  NotificationRepeatPreset preset, {
  required int customMask,
}) {
  switch (preset) {
    case NotificationRepeatPreset.everyDay:
      return _allDaysMask;
    case NotificationRepeatPreset.weekdays:
      return _weekdaysMask;
    case NotificationRepeatPreset.custom:
      return customMask & _allDaysMask;
  }
}

bool isValidNotificationRepeatMask(int mask) => (mask & _allDaysMask) != 0;

String notificationRepeatLabel(int mask) {
  switch (notificationPresetFromMask(mask)) {
    case NotificationRepeatPreset.everyDay:
      return 'Every day';
    case NotificationRepeatPreset.weekdays:
      return 'Mon–Fri';
    case NotificationRepeatPreset.custom:
      final days = notificationWeekdaysFromMask(mask);
      if (days.isEmpty) return 'No days selected';
      final sorted = days.toList()..sort();
      return sorted.map(notificationWeekdayLabel).join(', ');
  }
}

int notificationIdForWeekday(int weekday) =>
    notificationSummaryBaseId + weekday;

/// First local occurrence of [weekday] at [minuteOfDay] after [now].
/// Using `TZDateTime` in the device's local location keeps the wall-clock time
/// stable across daylight-saving transitions.
timezone.TZDateTime nextNotificationDate({
  required timezone.TZDateTime now,
  required int weekday,
  required int minuteOfDay,
}) {
  final delta = (weekday - now.weekday) % 7;
  var date = timezone.TZDateTime(
    timezone.local,
    now.year,
    now.month,
    now.day + delta,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );
  if (!date.isAfter(now)) {
    date = timezone.TZDateTime(
      timezone.local,
      date.year,
      date.month,
      date.day + 7,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
  }
  return date;
}
