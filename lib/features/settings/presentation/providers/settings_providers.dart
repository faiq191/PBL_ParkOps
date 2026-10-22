import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/settings_preference_keys.dart';

class CameraOverlayPreference extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .watch(sharedPreferencesProvider)
          .getBool(SettingsPreferenceKeys.cameraOverlayEnabled) ??
      true;

  Future<bool> setEnabled(bool enabled) async {
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setBool(SettingsPreferenceKeys.cameraOverlayEnabled, enabled);
    if (saved) state = enabled;
    return saved;
  }
}

final cameraOverlayPreferenceProvider =
    NotifierProvider<CameraOverlayPreference, bool>(
      CameraOverlayPreference.new,
    );
