import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parking_zone.dart';
import '../providers/parking_provider.dart';
import 'camera_pages.dart';

class AppColors {
  static const navy = Color(0xFF0F1B2D);
  static const amber = Color(0xFFFDB833);
  static const mist = Color(0xFFAEB9C7);
  static const paper = Color(0xFFEDF1F5);
  static const ok = Color(0xFF3FA796);
  static const tight = Color(0xFFFDB833);
  static const full = Color(0xFFD96C5B);
  static const teal = Color(0xFF0E7C6B);
  static const tealSoft = Color(0xFFE1F1EC);
  static const line = Color(0xFFE6EAF0);
}

class HomepagePages extends ConsumerWidget {
  const HomepagePages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Homepage',
              style: TextStyle(fontSize: 11, color: AppColors.mist),
            ),
            SizedBox(height: 2),
            Text(
              'ParkOps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 24, 25, 25), // teal terang (kiri atas)
                    Color.fromARGB(60, 20, 12, 92), // teal gelap (kanan bawah)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_parking, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load: $err')),
        data: (zones) {
          final totalAvailable = zones.fold<int>(
            0,
            (sum, z) => sum + z.availableSlots,
          );
          final totalSlots = zones.fold<int>(0, (sum, z) => sum + z.totalSlots);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _HeroCard(available: totalAvailable, total: totalSlots),
              const SizedBox(height: 18),
              if (zones.isNotEmpty) ...[
                _ZoneStatusCard(zone: zones.first),
                const SizedBox(height: 18),
              ],
              const Text(
                'Explore the lot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ExploreCard(
                      icon: Icons.videocam_outlined,
                      title: 'Camera view',
                      subtitle: 'See delayed detection',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExploreCard(
                      icon: Icons.map_outlined,
                      title: 'Parking map',
                      subtitle: 'Find an open bay',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              ...zones.map((zone) => _ZoneRow(zone: zone)),
            ],
          );
        },
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int available;
  final int total;
  const _HeroCard({required this.available, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available slots right now',
            style: TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'out of $total total slots',
            style: const TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.circle, size: 6, color: AppColors.amber),
              SizedBox(width: 6),
              Text(
                'Updated just now',
                style: TextStyle(color: AppColors.amber, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final ParkingZone zone;
  const _ZoneRow({required this.zone});

  Color get _borderColor {
    switch (zone.status) {
      case 'full':
        return AppColors.full;
      case 'tight':
        return AppColors.tight;
      default:
        return AppColors.ok;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _borderColor, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.navy,
                ),
              ),
              Text(
                zone.location,
                style: const TextStyle(fontSize: 10, color: Color(0xFF8892A0)),
              ),
            ],
          ),
          Text(
            '${zone.availableSlots}/${zone.totalSlots}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneStatusCard extends StatelessWidget {
  final ParkingZone zone;
  const _ZoneStatusCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final delayMin = DateTime.now()
        .difference(zone.lastUpdated)
        .inMinutes
        .abs();
    final delayText = delayMin <= 0 ? 'live' : '$delayMin min delay';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mist,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      delayText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${zone.availableSlots}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${zone.totalSlots}',
                  style: const TextStyle(fontSize: 18, color: AppColors.mist),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'spaces available in latest feed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${zone.occupiedSlots} occupied',
                style: const TextStyle(fontSize: 12, color: AppColors.mist),
              ),
              Text(
                'Camera delayed by $delayText',
                style: const TextStyle(fontSize: 12, color: AppColors.mist),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: AppColors.navy, size: 22),
                  const Icon(Icons.north_east, color: AppColors.navy, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 68,
      backgroundColor: AppColors.paper,
      onDestinationSelected: (i) {
        if (i == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CameraPages()),
          );
        }
        // TODO: 2=Map, 3=Info
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.videocam_outlined),
          label: 'Camera',
        ),
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
        NavigationDestination(icon: Icon(Icons.info_outline), label: 'Info'),
      ],
    );
  }
}
