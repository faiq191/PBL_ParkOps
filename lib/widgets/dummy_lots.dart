import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UI-only placeholder data. Replace with real data once the backend is ready.
class DummyLot {
  final String id;
  final String name;
  final String location;
  final int total;
  final int available;
  final String camera;
  late final List<bool> occupied; // true = occupied

  DummyLot({
    required this.id,
    required this.name,
    required this.location,
    required this.total,
    required this.available,
    required this.camera,
  }) {
    // Distribute free slots evenly: k-th free index = floor(k * total / available)
    final free = <int>{
      for (int k = 0; k < available; k++) (k * total / available).floor(),
    };
    // true = occupied; any slot not in the 'free' set is occupied
    occupied = List.generate(total, (i) => !free.contains(i));
  }

  int get occupiedCount => total - available;

  /// 'full' | 'tight' | 'ok'
  String get status {
    if (available == 0) return 'full';
    if (available <= total * 0.2) return 'tight';
    return 'ok';
  }

  Color get statusColor => switch (status) {
        'full' => AppColors.full,
        'tight' => AppColors.tight,
        _ => AppColors.ok,
      };
}

final List<DummyLot> dummyLots = [
  DummyLot(
    id: 'lot1',
    name: 'Graha Polinema',
    location: 'Front parking area',
    total: 48,
    available: 18,
    camera: 'CAM 01',
  ),
  DummyLot(
    id: 'lot2',
    name: 'North Lot',
    location: 'Beside the library',
    total: 32,
    available: 4,
    camera: 'CAM 02',
  ),
  DummyLot(
    id: 'lot3',
    name: 'South Lot',
    location: 'Behind the workshop',
    total: 24,
    available: 0,
    camera: 'CAM 03',
  ),
];

/// Lot currently picked. Shared by the Home, Camera and Map tabs.
final ValueNotifier<int> selectedLotIndex = ValueNotifier<int>(0);

/// Horizontal lot picker used on the Camera and Map tabs.
class LotChips extends StatelessWidget {
  const LotChips({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedLotIndex,
      builder: (_, sel, __) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dummyLots.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final lot = dummyLots[i];
            final selected = i == sel;
            return ChoiceChip(
              avatar: CircleAvatar(
                radius: 5,
                backgroundColor: lot.statusColor,
              ),
              label: Text(lot.name),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.navy,
              backgroundColor: Colors.white,
              side: BorderSide.none,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.navy,
              ),
              onSelected: (_) => selectedLotIndex.value = i,
            );
          },
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const StatCard(
      {super.key,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.mist)),
        ],
      ),
    );
  }
}
