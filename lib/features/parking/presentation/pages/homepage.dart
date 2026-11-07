import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../data/camera_feeds.dart';
import '../../domain/entities/camera_feed.dart';
import '../../domain/entities/camera_inference_result.dart';
import '../providers/parking_providers.dart';

class HomepagePages extends ConsumerWidget {
  const HomepagePages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCameraId = ref.watch(selectedCameraIdProvider);
    final results = [
      for (final feed in cameraFeeds)
        ref.watch(cameraInferenceStreamProvider(feed.id)),
    ];
    final selectedIndex = cameraFeeds.indexWhere(
      (feed) => feed.id == selectedCameraId,
    );
    final selectedResult = selectedIndex < 0
        ? const AsyncData<CameraInferenceResult?>(null)
        : results[selectedIndex];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'Homepage', title: 'ParkOps'),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _AggregateSummary(results: results),
          const SizedBox(height: 18),
          _SelectedCameraCard(
            feed: cameraFeeds[selectedIndex < 0 ? 0 : selectedIndex],
            inference: selectedResult,
          ),
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
                  subtitle: 'See camera detections',
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
            'Parking cameras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < cameraFeeds.length; index++)
            _CameraRow(
              feed: cameraFeeds[index],
              inference: results[index],
              selected: cameraFeeds[index].id == selectedCameraId,
              onTap: () => ref
                  .read(selectedCameraIdProvider.notifier)
                  .select(cameraFeeds[index].id),
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _AggregateSummary extends StatelessWidget {
  const _AggregateSummary({required this.results});

  final List<AsyncValue<CameraInferenceResult?>> results;

  @override
  Widget build(BuildContext context) {
    final availableResults = results
        .map((result) => result.asData?.value)
        .whereType<CameraInferenceResult>()
        .toList();
    final emptySpaces = availableResults.fold<int>(
      0,
      (sum, result) => sum + result.emptySpaceCount,
    );
    final vehicles = availableResults.fold<int>(
      0,
      (sum, result) => sum + result.vehicleCount,
    );
    final lastUpdate = availableResults
        .map((result) => result.processedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, time) {
          if (latest == null || time.isAfter(latest)) return time;
          return latest;
        });
    final hasError = results.any((result) => result.hasError);

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
            'Empty spaces detected across cameras',
            style: TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            availableResults.isEmpty ? '--' : '$emptySpaces',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'Vehicles detected: $vehicles · '
            '${availableResults.length}/${cameraFeeds.length} cameras reporting',
            style: const TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, size: 6, color: AppColors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasError && availableResults.length < cameraFeeds.length
                      ? 'Some camera results could not be loaded'
                      : availableResults.isEmpty
                      ? 'Waiting for the laptop ML worker'
                      : 'Latest update: ${_formatHomeTime(lastUpdate)}',
                  style: const TextStyle(color: AppColors.amber, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedCameraCard extends StatelessWidget {
  const _SelectedCameraCard({required this.feed, required this.inference});

  final CameraFeed feed;
  final AsyncValue<CameraInferenceResult?> inference;

  @override
  Widget build(BuildContext context) {
    final result = inference.asData?.value;
    final error = inference.hasError;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  feed.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: result == null ? AppColors.line : AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  error
                      ? 'Unavailable'
                      : result == null
                      ? 'Waiting'
                      : '${result.vehicleCount + result.emptySpaceCount} '
                            'detections',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result == null ? '--' : '${result.emptySpaceCount}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: const Text(
                  'empty spaces detected',
                  style: TextStyle(fontSize: 14, color: AppColors.mist),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result == null
                ? error
                      ? 'Could not load camera data.'
                      : 'Ask the laptop operator to start the ML worker.'
                : '${result.vehicleCount} vehicles detected in the latest frame.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Camera inference',
                style: TextStyle(fontSize: 12, color: AppColors.mist),
              ),
              Flexible(
                child: Text(
                  result == null
                      ? error
                            ? 'Check connection'
                            : 'Waiting for worker'
                      : _formatHomeTime(result.processedAt),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: AppColors.mist),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraRow extends StatelessWidget {
  const _CameraRow({
    required this.feed,
    required this.inference,
    required this.selected,
    required this.onTap,
  });

  final CameraFeed feed;
  final AsyncValue<CameraInferenceResult?> inference;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final result = inference.asData?.value;
    final statusColor = result == null ? AppColors.mist : AppColors.teal;
    final status = inference.hasError
        ? 'Unavailable'
        : result == null
        ? 'Waiting'
        : 'E ${result.emptySpaceCount} / V ${result.vehicleCount}';

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
              border: Border(left: BorderSide(color: statusColor, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        feed.id,
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
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
