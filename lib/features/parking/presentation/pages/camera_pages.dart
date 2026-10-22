import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_zone.dart';
import '../providers/parking_providers.dart';
import '../widgets/lot_chips.dart';
import '../widgets/placeholder_bays.dart';

/// UI only: the feed and counts are placeholders.
class CameraPages extends ConsumerStatefulWidget {
  const CameraPages({super.key});

  @override
  ConsumerState<CameraPages> createState() => _CameraPagesState();
}

class _CameraPagesState extends ConsumerState<CameraPages> {
  Future<void> _setOverlay(bool enabled) async {
    final saved = await ref
        .read(cameraOverlayPreferenceProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save the camera preference.'),
          ),
        );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesStreamProvider);
    final overlayEnabled = ref.watch(cameraOverlayPreferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(
        section: 'Camera',
        title: 'Parking Lot Camera',
      ),
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
        data: (_) => _buildBody(overlayEnabled),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(bool overlayEnabled) {
    final zone = ref.watch(selectedZoneProvider);
    if (zone == null) {
      return const Center(child: Text('No parking zones yet'));
    }
    // Real per-bay occupancy when the zone's 'slots' subcollection has
    // documents; otherwise the placeholder pattern from the zone counts.
    final slots =
        ref.watch(slotsStreamProvider(zone.id)).value ?? const <ParkingSlot>[];
    final occupied = baysFor(zone, slots);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _cameraCard(zone, occupied, overlayEnabled),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${zone.availableSlots}',
                label: 'Available',
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${zone.occupiedSlots}',
                label: 'Occupied',
                color: AppColors.full,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${zone.totalSlots}',
                label: 'Total bays',
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _infoCard(),
        const SizedBox(height: 16),
        _mapButton(),
      ],
    );
  }

  Widget _cameraCard(
    ParkingZone zone,
    List<bool> occupied,
    bool overlayEnabled,
  ) {
    // Lots listed in the camera header dropdown
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
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.videocam_outlined,
                  color: AppColors.navy,
                  size: 20,
                ),
                const SizedBox(width: 8),
                // Lot picker: switching lots swaps the camera feed and the
                // counts to the chosen lot.
                Expanded(
                  child: DropdownButtonHideUnderline(
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
                              '${z.cameraImageUrl}  -  ${z.name}',
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
                          ref.read(selectedZoneIdProvider.notifier).select(id);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _DummyCameraFeed(
            zone: zone,
            occupied: occupied,
            showOverlay: overlayEnabled,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Detection overlay',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                Switch(
                  // Toggle the detection overlay on top of the camera feed
                  value: overlayEnabled,
                  activeTrackColor: AppColors.navy,
                  onChanged: _setOverlay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: AppColors.navy, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Camera delayed by 1 minute',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Counts reflect the camera feed from 1 minute ago. '
            'Outlined bays show available and occupied spaces.',
            style: TextStyle(fontSize: 11, color: AppColors.mist, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _mapButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.map),
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
              'Find a space on the map',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Spacer(),
            Icon(Icons.map_outlined, size: 20),
            SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

// Placeholder "feed": dark box with a 4x12 grid of bays.
class _DummyCameraFeed extends StatelessWidget {
  final ParkingZone zone;
  final List<bool> occupied;
  final bool showOverlay;
  const _DummyCameraFeed({
    required this.zone,
    required this.occupied,
    required this.showOverlay,
  });

  // Number of bay columns in the feed grid; must match the grid on the Map page
  static const _cols = 12;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: const Color(0xFF4A4F55),
        child: Stack(
          children: [
            if (showOverlay)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Grid rows = total slots divided by columns, rounded up
                    for (int r = 0; r < (occupied.length / _cols).ceil(); r++)
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            for (int c = 0; c < _cols; c++) ...[
                              if (c > 0) const SizedBox(width: 3),
                              Expanded(
                                child: r * _cols + c < occupied.length
                                    ? _Bay(occupied: occupied[r * _cols + c])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              top: 10,
              left: 10,
              child: _pill(
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF7FD8C8)),
                    SizedBox(width: 6),
                    Text(
                      '1 min delay',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _pill(
                const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                square: true,
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: _pill(
                Text(
                  '${zone.cameraImageUrl}  /  TODAY 09:11:11',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(Widget child, {bool square = false}) {
    return Container(
      padding: square
          ? const EdgeInsets.all(6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x8C000000),
        borderRadius: BorderRadius.circular(square ? 8 : 999),
      ),
      child: child,
    );
  }
}

class _Bay extends StatelessWidget {
  final bool occupied;
  const _Bay({required this.occupied});

  @override
  Widget build(BuildContext context) {
    // Bay line color: orange = occupied, teal = available
    final line = occupied ? const Color(0xFFF0B27A) : const Color(0xFF7FD8C8);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: line, width: 1.5),
        color: line.withAlpha(40),
      ),
      child: occupied
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )
          : null,
    );
  }
}
