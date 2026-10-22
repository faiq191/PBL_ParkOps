import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/parkops_app_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(section: 'PARKOPS', title: 'Settings'),
      body: const SizedBox.shrink(),
    );
  }
}
