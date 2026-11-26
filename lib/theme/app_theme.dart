import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the app-wide [ThemeData] for light and dark mode.
///
/// The schemes are seeded from the ParkOps navy brand color; the remaining
/// surfaces are pinned to [AppPalette] so widgets can rely on `context.palette`
/// matching the framework's `ColorScheme`.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final onAccent = brightness == Brightness.dark
        ? AppColors.navy
        : Colors.white;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: brightness,
        ).copyWith(
          primary: palette.navy,
          onPrimary: palette.paper,
          secondary: AppColors.amber,
          onSecondary: AppColors.navy,
          surface: palette.paper,
          onSurface: palette.navy,
          error: AppColors.full,
          onError: onAccent,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.paper,
      dividerColor: palette.line,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.paper,
        foregroundColor: palette.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: palette.paper,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.paper,
        indicatorColor: palette.navIndicator,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: palette.card, elevation: 0),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.paper,
        surfaceTintColor: palette.paper,
      ),
    );
  }
}
