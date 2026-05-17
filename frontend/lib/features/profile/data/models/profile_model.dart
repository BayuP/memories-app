import 'package:memories_app/features/profile/domain/entities/profile_entity.dart';

class ProfileModel {
  const ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      handle: json['handle'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      handle: handle,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      createdAt: createdAt,
    );
  }
}
