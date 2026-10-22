import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/parking/data/seed_zones.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../data/parking_notification_service.dart';
import '../../data/settings_preference_keys.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _favoriteLotId = seedZones.first.id;
  bool _dailyNotificationEnabled = false;
  int _notificationMinuteOfDay = 8 * 60;
  bool _darkModeSelected = false;
  bool _savingNotification = false;

  @override
  void initState() {
    super.initState();
    final preferences = ref.read(sharedPreferencesProvider);
    _favoriteLotId =
        preferences.getString(SettingsPreferenceKeys.favoriteLotId) ??
        seedZones.first.id;
    if (!seedZones.any((zone) => zone.id == _favoriteLotId)) {
      _favoriteLotId = seedZones.first.id;
    }
    _dailyNotificationEnabled =
        preferences.getBool(SettingsPreferenceKeys.dailyNotificationEnabled) ??
        false;
    _notificationMinuteOfDay =
        preferences.getInt(SettingsPreferenceKeys.notificationMinuteOfDay) ??
        8 * 60;
    _darkModeSelected =
        preferences.getBool(SettingsPreferenceKeys.darkModeSelected) ?? false;
  }

  TimeOfDay get _notificationTime => TimeOfDay(
    hour: _notificationMinuteOfDay ~/ 60,
    minute: _notificationMinuteOfDay % 60,
  );

  Future<void> _setCameraOverlay(bool enabled) async {
    final saved = await ref
        .read(cameraOverlayPreferenceProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    if (!saved) {
      _showMessage('Could not save the camera preference.');
      return;
    }
  }

  Future<void> _setFavoriteLot(String? lotId) async {
    if (lotId == null) return;
    if (_dailyNotificationEnabled) {
      await _saveNotificationSettings(
        favoriteLotId: lotId,
        minuteOfDay: _notificationMinuteOfDay,
      );
      return;
    }
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setString(SettingsPreferenceKeys.favoriteLotId, lotId);
    if (!mounted) return;
    if (!saved) {
      _showMessage('Could not save your favorite lot.');
      return;
    }
    setState(() => _favoriteLotId = lotId);
  }

  Future<void> _chooseNotificationTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (selected == null || !mounted) return;
    final minuteOfDay = selected.hour * 60 + selected.minute;
    if (_dailyNotificationEnabled) {
      await _saveNotificationSettings(
        favoriteLotId: _favoriteLotId,
        minuteOfDay: minuteOfDay,
      );
      return;
    }
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setInt(SettingsPreferenceKeys.notificationMinuteOfDay, minuteOfDay);
    if (!mounted) return;
    if (!saved) {
      _showMessage('Could not save the notification time.');
      return;
    }
    setState(() => _notificationMinuteOfDay = minuteOfDay);
  }

  Future<void> _toggleDailyNotification(bool enabled) async {
    if (!enabled) {
      setState(() => _savingNotification = true);
      try {
        await ParkingNotificationService.instance.cancelDailySummary();
        if (!mounted) return;
        final saved = await ref
            .read(sharedPreferencesProvider)
            .setBool(SettingsPreferenceKeys.dailyNotificationEnabled, false);
        if (!saved) {
          _showMessage('Could not save the notification preference.');
          return;
        }
        setState(() => _dailyNotificationEnabled = false);
      } on PlatformException catch (error) {
        _showMessage('Could not cancel the notification: ${error.message}');
      } on UnsupportedError catch (error) {
        _showMessage(error.message ?? 'Notifications are not supported here.');
      } on StateError catch (error) {
        _showMessage(error.message);
      } finally {
        if (mounted) setState(() => _savingNotification = false);
      }
      return;
    }

    await _saveNotificationSettings(
      favoriteLotId: _favoriteLotId,
      minuteOfDay: _notificationMinuteOfDay,
      enableAfterSave: true,
    );
  }

  Future<void> _saveNotificationSettings({
    required String favoriteLotId,
    required int minuteOfDay,
    bool enableAfterSave = false,
  }) async {
    setState(() => _savingNotification = true);
    try {
      final notificationService = ParkingNotificationService.instance;
      if (enableAfterSave) {
        final permitted = await notificationService.requestPermission();
        if (!mounted) return;
        if (!permitted) {
          _showMessage(
            'Allow notifications and scheduled alarms in device settings to receive daily updates.',
          );
          return;
        }
      }
      await notificationService.scheduleDailySummary(
        favoriteLotId: favoriteLotId,
        minuteOfDay: minuteOfDay,
      );
      if (!mounted) return;
      final preferences = ref.read(sharedPreferencesProvider);
      final favoriteSaved = await preferences.setString(
        SettingsPreferenceKeys.favoriteLotId,
        favoriteLotId,
      );
      final timeSaved = await preferences.setInt(
        SettingsPreferenceKeys.notificationMinuteOfDay,
        minuteOfDay,
      );
      final enabledSaved = enableAfterSave
          ? await preferences.setBool(
              SettingsPreferenceKeys.dailyNotificationEnabled,
              true,
            )
          : true;
      if (!favoriteSaved || !timeSaved || !enabledSaved) {
        _showMessage('Could not save all notification preferences.');
        return;
      }
      setState(() {
        _favoriteLotId = favoriteLotId;
        _notificationMinuteOfDay = minuteOfDay;
        _dailyNotificationEnabled = true;
      });
    } on PlatformException catch (error) {
      _showMessage('Could not schedule the notification: ${error.message}');
    } on UnsupportedError catch (error) {
      _showMessage(error.message ?? 'Notifications are not supported here.');
    } on StateError catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _savingNotification = false);
    }
  }

  Future<void> _setDarkMode(bool isDark) async {
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setBool(SettingsPreferenceKeys.darkModeSelected, isDark);
    if (!mounted) return;
    if (!saved) {
      _showMessage('Could not save the display preference.');
      return;
    }
    // This preference is stored for later; applying an app-wide theme is not
    // included until the existing screens support dark and light themes.
    setState(() => _darkModeSelected = isDark);
  }

  Future<void> _logout() async {
    final error = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cameraOverlayEnabled = ref.watch(cameraOverlayPreferenceProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'PARKOPS', title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          _sectionTitle('Preferences'),
          _settingsCard([
            const ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                'Camera preferences',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SwitchListTile(
              key: const ValueKey('camera-overlay-setting'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Detection overlay',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Show bay detection on the camera view'),
              value: cameraOverlayEnabled,
              activeTrackColor: AppColors.navy,
              onChanged: _setCameraOverlay,
            ),
            const Divider(height: 1, color: AppColors.line),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Favorite lot',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Used for your daily parking summary'),
              trailing: DropdownButton<String>(
                key: const ValueKey('favorite-lot-setting'),
                value: _favoriteLotId,
                // WIP: replace seedZones with zonesStreamProvider when the
                // parking-lot choices are backed by Firebase.
                items: [
                  for (final zone in seedZones)
                    DropdownMenuItem(value: zone.id, child: Text(zone.name)),
                ],
                onChanged: _setFavoriteLot,
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            ListTile(
              key: const ValueKey('notification-time-setting'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Daily notification',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Local demo availability for now'),
              trailing: TextButton(
                onPressed: _savingNotification ? null : _chooseNotificationTime,
                child: Text(_notificationTime.format(context)),
              ),
            ),
            SwitchListTile(
              key: const ValueKey('daily-notification-setting'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Send daily summary',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _dailyNotificationEnabled,
              activeTrackColor: AppColors.navy,
              onChanged: _savingNotification ? null : _toggleDailyNotification,
            ),
          ]),
          const SizedBox(height: 22),
          _sectionTitle('Display'),
          _settingsCard([
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Theme preference',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Saved for later; does not change the app theme yet',
              ),
              trailing: SegmentedButton<bool>(
                key: const ValueKey('theme-preference-setting'),
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {_darkModeSelected},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    _setDarkMode(selection.first),
              ),
            ),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const ValueKey('logout-setting'),
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.full,
                side: const BorderSide(color: AppColors.full),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _settingsCard(List<Widget> children) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: children),
    ),
  );
}
