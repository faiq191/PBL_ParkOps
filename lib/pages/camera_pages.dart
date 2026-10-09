import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dummy_lots.dart';
import '../widgets/parkops_app_bar.dart';
import 'map_pages.dart';

/// UI only: the feed and counts are placeholders.
class CameraPages extends StatefulWidget {
  const CameraPages({super.key});

  @override
  State<CameraPages> createState() => _CameraPagesState();
}

class _CameraPagesState extends State<CameraPages> {
  bool _overlay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(
        section: 'Camera',
        title: 'Parking Lot Camera',
      ),
      // Rebuild whenever the selected lot changes (global state in dummy_lots.dart)
      body: ValueListenableBuilder<int>(
        valueListenable: selectedLotIndex,
        builder: (_, idx, __) {
          final lot = dummyLots[idx];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              const LotChips(),
              const SizedBox(height: 12),
              _cameraCard(lot),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      value: '${lot.available}',
                      label: 'Available',
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      value: '${lot.occupiedCount}',
                      label: 'Occupied',
                      color: AppColors.full,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      value: '${lot.total}',
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
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _cameraCard(DummyLot lot) {
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
                Text(
                  '${lot.camera}  -  ${lot.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          _DummyCameraFeed(lot: lot, showOverlay: _overlay),
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
                  value: _overlay,
                  activeTrackColor: AppColors.navy,
                  onChanged: (v) => setState(() => _overlay = v),
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
        onPressed: () => Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MapPages())),
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
  final DummyLot lot;
  final bool showOverlay;
  const _DummyCameraFeed({required this.lot, required this.showOverlay});

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
                    for (int r = 0; r < (lot.total / _cols).ceil(); r++)
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            for (int c = 0; c < _cols; c++) ...[
                              if (c > 0) const SizedBox(width: 3),
                              Expanded(
                                child: r * _cols + c < lot.total
                                    ? _Bay(
                                        occupied: lot.occupied[r * _cols + c],
                                      )
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
                  '${lot.camera}  /  TODAY 09:11:11',
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
