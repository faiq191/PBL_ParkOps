import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/data/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/parking/data/repositories/parking_repository_impl.dart';
import '../features/parking/domain/repositories/parking_repository.dart';
import 'providers.dart';

/// Composition root: the only place where concrete repository
/// implementations are bound to their domain contracts (CI-1/DI-1).
/// Pages and presentation providers depend on the abstract types above;
/// swapping in test fakes only means overriding these providers.
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(prefs: ref.watch(sharedPreferencesProvider));
});

final parkingRepositoryProvider = Provider<ParkingRepository>((ref) {
  return ParkingRepositoryImpl(firestore: FirebaseFirestore.instance);
});
