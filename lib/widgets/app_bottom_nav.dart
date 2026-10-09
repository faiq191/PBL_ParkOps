import 'package:flutter/material.dart';
import '../pages/camera_pages.dart';
import '../pages/homepage.dart' show HomepagePages;
import '../pages/map_pages.dart';
import '../theme/app_colors.dart';

/// Shared bottom bar. 0=Home, 1=Camera, 2=Map, 3=Info.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  void _go(BuildContext context, int i) {
    if (i == currentIndex) return;
    // Map tab index to a page; null means the page doesn't exist yet (Info)
    final Widget? page = switch (i) {
      0 => const HomepagePages(),
      1 => const CameraPages(),
      2 => const MapPages(),
      _ => null,
    };
    if (page == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Info page coming soon')));
      return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => page));
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
