import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UI-only placeholder data: 48 bays, 18 available / 30 occupied.
/// Replace with real data when the backend is ready.
final List<bool> dummyOccupied =
    List.generate(48, (i) => !((i * 5) % 8 < 3)); // true = occupied
int get dummyTotal => dummyOccupied.length;
int get dummyOccupiedCount => dummyOccupied.where((o) => o).length;
int get dummyAvailable => dummyTotal - dummyOccupiedCount;

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
