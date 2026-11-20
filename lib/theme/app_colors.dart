import 'package:flutter/material.dart';

/// Single source of truth for ParkOps brand colors (previously duplicated in
/// homepage.dart and camera_pages.dart).
///
/// These constants are theme-independent brand accents. Theme-dependent
/// surfaces/text live in [AppPalette] and are resolved via `context.palette`.
class AppColors {
  static const navy = Color(0xFF0F1B2D);
  static const amber = Color(0xFFFDB833);
  static const mist = Color(0xFFAEB9C7);
  static const paper = Color(0xFFEDF1F5);
  static const ok = Color(0xFF3FA796);
  static const tight = Color(0xFFFDB833);
  static const full = Color(0xFFD96C5B);
  static const teal = Color(0xFF0E7C6B);
  static const tealLight = Color(0xFF2FB79B);
  static const tealSoft = Color(0xFFE1F1EC);
  static const line = Color(0xFFE6EAF0);
}

/// Semantic colors that change between light and dark mode.
///
/// Brand accents (amber, teal, status colors) stay the same in both themes so
/// the app keeps its identity; surfaces, text and dividers flip.
class AppPalette {
  const AppPalette({
    required this.navy,
    required this.paper,
    required this.mist,
    required this.line,
    required this.teal,
    required this.tealSoft,
    required this.card,
    required this.avatar,
    required this.navIndicator,
    required this.fieldFill,
  });

  /// Primary text / strongest foreground color.
  final Color navy;

  /// Scaffold and app bar background.
  final Color paper;

  /// Secondary text and muted foregrounds.
  final Color mist;

  /// Dividers and subtle borders.
  final Color line;

  /// Brand teal accent.
  final Color teal;

  /// Soft teal surface used for selected chips.
  final Color tealSoft;

  /// Card / raised surface background.
  final Color card;

  /// Avatar placeholder circle background.
  final Color avatar;

  /// Bottom navigation selected indicator.
  final Color navIndicator;

  /// Text-field / social-button fill.
  final Color fieldFill;

  static const light = AppPalette(
    navy: AppColors.navy,
    paper: AppColors.paper,
    mist: AppColors.mist,
    line: AppColors.line,
    teal: AppColors.teal,
    tealSoft: AppColors.tealSoft,
    card: Colors.white,
    avatar: Color(0xFFDDE4EC),
    navIndicator: Color(0xFFDDE4EC),
    fieldFill: Color(0xFFF5F6F8),
  );

  static const dark = AppPalette(
    navy: Color(0xFFE8EDF3),
    paper: Color(0xFF0C1420),
    mist: Color(0xFF8A97A8),
    line: Color(0xFF26313F),
    teal: Color(0xFF2FB79B),
    tealSoft: Color(0xFF16332D),
    card: Color(0xFF16202E),
    avatar: Color(0xFF26313F),
    navIndicator: Color(0xFF26313F),
    fieldFill: Color(0xFF1C2735),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension AppColorsX on BuildContext {
  /// Semantic palette for the current theme.
  AppPalette get palette => AppPalette.of(this);
}
