import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/theme/app_colors.dart';
import 'package:pbl_parkops/widgets/parkops_app_bar.dart';

void main() {
  testWidgets('profile menu uses themed background and icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: ParkOpsAppBar(section: 'PARKOPS', title: 'Home'),
        ),
      ),
    );

    final menuButton = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    expect(menuButton.color, AppColors.paper);
    expect(menuButton.position, PopupMenuPosition.under);
    expect(menuButton.offset, const Offset(-12, 8));

    await tester.tap(find.byTooltip('Open profile menu'));
    await tester.pumpAndSettle();

    final buttonRect = tester.getRect(find.byTooltip('Open profile menu'));
    final profileRect = tester.getRect(find.text('Profile'));
    expect(profileRect.top, greaterThanOrEqualTo(buttonRect.bottom));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });
}
