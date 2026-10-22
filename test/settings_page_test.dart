import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/settings/presentation/pages/settings_page.dart';
import 'package:pbl_parkops/routes.dart';
import 'package:pbl_parkops/widgets/parkops_app_bar.dart';

void main() {
  testWidgets('settings dropdown item opens the blank settings page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: Routes.all,
        home: const Scaffold(
          appBar: ParkOpsAppBar(section: 'Homepage', title: 'ParkOps'),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open profile menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
}
