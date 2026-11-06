/// Application-wide failure types (CI-3): repositories map low-level
/// exceptions (Firestore, IO, ...) to these classes so raw errors never
/// reach the UI.
sealed class Failure implements Exception {
  const Failure(this.message, [this.cause]);

  final String message;

  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, [super.cause]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.cause]);
}
