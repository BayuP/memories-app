import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/features/story/data/models/story_model.dart';

class StoryRemoteDataSource {
  const StoryRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/v1/trips/{tripId}/story
  /// Returns null when the backend responds with 404.
  Future<StoryModel?> getStory(String tripId) async {
    try {
      final data = await _apiClient.get('/api/v1/trips/$tripId/story');
      return StoryModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      // Treat 404 as "no story yet"
      if (e.toString().contains('404') ||
          e.toString().toLowerCase().contains('not found')) {
        return null;
      }
      rethrow;
    }
  }

  /// POST /api/v1/trips/{tripId}/story/generate
  Future<StoryModel> generateStory(String tripId) async {
    final data = await _apiClient.post(
        '/api/v1/trips/$tripId/story/generate');
    return StoryModel.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /api/v1/trips/{tripId}/story
  Future<StoryModel> updateStory(
    String tripId, {
    String? title,
    String? body,
  }) async {
    final reqBody = <String, dynamic>{};
    if (title != null) reqBody['title'] = title;
    if (body != null) reqBody['body'] = body;

    final data = await _apiClient.patch(
      '/api/v1/trips/$tripId/story',
      data: reqBody,
    );
    return StoryModel.fromJson(data as Map<String, dynamic>);
  }
}
