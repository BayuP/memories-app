import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/checkin/data/datasources/checkin_remote_datasource.dart';
import 'package:memories_app/features/checkin/data/repositories/checkin_repository_impl.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/domain/repositories/checkin_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final checkinRemoteDataSourceProvider =
    Provider<CheckinRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return CheckinRemoteDataSource(client);
});

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  final dataSource = ref.watch(checkinRemoteDataSourceProvider);
  return CheckinRepositoryImpl(dataSource);
});

// ---------------------------------------------------------------------------
// Checkin detail provider (family by checkin ID)
// ---------------------------------------------------------------------------

final checkinDetailProvider =
    FutureProvider.family<CheckinEntity, String>((ref, id) async {
  final repo = ref.watch(checkinRepositoryProvider);
  return repo.getCheckin(id);
});
