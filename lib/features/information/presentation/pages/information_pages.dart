import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../parking/presentation/providers/parking_providers.dart';
import '../../../reporting/presentation/pages/reporting_page.dart';

class InformationPages extends ConsumerWidget {
  const InformationPages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authStateProvider).value?.isAdmin ?? false;

    // Latest footage time = when the ML worker last processed a frame for the
    // camera selected on the Camera tab. Shows --:--:-- until one arrives.
    final feed = ref.watch(selectedCameraFeedProvider);
    final processedAt = ref
        .watch(cameraInferenceStreamProvider(feed.id))
        .asData
        ?.value
        ?.processedAt;
    final footageTime = processedAt == null
        ? '--:--:--'
        : _formatClock(processedAt);

    return Scaffold(
      backgroundColor: context.palette.paper,
      appBar: const ParkOpsAppBar(section: 'PARKOPS', title: 'Information'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          // ParkOps identity card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.palette.mutedSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: context.palette.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: context.palette.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ParkOps',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: context.palette.navy,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'State Polytechnic of Malang',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.mist,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Parking essentials
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parking essentials',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: context.palette.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 12),
                      child: Icon(
                        Icons.access_time,
                        color: context.palette.accent,
                        size: 23,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opening hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.mist,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '7:00 AM - 10:00 PM, Everyday',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: context.palette.line),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detection information
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'About detection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: context.palette.navy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.tealSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 7,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.palette.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Camera footage is delayed by 1 minute. '
                  'Availability reflects that footage and may change '
                  'as cars arrive.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: context.palette.mist,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '89.2%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.palette.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Detection confidence',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.palette.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            footageTime,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.palette.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Latest footage time',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.palette.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportingPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Need Assistance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // Administrator card: only shown to signed-in admins
          if (isAdmin) ...[const _AdminCard(), const SizedBox(height: 16)],

          // Replay walkthrough card
          _InfoCard(
            child: InkWell(
              // Reset the walkthrough flag through the repository (DV-2 fix:
              // no storage plugin call in the widget).
              onTap: () async {
                await ref
                    .read(onboardingRepositoryProvider)
                    .setDone(done: false);
                if (!context.mounted) return;
                Navigator.of(context).pushReplacementNamed(Routes.onboarding);
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.replay_rounded,
                      color: context.palette.accent,
                      size: 25,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replay walkthrough',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.palette.navy,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'See the introduction and permissions again',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.north_east,
                      size: 19,
                      color: context.palette.accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

/// HH:MM:SS in local time.
String _formatClock(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(21),
      ),
      child: child,
    );
  }
}

/// Shortcut to the admin dashboard. Only built for users whose profile has
/// role == 'admin'; the route itself is also protected by AdminGuard.
class _AdminCard extends StatelessWidget {
  const _AdminCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administrator',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: palette.navy,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.of(context).pushNamed(Routes.admin),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: palette.navy,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Open Admin Dashboard',
                    style: TextStyle(fontSize: 13, color: palette.navy),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
