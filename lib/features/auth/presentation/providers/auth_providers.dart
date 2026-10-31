import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/app_user.dart';

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String?> signIn({required String email, required String password}) {
    return _run(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
    });
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _run(() async {
      await ref.read(authRepositoryProvider).register(
            username: username,
            email: email,
            password: password,
          );
    });
  }

  Future<String?> signInWithGoogle() {
    return _run(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    });
  }

  Future<String?> sendPasswordReset(String email) {
    return _run(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    });
  }

  Future<String?> signOut() {
    return _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<String?> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return null;
    } on Failure catch (e) {
      state = const AsyncData(null);
      return e.message;
    } catch (_) {
      state = const AsyncData(null);
      return 'Something went wrong. Please try again.';
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
