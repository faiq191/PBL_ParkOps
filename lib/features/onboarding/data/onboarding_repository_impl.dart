import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/onboarding_repository.dart';

/// Key used in SharedPreferences so the walkthrough is shown only once
/// (on first launch / first install). Moved out of onboarding_pages.dart so
/// this data detail no longer lives in the UI (DV-2).
const String _kOnboardingDoneKey = 'onboarding_done';

/// SharedPreferences-backed [OnboardingRepository]. The key and every
/// SharedPreferences call live here — pages only see [isDone]/[setDone].
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({required this.prefs});

  final SharedPreferences prefs;

  @override
  Future<bool> isDone() async {
    return prefs.getBool(_kOnboardingDoneKey) ?? false;
  }

  @override
  Future<void> setDone({required bool done}) async {
    await prefs.setBool(_kOnboardingDoneKey, done);
  }
}
