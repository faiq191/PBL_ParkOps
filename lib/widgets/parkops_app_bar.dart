import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes.dart';
import '../theme/app_colors.dart';
import '../features/profile/presentation/providers/profile_provider.dart';

class ParkOpsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String section;
  final String title;
  const ParkOpsAppBar({super.key, required this.section, required this.title});

  @override
  // Required by PreferredSizeWidget: defines the app bar height (kToolbarHeight + 8)
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider);
    final hasAvatar =
        user.avatarPath != null && File(user.avatarPath!).existsSync();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: kToolbarHeight + 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section,
            style: const TextStyle(fontSize: 11, color: AppColors.mist),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Open profile menu',
          padding: EdgeInsets.zero,
          position: PopupMenuPosition.under,
          offset: const Offset(-12, 8),
          color: AppColors.paper,
          surfaceTintColor: AppColors.paper,
          onSelected: (value) {
            // Updated routing logic to handle the profile selection
            if (value == 'profile') {
              Navigator.of(context).pushNamed(Routes.profile);
            } else if (value == 'settings') {
              Navigator.of(context).pushNamed(Routes.settings);
            }
            // You can add logic for 'logout' here later
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: AppColors.navy),
                  SizedBox(width: 12),
                  Text('Profile', style: TextStyle(color: AppColors.navy)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, color: AppColors.navy),
                  SizedBox(width: 12),
                  Text('Settings', style: TextStyle(color: AppColors.navy)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.navy),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: AppColors.navy)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF181919), Color(0x3C140C5C)],
                ),
                image: hasAvatar
                    ? DecorationImage(
                        image: FileImage(File(user.avatarPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasAvatar
                  ? null
                  : const Icon(
                      Icons.local_parking,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}