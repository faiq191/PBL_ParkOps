import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../providers/parking_providers.dart';
import 'zone_status_color.dart';

/// Horizontal lot picker used on the Camera and Map tabs.
class LotChips extends ConsumerWidget {
  const LotChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zonesListProvider);
    final selectedId = ref.watch(selectedZoneIdProvider);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: zones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final zone = zones[i];
          final selected = zone.id == selectedId;
          return ChoiceChip(
            avatar: CircleAvatar(
              radius: 5,
              backgroundColor: zone.status.color,
            ),
            label: Text(zone.name),
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
            onSelected: (_) =>
                ref.read(selectedZoneIdProvider.notifier).select(zone.id),
          );
        },
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
