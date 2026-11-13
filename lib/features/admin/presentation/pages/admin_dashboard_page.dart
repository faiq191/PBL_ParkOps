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
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
            // HEADER
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Management',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF234D70), Color(0xFF078F85)],
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
              const Icon(Icons.schedule_rounded,
                  size: 14, color: AppColors.amber),
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

            // PARKING ESSENTIALS
            _DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parking essentials',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: blue, size: 21),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opening hours',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '24 hours, every day',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.line),
                ],
              ),
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

            // LOG PARKIRAN
            _DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Log Parkiran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F3ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 7, color: teal),
                            SizedBox(width: 6),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Log 1',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  const SizedBox(height: 9),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '99.2%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Parkiran Terisi',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'March 2026',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Date of the log',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              const Icon(Icons.videocam_outlined,
                  size: 20, color: AppColors.teal),
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
                  const SizedBox(height: 8),
                  const Text(
                    '16 March 2026',
                    style: TextStyle(fontSize: 10, color: muted),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.line),
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

      // BOTTOM NAVIGATION
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  const _DashboardCard({required this.child});

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
                  created == null
                      ? 'Just now'
                      : _formatDateTime(created),
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
