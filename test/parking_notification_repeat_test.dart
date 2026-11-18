import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/settings/data/notification_repeat.dart';
import 'package:pbl_parkops/features/settings/data/settings_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

void main() {
  setUpAll(() {
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Jakarta'));
  });

  group('repeat presets and bitmask', () {
    test('maps presets to the expected masks', () {
      expect(everyDayNotificationRepeatMask, 0x7F);
      expect(weekdaysNotificationRepeatMask, 0x1F);
      expect(
        notificationMaskForPreset(
          NotificationRepeatPreset.everyDay,
          customMask: 0,
        ),
        127,
      );
      expect(
        notificationMaskForPreset(
          NotificationRepeatPreset.weekdays,
          customMask: 127,
        ),
        31,
      );
      expect(
        notificationMaskForPreset(
          NotificationRepeatPreset.custom,
          customMask: 85,
        ),
        85,
      );
    });

    test('detects a preset from a stored mask', () {
      expect(
        notificationPresetFromMask(127),
        NotificationRepeatPreset.everyDay,
      );
      expect(notificationPresetFromMask(31), NotificationRepeatPreset.weekdays);
      expect(notificationPresetFromMask(85), NotificationRepeatPreset.custom);
    });

    test('supports selecting several days and deselecting one', () {
      var mask = 0;
      mask |= 1 << (1 - 1); // Mon
      mask |= 1 << (3 - 1); // Wed
      mask |= 1 << (5 - 1); // Fri
      expect(notificationWeekdaysFromMask(mask), {1, 3, 5});

      mask &= ~(1 << (3 - 1)); // deselect Wed
      expect(notificationWeekdaysFromMask(mask), {1, 5});
      expect(notificationMaskFromWeekdays({1, 5}), mask);
    });

    test('handles all days and rejects an empty selection', () {
      final allDays = notificationMaskFromWeekdays({1, 2, 3, 4, 5, 6, 7});
      expect(allDays, 127);
      expect(notificationWeekdaysFromMask(allDays).length, 7);
      expect(isValidNotificationRepeatMask(allDays), isTrue);

      expect(isValidNotificationRepeatMask(0), isFalse);
      expect(notificationWeekdaysFromMask(0), isEmpty);
      // Bits outside Monday..Sunday cannot create a valid schedule.
      expect(isValidNotificationRepeatMask(1 << 8), isFalse);
    });

    test('uses English Sunday-first chip labels', () {
      expect(notificationWeekdayLabels, [
        'Sun',
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
      ]);
      expect(notificationWeekdayFromChipIndex(0), 7);
      expect(notificationWeekdayFromChipIndex(1), 1);
      expect(notificationWeekdayFromChipIndex(6), 6);
      expect(notificationWeekdayLabel(7), 'Sun');
      expect(notificationWeekdayLabel(1), 'Mon');
    });

    test('builds readable preset labels', () {
      expect(notificationRepeatLabel(127), 'Every day');
      expect(notificationRepeatLabel(31), 'Mon–Fri');
      expect(notificationRepeatLabel(85), 'Mon, Wed, Fri, Sun');
      expect(notificationRepeatLabel(0), 'No days selected');
    });
  });

  group('schedule ids', () {
    test('uses one unique id per weekday without reusing the legacy id', () {
      final ids = {
        for (var weekday = 1; weekday <= 7; weekday++)
          notificationIdForWeekday(weekday),
      };
      expect(ids.length, 7);
      expect(notificationIdForWeekday(1), notificationSummaryBaseId + 1);
      expect(ids.contains(notificationSummaryBaseId), isFalse);
      expect(
        ids.reduce((a, b) => a > b ? a : b),
        notificationSummaryBaseId + 7,
      );
    });
  });

  group('nextNotificationDate', () {
    timezone.TZDateTime at(int day, int hour, [int minute = 0]) =>
        timezone.TZDateTime(timezone.local, 2026, 11, day, hour, minute);

    test('picks the next selected weekday before the configured time', () {
      // 18 Nov 2026 is a Wednesday.
      final now = at(18, 9);
      expect(now.weekday, 3);

      final friday = nextNotificationDate(
        now: now,
        weekday: 5,
        minuteOfDay: 8 * 60,
      );
      expect(friday, at(20, 8));
      expect(friday.weekday, 5);

      final monday = nextNotificationDate(
        now: now,
        weekday: 1,
        minuteOfDay: 8 * 60,
      );
      expect(monday, at(23, 8));
      expect(monday.weekday, 1);

      final sunday = nextNotificationDate(
        now: now,
        weekday: 7,
        minuteOfDay: 8 * 60,
      );
      expect(sunday, at(22, 8));
      expect(sunday.weekday, 7);
    });

    test('rolls to the following week when today is already past the time', () {
      final now = at(18, 9);
      final nextWednesday = nextNotificationDate(
        now: now,
        weekday: 3,
        minuteOfDay: 8 * 60,
      );
      expect(nextWednesday, at(25, 8));
      expect(nextWednesday.weekday, 3);
      expect(nextWednesday.isAfter(now), isTrue);
    });

    test('crosses midnight and the week boundary correctly', () {
      final lateWednesday = at(18, 23, 30);
      final thursdayMidnight = nextNotificationDate(
        now: lateWednesday,
        weekday: 4,
        minuteOfDay: 0,
      );
      expect(thursdayMidnight, at(19, 0));

      final sunday = at(22, 9);
      final nextMonday = nextNotificationDate(
        now: sunday,
        weekday: 1,
        minuteOfDay: 8 * 60,
      );
      expect(nextMonday, at(23, 8));
      expect(nextMonday.weekday, 1);
    });
  });

  test('repeat days survive a SharedPreferences reopen', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance().then(
      (preferences) =>
          preferences.setInt(SettingsPreferenceKeys.notificationRepeatDays, 85),
    );

    final reopened = await SharedPreferences.getInstance();
    final stored = reopened.getInt(
      SettingsPreferenceKeys.notificationRepeatDays,
    );
    expect(stored, 85);
    expect(notificationWeekdaysFromMask(stored ?? 0), {1, 3, 5, 7});
  });
}
