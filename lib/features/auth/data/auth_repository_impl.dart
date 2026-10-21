import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/failures.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

// ignore_for_file: prefer_initializing_formals
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _db = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().asyncMap(_profileFor);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return (await _profileFor(cred.user))!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code), e);
    }
  }

  @override
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final name = username.trim();
    final key = name.toLowerCase();

    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code), e);
    }
    final user = cred.user!;

    try {
      await _db.runTransaction((tx) async {
        final nameRef = _usernames.doc(key);
        final taken = await tx.get(nameRef);
        if (taken.exists) {
          throw const AuthFailure('That username is already taken.');
        }
        tx.set(nameRef, {'uid': user.uid});
        tx.set(_users.doc(user.uid), {
          'username': name,
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      await user.updateDisplayName(name);
    } on AuthFailure {
      await _rollback(user);
      rethrow;
    } on FirebaseException catch (e) {
      await _rollback(user);
      throw AuthFailure('Could not save your profile. Please try again.', e);
    }

    return AppUser(uid: user.uid, username: name, email: user.email ?? '');
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw AuthFailure(_messageFor(e.code), e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> _profileFor(User? user) async {
    if (user == null) return null;
    try {
      final data = (await _users.doc(user.uid).get()).data();
      if (data != null) {
        return AppUser(
          uid: user.uid,
          username: (data['username'] as String?) ?? _fallbackName(user),
          email: user.email ?? '',
          role: (data['role'] as String?) ?? 'user',
        );
      }
    } on FirebaseException {
      // Profile unreadable: fall back to the Auth data below.
    }
    return AppUser(
      uid: user.uid,
      username: _fallbackName(user),
      email: user.email ?? '',
    );
  }

  String _fallbackName(User user) =>
      user.displayName ?? (user.email ?? 'user').split('@').first;

  Future<void> _rollback(User user) async {
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this app.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
