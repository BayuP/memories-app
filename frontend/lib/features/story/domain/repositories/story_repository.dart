import 'package:memories_app/features/story/domain/entities/story_entity.dart';

abstract class StoryRepository {
  /// Fetch the saved story for a trip. Returns null if none exists yet.
  Future<StoryEntity?> getStory(String tripId);

  /// Generate (or regenerate) a story using AI and upsert it.
  Future<StoryEntity> generateStory(String tripId);

  /// Manually update the story title and/or body.
  Future<StoryEntity> updateStory(
    String tripId, {
    String? title,
    String? body,
  });
}
