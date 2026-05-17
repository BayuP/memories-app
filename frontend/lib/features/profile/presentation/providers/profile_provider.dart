import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:memories_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:memories_app/features/profile/domain/entities/profile_entity.dart';
import 'package:memories_app/features/profile/domain/repositories/profile_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileRemoteDataSource(client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(dataSource);
});

// ---------------------------------------------------------------------------
// Profile notifier
// ---------------------------------------------------------------------------

class ProfileNotifier extends AsyncNotifier<ProfileEntity> {
  @override
  Future<ProfileEntity> build() async {
    return ref.read(profileRepositoryProvider).getMe();
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final repo = ref.read(profileRepositoryProvider);
    final updated = await repo.updateMe(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMe(),
    );
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileEntity>(ProfileNotifier.new);
