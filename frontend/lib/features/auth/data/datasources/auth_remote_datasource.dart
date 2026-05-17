import 'package:memories_app/core/constants/api_constants.dart';
import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/features/auth/data/models/auth_model.dart';

abstract class AuthRemoteDataSourceBase {
  Future<AuthTokensModel> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  });

  Future<AuthTokensModel> signIn({
    required String email,
    required String password,
  });

  Future<AuthTokensModel> refresh(String refreshToken);
}

class AuthRemoteDataSource implements AuthRemoteDataSourceBase {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthTokensModel> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.authSignUp,
      data: {
        'email': email,
        'password': password,
        'handle': handle,
        'display_name': displayName,
      },
    ) as Map<String, dynamic>;

    return AuthTokensModel.fromJson(response);
  }

  @override
  Future<AuthTokensModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.authSignIn,
      data: {
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    return AuthTokensModel.fromJson(response);
  }

  @override
  Future<AuthTokensModel> refresh(String refreshToken) async {
    final response = await _apiClient.post(
      ApiConstants.authRefresh,
      data: {'refresh_token': refreshToken},
    ) as Map<String, dynamic>;

    return AuthTokensModel.fromJson(response);
  }
}
