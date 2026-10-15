/// Application-wide failure types (CI-3): repositories map low-level
/// exceptions (Firestore, IO, ...) to these classes so raw errors never
/// reach the UI.
sealed class Failure implements Exception {
  const Failure(this.message, [this.cause]);

  /// Human-readable description safe to show in the UI.
  final String message;

  /// The original error this failure wraps, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// A Firestore read or realtime stream failed.
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, [super.cause]);
}
