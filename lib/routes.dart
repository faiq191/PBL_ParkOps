import 'package:flutter/material.dart';

import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/auth/presentation/pages/login_pages.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/information/presentation/pages/information_pages.dart';
import 'features/onboarding/presentation/pages/onboarding_pages.dart';
import 'features/parking/presentation/pages/camera_pages.dart';
import 'features/parking/presentation/pages/map_pages.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

/// Central route table (DV-3 fix): this is the only file that imports pages.
/// Pages navigate through these names instead of importing each other, which
/// removes the old widgets → pages outward arrow and the camera ↔ map
/// circular import.
class Routes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const camera = '/camera';
  static const map = '/map';
  static const info = '/info';
  static const admin = '/admin';
  static const login = '/login';
  static const register = '/register';
  static const settings = '/settings';
  static const profile = '/profile';

  static final Map<String, WidgetBuilder> all = {
    onboarding: (_) => const OnboardingPages(),
    camera: (_) => const CameraPages(),
    map: (_) => const MapPages(),
    info: (_) => const InformationPages(),
    admin: (_) => const AdminDashboardPage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    settings: (_) => const SettingsPage(),
    profile: (_) => const ProfilePage(),
  };
}
