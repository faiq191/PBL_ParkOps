import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parking_zone.dart';
import '../providers/parking_provider.dart';

class AppColors {
  static const navy = Color(0xFF0F1B2D);
  static const amber = Color(0xFFFDB833);
  static const mist = Color(0xFFAEB9C7);
  static const paper = Color(0xFFEDF1F5);
  static const ok = Color(0xFF3FA796);
  static const tight = Color(0xFFFDB833);
  static const full = Color(0xFFD96C5B);
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
        title: const Text(
          'ParkOps',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.location_on, color: AppColors.navy),
          ),
        ],
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load: $err')),
        data: (zones) {
          final totalAvailable =
              zones.fold<int>(0, (sum, z) => sum + z.availableSlots);
          final totalSlots =
              zones.fold<int>(0, (sum, z) => sum + z.totalSlots);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _HeroCard(available: totalAvailable, total: totalSlots),
              const SizedBox(height: 18),
              const Text(
                'PARKING ZONES',
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
          const Text('Available slots right now',
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
          Row(
            children: const [
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
              Text(zone.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.navy)),
              Text(zone.location,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8892A0))),
            ],
          ),
          Text('${zone.availableSlots}/${zone.totalSlots}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}