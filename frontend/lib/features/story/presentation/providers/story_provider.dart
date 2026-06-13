import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/story/data/datasources/story_remote_datasource.dart';
import 'package:memories_app/features/story/data/repositories/story_repository_impl.dart';
import 'package:memories_app/features/story/domain/entities/story_entity.dart';
import 'package:memories_app/features/story/domain/repositories/story_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final storyRemoteDataSourceProvider =
    Provider<StoryRemoteDataSource>((ref) {
  return StoryRemoteDataSource(ref.watch(apiClientProvider));
});

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(ref.watch(storyRemoteDataSourceProvider));
});

// ---------------------------------------------------------------------------
// Story provider (family by trip ID)
// ---------------------------------------------------------------------------

/// Holds the current story (or null) for a trip.
/// Also exposes `generate` and `update` actions via the notifier.
class StoryNotifier
    extends FamilyAsyncNotifier<StoryEntity?, String> {
  @override
  Future<StoryEntity?> build(String tripId) async {
    return ref.read(storyRepositoryProvider).getStory(tripId);
  }

  Future<void> generate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(storyRepositoryProvider).generateStory(arg),
    );
  }

  Future<void> saveEdits({String? title, String? body}) async {
    final current = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(storyRepositoryProvider).updateStory(
            arg,
            title: title,
            body: body,
          ),
    );
    // If update fails, restore previous state
    if (state.hasError && current != null) {
      state = AsyncData(current);
    }
  }
}

final storyProvider =
    AsyncNotifierProvider.family<StoryNotifier, StoryEntity?, String>(
  StoryNotifier.new,
);
