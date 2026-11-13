import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../data/camera_feeds.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_zone.dart';
import '../providers/parking_providers.dart';
import '../widgets/format_time.dart';
import '../widgets/lot_chips.dart';
import '../widgets/placeholder_bays.dart';

/// Map tab. Laid out like the Camera tab: a lot-picker card, a row of
/// Available / Occupied / Total stat cards, an info card, and a button that
/// jumps to the other tab.
class MapPages extends ConsumerWidget {
  const MapPages({super.key});

  static const _cols = 12; // bays per row in the grid

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
          child: Text(
            e is Failure ? e.message : 'Could not load parking zones',
          ),
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
          final slots =
              ref.watch(slotsStreamProvider(zone.id)).value ??
              const <ParkingSlot>[];
          final occupied = baysFor(zone, slots);
          return _buildBody(context, ref, zone, occupied, slots.isNotEmpty);
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ParkingZone zone,
    List<bool> occupied,
    bool hasRealBays,
  ) {
    // Stats come from the same list that draws the grid, so the numbers and
    // the bays on screen always agree.
    final total = occupied.length;
    final occupiedCount = occupied.where((o) => o).length;
    final available = total - occupiedCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _mapCard(ref, zone, occupied),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: available.toString(),
                label: 'Available',
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: occupiedCount.toString(),
                label: 'Occupied',
                color: AppColors.full,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: total.toString(),
                label: 'Total bays',
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _infoCard(zone, occupied, hasRealBays),
        const SizedBox(height: 16),
        _cameraButton(context),
      ],
    );
  }

  Widget _mapCard(WidgetRef ref, ParkingZone zone, List<bool> occupied) {
    // Lots listed in the card dropdown
    final zones = ref.watch(zonesListProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.navy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lot picker: switching lots swaps the bay grid and the
                      // counts to the chosen lot.
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: zone.id,
                          isExpanded: true,
                          isDense: true,
                          borderRadius: BorderRadius.circular(10),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.navy,
                          ),
                          items: [
                            for (final z in zones)
                              DropdownMenuItem(
                                value: z.id,
                                child: Text(
                                  zones.indexOf(z) < cameraFeeds.length
                                      ? cameraFeeds[zones.indexOf(z)].title
                                      : z.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: (id) {
                            if (id != null) {
                              ref
                                  .read(selectedZoneIdProvider.notifier)
                                  .select(id);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        zone.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mist,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bay grid sits edge to edge in the card, like the camera preview.
          Container(
            width: double.infinity,
            color: AppColors.paper,
            padding: const EdgeInsets.all(10),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _LegendDot(color: AppColors.ok, label: 'Available'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFFD5DBE3), label: 'Occupied'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(ParkingZone zone, List<bool> occupied, bool hasRealBays) {
    final firstFree = occupied.indexOf(false);
    final isFull = firstFree == -1;

    final String heading = isFull
        ? 'This lot is full'
        : 'First free bay: ${firstFree + 1}';
    final IconData icon = isFull ? Icons.info_outline : Icons.near_me;
    final String detail = isFull
        ? 'No free bays right now. Pick another lot from the dropdown.'
        : hasRealBays
        ? 'Bay status updates automatically.'
        : 'Bay layout is estimated from the lot counts until per-bay data '
              'is available.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.navy, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$detail Last update: ${formatTimestamp(zone.lastUpdated)}.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mist,
              height: 1.4,
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(width: 6),
            Text(
              'View this area on camera',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
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
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              'Bay ${index + 1}: ${occupied ? 'occupied' : 'available'}',
            ),
          ),
        ),
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
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.navy),
        ),
      ],
    );
  }
}
