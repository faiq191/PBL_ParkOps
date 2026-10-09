import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dummy_lots.dart';
import '../widgets/parkops_app_bar.dart';
import 'camera_pages.dart';
import 'map_pages.dart';

/// UI only: lots and counts are placeholders (see widgets/dummy_lots.dart).
class HomepagePages extends StatelessWidget {
  const HomepagePages({super.key});

  @override
  Widget build(BuildContext context) {
    final totalAvailable =
        dummyLots.fold<int>(0, (sum, l) => sum + l.available);
    final totalSlots = dummyLots.fold<int>(0, (sum, l) => sum + l.total);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'Homepage', title: 'ParkOps'),
      body: ValueListenableBuilder<int>(
        valueListenable: selectedLotIndex,
        builder: (_, idx, __) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _HeroCard(available: totalAvailable, total: totalSlots),
            const SizedBox(height: 18),
            _LotStatusCard(lot: dummyLots[idx]),
            const SizedBox(height: 18),
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
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const CameraPages()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExploreCard(
                    icon: Icons.map_outlined,
                    title: 'Parking map',
                    subtitle: 'Find an open bay',
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MapPages()),
                    ),
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
            for (int i = 0; i < dummyLots.length; i++)
              _LotRow(
                lot: dummyLots[i],
                selected: i == idx,
                onTap: () => selectedLotIndex.value = i,
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
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
  final DummyLot lot;
  const _LotStatusCard({required this.lot});

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
                    Text(lot.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(lot.location,
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
              Text('${lot.available}',
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ ${lot.total}',
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
              Text('${lot.occupiedCount} occupied',
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
  final DummyLot lot;
  final bool selected;
  final VoidCallback onTap;
  const _LotRow(
      {required this.lot, required this.selected, required this.onTap});

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
                  left: BorderSide(color: lot.statusColor, width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lot.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.navy)),
                      Text(lot.location,
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
                Text('${lot.available}/${lot.total}',
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
