import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/failures.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Paste the Web client ID here (Firebase console -> Authentication ->
/// Sign-in method -> Google -> Web SDK configuration -> Web client ID).
/// Leave empty to let the plugin read it from google-services.json.
const String kGoogleWebClientId = '488141518443-f2geamlhmgqg2elcsj9bro0qbr7gqcur.apps.googleusercontent.com';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _db = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

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
      throw _failure(e);
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
      throw _failure(e);
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
      debugPrint('Profile save failed: code=${e.code} message=${e.message}');
      await _rollback(user);
      throw AuthFailure('Could not save your profile. Please try again.', e);
    }

    return AppUser(uid: user.uid, username: name, email: user.email ?? '');
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize(
          serverClientId:
              kGoogleWebClientId.isEmpty ? null : kGoogleWebClientId,
        );
        _googleReady = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Google did not return an ID token. Check the Web client ID setup.',
        );
      }
      final cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return await _ensureProfile(cred.user!);
    } on GoogleSignInException catch (e) {
      debugPrint(
        'Google sign-in failed: code=${e.code.name} description=${e.description}',
      );
      // Compare by name so this compiles regardless of which 7.x release
      // exports GoogleSignInExceptionCode.
      if (e.code.name == 'canceled') {
        throw const AuthFailure('Sign-in was cancelled.');
      }
      throw AuthFailure(
        'Google sign-in failed (${e.code.name}): ${e.description ?? 'no details'}',
        e,
      );
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }

  Future<AppUser> _ensureProfile(User user) async {
    final doc = _users.doc(user.uid);
    try {
      final data = (await doc.get()).data();
      if (data != null) {
        return AppUser(
          uid: user.uid,
          username: (data['username'] as String?) ?? _fallbackName(user),
          email: user.email ?? '',
          role: (data['role'] as String?) ?? 'user',
        );
      }
      final name = _socialUsername(user);
      await doc.set({
        'username': name,
        'email': user.email ?? '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return AppUser(uid: user.uid, username: name, email: user.email ?? '');
    } on FirebaseException catch (e) {
      debugPrint('Profile load/save failed: code=${e.code} message=${e.message}');
      return AppUser(
        uid: user.uid,
        username: _fallbackName(user),
        email: user.email ?? '',
      );
    }
  }

  String _socialUsername(User user) {
    final raw = (user.displayName ?? (user.email ?? 'user').split('@').first)
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    final padded = raw.length < 3 ? 'user$raw' : raw;
    return padded.length > 20 ? padded.substring(0, 20) : padded;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw _failure(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
    }
    await _auth.signOut();
  }

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
    } on FirebaseException catch (e) {
      debugPrint('Profile read failed: code=${e.code} message=${e.message}');
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

  AuthFailure _failure(FirebaseAuthException e) {
    debugPrint('Auth error: code=${e.code} message=${e.message}');
    return AuthFailure(_messageFor(e.code, e.message), e);
  }

  String _messageFor(String code, [String? detail]) {
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
      case 'account-exists-with-different-credential':
        return 'This email is already used with another sign-in method. '
            'Sign in with that method instead.';
      case 'web-context-canceled':
      case 'canceled':
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in the Firebase console.';
      case 'configuration-not-found':
        return 'Authentication is not set up for this Firebase project '
            '($code).';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'This app is not authorized for this Firebase project ($code).';
      default:
        return 'Authentication failed ($code): ${detail ?? 'no details'}';
    }
  }
}