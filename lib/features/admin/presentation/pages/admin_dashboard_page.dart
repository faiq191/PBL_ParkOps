import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const Color muted = Color(0xFF8493A3);
  static const Color blue = Color(0xFF477AA5);
  static const Color teal = Color(0xFF218F83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: muted,
                        ),
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
                      colors: [
                        Color(0xFF234D70),
                        Color(0xFF078F85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_parking_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

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
                      Icon(
                        Icons.access_time_rounded,
                        color: blue,
                        size: 21,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opening hours',
                              style: TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
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
                  const Divider(
                    height: 1,
                    color: AppColors.line,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
                            Icon(
                              Icons.circle,
                              size: 7,
                              color: teal,
                            ),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: muted,
                    ),
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
                              style: TextStyle(
                                fontSize: 10,
                                color: muted,
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
                              style: TextStyle(
                                fontSize: 10,
                                color: muted,
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

            // CUSTOMER REPORT
            _DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '16 March 2026',
                    style: TextStyle(
                      fontSize: 10,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF5263),
                        size: 23,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'LOKASI PARKIR TIDAK AKURAT, SAYA '
                          'MENUJU LOKASI PARKIR DAN TERNYATA '
                          'PARKIRAN PENUH! '
                          '!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.5,
                            color: Color(0xFF526477),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    color: AppColors.line,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: const AppBottomNav(
        currentIndex: 3,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;

  const _DashboardCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: child,
    );
  }
}
