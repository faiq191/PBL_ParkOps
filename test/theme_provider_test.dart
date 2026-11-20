import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/core/providers.dart';
import 'package:pbl_parkops/features/settings/data/settings_preference_keys.dart';
import 'package:pbl_parkops/features/settings/presentation/providers/settings_providers.dart';
import 'package:pbl_parkops/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark mode preference defaults to light and persists changes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(darkModePreferenceProvider), isFalse);

    final saved = await container
        .read(darkModePreferenceProvider.notifier)
        .setEnabled(true);

    expect(saved, isTrue);
    expect(container.read(darkModePreferenceProvider), isTrue);
    expect(
      preferences.getBool(SettingsPreferenceKeys.darkModeSelected),
      isTrue,
    );
  });

  test('dark mode preference restores a persisted value on build', () async {
    SharedPreferences.setMockInitialValues({
      SettingsPreferenceKeys.darkModeSelected: true,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(darkModePreferenceProvider), isTrue);
  });

  test('AppTheme exposes matching light and dark themes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.scaffoldBackgroundColor,
        isNot(AppTheme.dark.scaffoldBackgroundColor));
  });
}
