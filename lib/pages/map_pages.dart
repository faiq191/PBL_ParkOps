import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/dummy_bays.dart';
import '../widgets/parkops_app_bar.dart';
import 'camera_pages.dart';

/// UI only: bay layout and counts are placeholders.
class MapPages extends StatelessWidget {
  const MapPages({super.key});

  static const _rows = 6;
  static const _cols = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'Map', title: 'Find Your Space'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _mapCard(context),
          const SizedBox(height: 14),
          _cameraButton(context),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _mapCard(BuildContext context) {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Graha Polinema',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    Text('Main lot',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.mist)),
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
                child: Text('$dummyAvailable spaces available',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (int r = 0; r < _rows; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (int c = 0; c < _cols; c++)
                            Expanded(
                              child: _MapBay(
                                index: r * _cols + c,
                                occupied: dummyOccupied[r * _cols + c],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: AppColors.ok, label: 'Available'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.full, label: 'Occupied'),
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
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CameraPages()),
        ),
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
    final color = occupied ? AppColors.full : AppColors.ok;
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
              'Bay ${index + 1}: ${occupied ? 'occupied' : 'available'}'),
        )),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color.withAlpha(60),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Icon(occupied ? Icons.directions_car : Icons.check,
                size: 14, color: color),
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
            color: color.withAlpha(90),
            border: Border.all(color: color, width: 1.5),
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
