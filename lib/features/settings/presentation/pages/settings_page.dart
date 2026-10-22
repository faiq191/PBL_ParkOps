import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/parking/data/seed_zones.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../data/settings_preference_keys.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _favoriteLotId = seedZones.first.id;
  bool _darkModeSelected = false;

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
    _darkModeSelected =
        preferences.getBool(SettingsPreferenceKeys.darkModeSelected) ?? false;
  }

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
