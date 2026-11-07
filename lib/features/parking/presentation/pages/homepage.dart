import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../domain/entities/camera_feed.dart';
import '../../domain/entities/camera_inference_result.dart';
import '../../domain/entities/parking_zone.dart';
import '../providers/parking_providers.dart';

/// Parking zones still use demo metadata when Firestore has not been seeded.
class HomepagePages extends ConsumerWidget {
  const HomepagePages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'Homepage', title: 'ParkOps'),
      body: zonesAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Center(
          child: Text(
            e is Failure ? e.message : 'Could not load parking zones',
          ),
        ),
        data: (_) => const _HomepageBody(),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

/// Home tab body. Rebuilds automatically whenever the selected zone changes
/// (DV-3: selection is now Riverpod state in parking_providers.dart).
class _HomepageBody extends ConsumerWidget {
  const _HomepageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zonesListProvider);
    final selectedId = ref.watch(selectedZoneIdProvider);
    final feed = ref.watch(selectedCameraFeedProvider);
    final inference = ref.watch(cameraInferenceStreamProvider(feed.id));

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _LiveCameraSummary(feed: feed, inference: inference),
        const SizedBox(height: 18),
        const Text(
          'Explore the lot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ExploreCard(
                icon: Icons.videocam_outlined,
                title: 'Camera view',
                subtitle: 'See delayed detection',
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed(Routes.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExploreCard(
                icon: Icons.map_outlined,
                title: 'Parking map',
                subtitle: 'Find an open bay',
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed(Routes.map),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Parking lots',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        for (final zone in zones)
          _LotRow(
            zone: zone,
            selected: zone.id == selectedId,
            // Update the selected-zone state so Camera & Map tabs follow the selection
            onTap: () =>
                ref.read(selectedZoneIdProvider.notifier).select(zone.id),
          ),
      ],
    );
  }
}

class _LiveCameraSummary extends StatelessWidget {
  const _LiveCameraSummary({required this.feed, required this.inference});

  final CameraFeed feed;
  final AsyncValue<CameraInferenceResult?> inference;

  @override
  Widget build(BuildContext context) {
    final result = inference.asData?.value;
    final detectionCount = result == null
        ? null
        : result.vehicleCount + result.emptySpaceCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest camera detections',
            style: TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            result == null ? '--' : '$detectionCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const Text(
            'detections in the latest frame',
            style: TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            feed.title,
            style: const TextStyle(color: AppColors.mist, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, size: 6, color: AppColors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _statusText(result),
                  style: const TextStyle(color: AppColors.amber, fontSize: 10),
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HomeMetric(
                    value: '${result.vehicleCount}',
                    label: 'Vehicles',
                  ),
                ),
                Expanded(
                  child: _HomeMetric(
                    value: '${result.emptySpaceCount}',
                    label: 'Empty spaces',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(CameraInferenceResult? result) {
    if (inference.hasError) return 'Could not load camera data';
    if (result == null) return 'Waiting for the laptop ML worker';
    return 'Last update: ${_formatHomeTime(result.processedAt)}';
  }
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.mist, fontSize: 11),
        ),
      ],
    );
  }
}

class _LotRow extends StatelessWidget {
  final ParkingZone zone;
  final bool selected;
  final VoidCallback onTap;
  const _LotRow({
    required this.zone,
    required this.selected,
    required this.onTap,
  });

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
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        zone.location,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8892A0),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
                Text(
                  zone.cameraImageUrl,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.navy,
                  ),
                ),
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
                  const Icon(Icons.north_east, color: AppColors.navy, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatHomeTime(DateTime? time) {
  if (time == null) return 'Update time unavailable';
  final local = time.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$date $hour:$minute:$second';
}
