import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/core/demo/demo_flag.dart';
import 'package:memories_app/core/demo/mock_data.dart';
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
    // DEMO: return mock profile immediately
    if (ref.watch(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 200));
      return mockProfile;
    }
    // DEMO: real API call below
    return ref.read(profileRepositoryProvider).getMe();
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    // DEMO: apply edit in-memory only
    if (ref.read(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 200));
      final current = state.value ?? mockProfile;
      state = AsyncData(
        ProfileEntity(
          id: current.id,
          handle: current.handle,
          displayName: displayName ?? current.displayName,
          email: current.email,
          avatarUrl: avatarUrl ?? current.avatarUrl,
          createdAt: current.createdAt,
        ),
      );
      return;
    }
    // DEMO: real API call below
    final repo = ref.read(profileRepositoryProvider);
    final updated = await repo.updateMe(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    // DEMO: just re-emit mock profile
    if (ref.read(demoModeProvider)) {
      state = const AsyncLoading();
      await Future.delayed(const Duration(milliseconds: 200));
      state = AsyncData(mockProfile);
      return;
    }
    // DEMO: real API call below
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMe(),
    );
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileEntity>(ProfileNotifier.new);
