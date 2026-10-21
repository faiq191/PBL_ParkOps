class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.role = 'user',
  });

  final String uid;
  final String username;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';
}
