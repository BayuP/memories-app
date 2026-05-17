class ProfileEntity {
  const ProfileEntity({
    required this.id,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String handle;
  final String displayName;
  final String? avatarUrl;
  final String email;
  final DateTime createdAt;
}
