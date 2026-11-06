import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/core/providers.dart';
import 'package:pbl_parkops/features/settings/data/settings_preference_keys.dart';
import 'package:pbl_parkops/features/settings/presentation/pages/settings_page.dart';
import 'package:pbl_parkops/routes.dart';
import 'package:pbl_parkops/widgets/parkops_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings dropdown opens preferences and display controls', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          routes: Routes.all,
          home: const Scaffold(
            appBar: ParkOpsAppBar(section: 'Homepage', title: 'ParkOps'),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open profile menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Camera preferences'), findsOneWidget);
    expect(find.text('Detection overlay'), findsOneWidget);
    expect(find.text('Favorite lot'), findsOneWidget);
    expect(find.text('Daily notification'), findsOneWidget);
    expect(find.text('Send daily summary'), findsOneWidget);
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Theme preference'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('camera overlay and theme preference are saved locally', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('camera-overlay-setting')));
    await tester.pumpAndSettle();
    expect(
      preferences.getBool(SettingsPreferenceKeys.cameraOverlayEnabled),
      isFalse,
    );

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      preferences.getBool(SettingsPreferenceKeys.darkModeSelected),
      isTrue,
    );
  });
}
