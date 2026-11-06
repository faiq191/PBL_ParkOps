import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile.dart';

final authUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.userChanges(),
);

class ProfileNotifier extends Notifier<UserProfile> {
  String? _uid;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  UserProfile build() {
    final user =
        ref.watch(authUserProvider).value ?? FirebaseAuth.instance.currentUser;
    _uid = user?.uid;
    if (user != null) _load(user);
    return _defaultFor(user);
  }

  UserProfile _defaultFor(User? user) {
    final display = user?.displayName?.trim();
    final emailName = user?.email?.split('@').first;
    return UserProfile(
      name: (display != null && display.isNotEmpty)
          ? display
          : (emailName ?? 'User'),
      email: user?.email ?? '',
      bio: '',
      nim: '',
    );
  }

  String? _str(Object? v) => (v is String && v.isNotEmpty) ? v : null;

  String _avatarKey(String uid) => 'profile_${uid}_avatar';

  Future<void> _load(User user) async {
    final uid = user.uid;
    final defaults = _defaultFor(user);

    Map<String, dynamic>? data;
    try {
      data = (await _doc(uid).get()).data();
    } on FirebaseException catch (e) {
      debugPrint('Profile load failed: code=${e.code} message=${e.message}');
    }

    final prefs = await SharedPreferences.getInstance();
    if (_uid != uid) return; // account changed while loading

    final avatar = prefs.getString(_avatarKey(uid));
    state = UserProfile(
      name: _str(data?['displayName']) ??
          _str(data?['username']) ??
          defaults.name,
      email: defaults.email,
      bio: _str(data?['bio']) ?? '',
      nim: _str(data?['nim']) ?? '',
      avatarPath: avatar != null && File(avatar).existsSync() ? avatar : null,
    );
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    final uid = _uid;
    if (uid == null) return;

    final oldAvatar = state.avatarPath;
    state = newProfile;

    final dir = await getApplicationDocumentsDirectory();
    final newAvatar = await _persistAvatar(newProfile.avatarPath, dir, uid);

    if (oldAvatar != null &&
        oldAvatar != newAvatar &&
        oldAvatar.startsWith(dir.path)) {
      final oldFile = File(oldAvatar);
      if (oldFile.existsSync()) await oldFile.delete();
    }

    final saved = newProfile.copyWith(avatarPath: newAvatar);
    if (_uid == uid) state = saved;

    final prefs = await SharedPreferences.getInstance();
    if (newAvatar != null) {
      await prefs.setString(_avatarKey(uid), newAvatar);
    } else {
      await prefs.remove(_avatarKey(uid));
    }

    try {
      await _doc(uid).set({
        'displayName': saved.name,
        'bio': saved.bio,
        'nim': saved.nim,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('Profile save failed: code=${e.code} message=${e.message}');
    }
  }

  Future<String?> _persistAvatar(
      String? path, Directory dir, String uid) async {
    if (path == null) return null;
    if (path.startsWith(dir.path)) return path;
    final source = File(path);
    if (!source.existsSync()) return null;
    final ext = path.contains('.') ? path.split('.').last : 'jpg';
    final dest =
        '${dir.path}/avatar_${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await source.copy(dest);
    return dest;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});