import 'package:memories_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:memories_app/features/profile/domain/entities/profile_entity.dart';
import 'package:memories_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);

  final ProfileRemoteDataSource _dataSource;

  @override
  Future<ProfileEntity> getMe() async {
    final model = await _dataSource.getMe();
    return model.toEntity();
  }

  @override
  Future<ProfileEntity> updateMe({
    String? displayName,
    String? avatarUrl,
  }) async {
    final model = await _dataSource.updateMe(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    return model.toEntity();
  }
}
