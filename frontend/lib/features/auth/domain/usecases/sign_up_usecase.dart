import 'package:memories_app/features/auth/domain/entities/auth_entity.dart';
import 'package:memories_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthTokens> call({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      handle: handle,
      displayName: displayName,
    );
  }
}
