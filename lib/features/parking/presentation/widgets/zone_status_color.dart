import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/parking_zone.dart';

/// Maps a zone status to its accent color ('full' | 'tight' | 'ok' — CI-2).
/// Presentation-side counterpart of the domain `ZoneStatus` enum: the color
/// choice is a UI concern, so it lives here and not in the entity.
extension ZoneStatusColor on ZoneStatus {
  Color get color => switch (this) {
        ZoneStatus.full => AppColors.full,
        ZoneStatus.tight => AppColors.tight,
        ZoneStatus.ok => AppColors.ok,
      };
}
