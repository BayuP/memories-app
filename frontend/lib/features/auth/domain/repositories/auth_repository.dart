import 'package:memories_app/features/auth/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthTokens> signIn({
    required String email,
    required String password,
  });

  Future<AuthTokens> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  });

  Future<AuthTokens> refresh(String refreshToken);
}
