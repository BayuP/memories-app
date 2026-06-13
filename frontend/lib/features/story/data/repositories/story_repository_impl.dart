import 'package:memories_app/features/story/data/datasources/story_remote_datasource.dart';
import 'package:memories_app/features/story/domain/entities/story_entity.dart';
import 'package:memories_app/features/story/domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  const StoryRepositoryImpl(this._dataSource);

  final StoryRemoteDataSource _dataSource;

  @override
  Future<StoryEntity?> getStory(String tripId) async {
    final model = await _dataSource.getStory(tripId);
    return model?.toEntity();
  }

  @override
  Future<StoryEntity> generateStory(String tripId) async {
    final model = await _dataSource.generateStory(tripId);
    return model.toEntity();
  }

  @override
  Future<StoryEntity> updateStory(
    String tripId, {
    String? title,
    String? body,
  }) async {
    final model = await _dataSource.updateStory(
      tripId,
      title: title,
      body: body,
    );
    return model.toEntity();
  }
}
