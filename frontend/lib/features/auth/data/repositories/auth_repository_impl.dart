import 'package:memories_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:memories_app/features/auth/domain/entities/auth_entity.dart';
import 'package:memories_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthTokens> signIn({
    required String email,
    required String password,
  }) async {
    final model = await _remoteDataSource.signIn(
      email: email,
      password: password,
    );
    return model.toEntity();
  }

  @override
  Future<AuthTokens> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    final model = await _remoteDataSource.signUp(
      email: email,
      password: password,
      handle: handle,
      displayName: displayName,
    );
    return model.toEntity();
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final model = await _remoteDataSource.refresh(refreshToken);
    return model.toEntity();
  }
}
