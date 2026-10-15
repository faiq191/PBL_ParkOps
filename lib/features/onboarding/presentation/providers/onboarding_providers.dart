import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';

/// Whether the first-launch walkthrough has already been shown.
/// Read by RootGate in main.dart to pick the first screen.
final onboardingDoneProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepositoryProvider).isDone();
});
