class UserProfile {
  final String name;
  final String email;
  final String bio;
  final String nim;
  final String? avatarPath;

  UserProfile({
    required this.name,
    required this.email,
    required this.bio,
    required this.nim,
    this.avatarPath,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? bio,
    String? nim,
    Object? avatarPath = _unset,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      nim: nim ?? this.nim,
      avatarPath: identical(avatarPath, _unset)
          ? this.avatarPath
          : avatarPath as String?,
    );
  }
}

const Object _unset = Object();