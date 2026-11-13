import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../../parking/domain/entities/parking_zone.dart';
import '../../../parking/presentation/providers/parking_providers.dart';
import '../../../reporting/data/report_repository.dart';
import '../../../reporting/presentation/providers/report_providers.dart';

const Color _muted = Color(0xFF8493A3);

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDateTime(DateTime time) {
  final t = time.toLocal();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${_months[t.month - 1]} ${t.year}, $hh:$mm';
}

Color _occupancyColor(double ratio) {
  if (ratio >= 0.9) return AppColors.full;
  if (ratio >= 0.7) return AppColors.tight;
  return AppColors.tealLight;
}

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'MANAGEMENT', title: 'Admin'),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text(
            'Could not load parking data.',
            style: TextStyle(color: _muted),
          ),
        ),
        data: (zones) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _OverviewCard(zones: zones),
            const SizedBox(height: 22),
            const _SectionTitle('Parking lots'),
            if (zones.isEmpty)
              const _EmptyNote('No parking lots yet.')
            else
              ...zones.map((zone) => _LotCard(zone: zone)),
            const SizedBox(height: 14),
            const _SectionTitle('Live camera'),
            const _CameraCard(),
            const SizedBox(height: 22),
            const _SectionTitle('Customer reports'),
            const _ReportsCard(),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: _muted,
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Text(text, style: const TextStyle(fontSize: 12, color: _muted)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.zones});

  final List<ParkingZone> zones;

  @override
  Widget build(BuildContext context) {
    final total = zones.fold<int>(0, (sum, z) => sum + z.totalSlots);
    final available = zones.fold<int>(0, (sum, z) => sum + z.availableSlots);
    final occupied = (total - available)
        .clamp(0, total < 0 ? 0 : total)
        .toInt();
    final ratio = total == 0 ? 0.0 : occupied / total;

    DateTime? updated;
    for (final zone in zones) {
      if (updated == null || zone.lastUpdated.isAfter(updated)) {
        updated = zone.lastUpdated;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Campus occupancy',
                style: TextStyle(fontSize: 12, color: AppColors.mist),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: AppColors.tealLight),
                    SizedBox(width: 6),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 42,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$occupied of $total bays occupied across ${zones.length} lots',
            style: const TextStyle(fontSize: 12, color: AppColors.mist),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(_occupancyColor(ratio)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: 'Available', value: '$available'),
              _Stat(label: 'Occupied', value: '$occupied'),
              _Stat(label: 'Lots', value: '${zones.length}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.amber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  updated == null
                      ? 'No lot data yet'
                      : 'Lot data updated ${_formatDateTime(updated)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.amber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.mist),
          ),
        ],
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.zone});

  final ParkingZone zone;

  Color get _color {
    switch (zone.status) {
      case ZoneStatus.full:
        return AppColors.full;
      case ZoneStatus.tight:
        return AppColors.tight;
      case ZoneStatus.ok:
        return AppColors.ok;
    }
  }

  String get _label {
    switch (zone.status) {
      case ZoneStatus.full:
        return 'Full';
      case ZoneStatus.tight:
        return 'Almost full';
      case ZoneStatus.ok:
        return 'Available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = zone.totalSlots;
    final occupied = zone.occupiedSlots.clamp(0, total < 0 ? 0 : total).toInt();
    final ratio = total == 0 ? 0.0 : occupied / total;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    if (zone.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        zone.location,
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${zone.availableSlots} of $total free',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}% occupied',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Updated ${_formatDateTime(zone.lastUpdated)}',
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends ConsumerWidget {
  const _CameraCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(selectedCameraFeedProvider);
    final inference = ref.watch(cameraInferenceStreamProvider(feed.id));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.videocam_outlined,
                size: 20,
                color: AppColors.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  feed.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          inference.when(
            loading: () => const Text(
              'Checking the camera...',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
            error: (_, __) => const Text(
              'Could not load camera data.',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
            data: (result) {
              final processed = result?.processedAt;
              if (result == null || processed == null) {
                return const Text(
                  'No processed frame yet.',
                  style: TextStyle(fontSize: 11, color: _muted),
                );
              }
              return Row(
                children: [
                  _CameraFact(
                    value: '${result.vehicleCount}',
                    label: 'Vehicles',
                  ),
                  _CameraFact(
                    value: '${result.emptySpaceCount}',
                    label: 'Empty spaces',
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(processed),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Last processed',
                          style: TextStyle(fontSize: 10, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CameraFact extends StatelessWidget {
  const _CameraFact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }
}

class _ReportsCard extends ConsumerWidget {
  const _ReportsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(recentReportsProvider);

    return reports.when(
      loading: () => const _Card(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const _EmptyNote(
        'Could not load reports. Check the Firestore rules for reports.',
      ),
      data: (items) {
        if (items.isEmpty) return const _EmptyNote('No reports yet.');
        return Column(
          children: items.map((report) => _ReportTile(report: report)).toList(),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final ParkingReport report;

  @override
  Widget build(BuildContext context) {
    final created = report.createdAt;
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.flag_rounded, size: 20, color: AppColors.tight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.zoneName} - ${report.type}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF526477),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  created == null ? 'Just now' : _formatDateTime(created),
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
