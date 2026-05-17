import 'package:memories_app/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getMe();

  Future<ProfileEntity> updateMe({String? displayName, String? avatarUrl});
}
