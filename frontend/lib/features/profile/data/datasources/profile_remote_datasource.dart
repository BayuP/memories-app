import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/features/profile/data/models/profile_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfileModel> getMe() async {
    final data = await _apiClient.get('/api/v1/me');
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProfileModel> updateMe({String? displayName, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final data = await _apiClient.patch('/api/v1/me', data: body);
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }
}
