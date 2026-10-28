import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile.dart';

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    _load();
    return UserProfile(
      name: 'Eiyu Azizuly Efendi',
      email: 'eiyu@student.polinema.ac.id',
      bio: 'Politeknik Negeri Malang | TI-3I',
      nim: '244107020181',
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('profile_name')) return;
    final avatar = prefs.getString('profile_avatar');
    state = UserProfile(
      name: prefs.getString('profile_name') ?? state.name,
      email: prefs.getString('profile_email') ?? state.email,
      bio: prefs.getString('profile_bio') ?? state.bio,
      nim: prefs.getString('profile_nim') ?? state.nim,
      avatarPath:
          avatar != null && File(avatar).existsSync() ? avatar : null,
    );
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    final oldAvatar = state.avatarPath;
    state = newProfile;

    final dir = await getApplicationDocumentsDirectory();
    final newAvatar = await _persistAvatar(newProfile.avatarPath, dir);

    if (oldAvatar != null &&
        oldAvatar != newAvatar &&
        oldAvatar.startsWith(dir.path)) {
      final oldFile = File(oldAvatar);
      if (oldFile.existsSync()) await oldFile.delete();
    }

    final saved = newProfile.copyWith(avatarPath: newAvatar);
    state = saved;
    await _save(saved);
  }

  Future<String?> _persistAvatar(String? path, Directory dir) async {
    if (path == null) return null;
    if (path.startsWith(dir.path)) return path;
    final source = File(path);
    if (!source.existsSync()) return null;
    final ext = path.contains('.') ? path.split('.').last : 'jpg';
    final dest =
        '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await source.copy(dest);
    return dest;
  }

  Future<void> _save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', profile.name);
    await prefs.setString('profile_email', profile.email);
    await prefs.setString('profile_bio', profile.bio);
    await prefs.setString('profile_nim', profile.nim);
    if (profile.avatarPath != null) {
      await prefs.setString('profile_avatar', profile.avatarPath!);
    } else {
      await prefs.remove('profile_avatar');
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});