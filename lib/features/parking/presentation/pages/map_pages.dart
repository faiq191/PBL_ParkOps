import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_zone.dart';
import '../providers/parking_providers.dart';
import '../widgets/lot_chips.dart';
import '../widgets/placeholder_bays.dart';

/// UI only: bay layout and counts are placeholders.
class MapPages extends ConsumerWidget {
  const MapPages({super.key});

  static const _cols = 12; // same grid as the camera page

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'Map', title: 'Find Your Space'),
      body: zonesAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Center(
          child: Text(e is Failure ? e.message : 'Could not load parking zones'),
        ),
        // Rebuild whenever the selected zone changes (DV-3: selection is
        // Riverpod state in parking_providers.dart)
        data: (_) {
          final zone = ref.watch(selectedZoneProvider);
          if (zone == null) {
            return const Center(child: Text('No parking zones yet'));
          }
          // Real per-bay occupancy when the zone's 'slots' subcollection has
          // documents; otherwise the placeholder pattern from the zone counts.
          final slots = ref.watch(slotsStreamProvider(zone.id)).value ??
              const <ParkingSlot>[];
          final occupied = baysFor(zone, slots);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              const LotChips(),
              const SizedBox(height: 12),
              _mapCard(context, zone, occupied),
              const SizedBox(height: 14),
              _cameraButton(context),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _mapCard(BuildContext context, ParkingZone zone, List<bool> occupied) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    Text(zone.location,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mist)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: zone.availableSlots == 0
                      ? const Color(0xFFF8E3E0)
                      : AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                    zone.availableSlots == 0
                        ? 'Full'
                        : '${zone.availableSlots} spaces available',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: zone.availableSlots == 0
                            ? AppColors.full
                            : AppColors.teal)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (zone.availableSlots > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.near_me, size: 14, color: AppColors.teal),
                  const SizedBox(width: 6),
                  // First free bay = first index holding false; +1 to display as 1-based
                  Text('First free bay: ${occupied.indexOf(false) + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Grid rows = total slots divided by columns, rounded up
                for (int r = 0; r < (occupied.length / _cols).ceil(); r++)
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        for (int c = 0; c < _cols; c++)
                          Expanded(
                            child: r * _cols + c < occupied.length
                                ? _MapBay(
                                    index: r * _cols + c,
                                    occupied: occupied[r * _cols + c],
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: AppColors.ok, label: 'Available'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFB8C1CC), label: 'Occupied'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cameraButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () =>
            Navigator.of(context).pushReplacementNamed(Routes.camera),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 6),
            Text('View this area on camera',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Spacer(),
            Icon(Icons.videocam_outlined, size: 20),
            SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _MapBay extends StatelessWidget {
  final int index;
  final bool occupied;
  const _MapBay({required this.index, required this.occupied});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
              'Bay ${index + 1}: ${occupied ? 'occupied' : 'available'}'),
        )),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            // Free bays are solid green so they pop; occupied are muted grey.
            color: occupied ? const Color(0xFFD5DBE3) : AppColors.ok,
          ),
          child: Center(
            child: occupied
                ? null
                : Text('${index + 1}',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.navy)),
      ],
    );
  }
}
