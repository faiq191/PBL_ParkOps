/// Contract for the "onboarding done" flag (DV-2): a single owner for the
/// flag instead of five call sites reading/writing SharedPreferences.
abstract class OnboardingRepository {
  /// Whether the first-launch walkthrough has already been shown.
  Future<bool> isDone();

  /// Marks the walkthrough as shown ([done: true]) or resets it so the
  /// walkthrough can be replayed ([done: false]).
  Future<void> setDone({required bool done});
}
