import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../domain/entities/parking_zone.dart';
import '../providers/parking_providers.dart';
import '../widgets/zone_status_color.dart';

/// UI only: lots and counts are placeholders (demo fallback lives in
/// features/parking/data/seed_zones.dart until Firestore is seeded).
class HomepagePages extends ConsumerWidget {
  const HomepagePages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'Homepage', title: 'ParkOps'),
      body: zonesAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Center(
          child: Text(e is Failure ? e.message : 'Could not load parking zones'),
        ),
        data: (_) => const _HomepageBody(),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

/// Home tab body. Rebuilds automatically whenever the selected zone changes
/// (DV-3: selection is now Riverpod state in parking_providers.dart).
class _HomepageBody extends ConsumerWidget {
  const _HomepageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aggregate free and total slots across all zones for the hero card
    final totals = ref.watch(zoneTotalsProvider);
    final zones = ref.watch(zonesListProvider);
    final selectedZone = ref.watch(selectedZoneProvider);
    final selectedId = ref.watch(selectedZoneIdProvider);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _HeroCard(available: totals.available, total: totals.total),
        const SizedBox(height: 18),
        if (selectedZone != null) ...[
          _LotStatusCard(zone: selectedZone),
          const SizedBox(height: 18),
        ],
        const Text('Explore the lot',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ExploreCard(
                icon: Icons.videocam_outlined,
                title: 'Camera view',
                subtitle: 'See delayed detection',
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed(Routes.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExploreCard(
                icon: Icons.map_outlined,
                title: 'Parking map',
                subtitle: 'Find an open bay',
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed(Routes.map),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Parking lots',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 10),
        for (final zone in zones)
          _LotRow(
            zone: zone,
            selected: zone.id == selectedId,
            // Update the selected-zone state so Camera & Map tabs follow the selection
            onTap: () =>
                ref.read(selectedZoneIdProvider.notifier).select(zone.id),
          ),
      ],
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
          const Text('Available slots across all lots',
              style: TextStyle(color: AppColors.mist, fontSize: 12)),
          const SizedBox(height: 4),
          Text('$available',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          Text('out of $total total slots',
              style: const TextStyle(color: AppColors.mist, fontSize: 12)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.circle, size: 6, color: AppColors.amber),
              SizedBox(width: 6),
              Text('Updated just now',
                  style: TextStyle(color: AppColors.amber, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LotStatusCard extends StatelessWidget {
  final ParkingZone zone;
  const _LotStatusCard({required this.zone});

  @override
  Widget build(BuildContext context) {
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
                    Text(zone.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(zone.location,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.mist)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: AppColors.teal),
                    SizedBox(width: 6),
                    Text('1 min delay',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${zone.availableSlots}',
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ ${zone.totalSlots}',
                    style: const TextStyle(
                        fontSize: 18, color: AppColors.mist)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('spaces available in latest feed',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal)),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${zone.occupiedSlots} occupied',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.mist)),
              const Text('Camera delayed by 1 min',
                  style: TextStyle(fontSize: 12, color: AppColors.mist)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LotRow extends StatelessWidget {
  final ParkingZone zone;
  final bool selected;
  final VoidCallback onTap;
  const _LotRow({
    required this.zone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                  left: BorderSide(color: zone.status.color, width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.navy)),
                      Text(zone.location,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8892A0))),
                    ],
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.check_circle,
                        size: 16, color: AppColors.navy),
                  ),
                Text('${zone.availableSlots}/${zone.totalSlots}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.navy)),
              ],
            ),
          ),
        ),
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
                  const Icon(Icons.north_east,
                      color: AppColors.navy, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.mist)),
            ],
          ),
        ),
      ),
    );
  }
}
