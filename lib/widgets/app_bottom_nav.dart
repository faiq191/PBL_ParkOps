import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_colors.dart';

/// Shared bottom bar. 0=Home, 1=Camera, 2=Map, 3=Info.
/// DV-3 fix: navigates through named routes (routes.dart) instead of
/// importing the page classes, so this widget no longer points outward.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  void _go(BuildContext context, int i) {
    if (i == currentIndex) return;
    // Map tab index to a route; null means the page doesn't exist yet
    final String? route = switch (i) {
      0 => Routes.home,
      1 => Routes.camera,
      2 => Routes.map,
      3 => Routes.info,
      _ => null,
    };
    if (route == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Info page coming soon')));
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 68,
      backgroundColor: AppColors.paper,
      indicatorColor: const Color(0xFFDDE4EC),
      onDestinationSelected: (i) => _go(context, i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.videocam_outlined),
          selectedIcon: Icon(Icons.videocam),
          label: 'Camera',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Map',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline),
          selectedIcon: Icon(Icons.info),
          label: 'Info',
        ),
      ],
    );
  }
}
