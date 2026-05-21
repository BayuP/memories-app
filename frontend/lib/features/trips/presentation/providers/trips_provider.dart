import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/core/demo/demo_flag.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/trips/data/datasources/trips_remote_datasource.dart';
import 'package:memories_app/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:memories_app/features/trips/domain/entities/public_trip_entity.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/domain/repositories/trips_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final tripsRemoteDataSourceProvider = Provider<TripsRemoteDataSource>((ref) {
  return TripsRemoteDataSource(
    ref.watch(apiClientProvider),
    demoMode: ref.watch(demoModeProvider),
  );
});

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  final dataSource = ref.watch(tripsRemoteDataSourceProvider);
  return TripsRepositoryImpl(dataSource);
});

// ---------------------------------------------------------------------------
// Trips list provider
// ---------------------------------------------------------------------------

class TripsNotifier extends AsyncNotifier<List<TripEntity>> {
  @override
  Future<List<TripEntity>> build() async {
    return _fetch();
  }

  Future<List<TripEntity>> _fetch() {
    final repo = ref.read(tripsRepositoryProvider);
    return repo.getTrips();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final tripsProvider =
    AsyncNotifierProvider<TripsNotifier, List<TripEntity>>(TripsNotifier.new);

// ---------------------------------------------------------------------------
// Trip detail provider (family by trip ID)
// ---------------------------------------------------------------------------

class TripDetailNotifier
    extends FamilyAsyncNotifier<TripDetailEntity, String> {
  @override
  Future<TripDetailEntity> build(String arg) async {
    return ref.read(tripsRepositoryProvider).getTripDetail(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tripsRepositoryProvider).getTripDetail(arg),
    );
  }
}

final tripDetailProvider =
    AsyncNotifierProvider.family<TripDetailNotifier, TripDetailEntity, String>(
  TripDetailNotifier.new,
);

// ---------------------------------------------------------------------------
// Itinerary items provider (family by trip ID)
// ---------------------------------------------------------------------------

class ItineraryItemsNotifier
    extends FamilyAsyncNotifier<List<ItineraryItemEntity>, String> {
  @override
  Future<List<ItineraryItemEntity>> build(String arg) async {
    return ref.read(tripsRepositoryProvider).getItems(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tripsRepositoryProvider).getItems(arg),
    );
  }

  Future<void> deleteItem(String itemId) async {
    await ref.read(tripsRepositoryProvider).deleteItem(arg, itemId);
    final current = state.value ?? [];
    state = AsyncData(current.where((i) => i.id != itemId).toList());
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> body) async {
    final updated =
        await ref.read(tripsRepositoryProvider).updateItem(arg, itemId, body);
    final current = state.value ?? [];
    state = AsyncData(
      current.map((i) => i.id == itemId ? updated : i).toList(),
    );
  }
}

final itineraryItemsProvider = AsyncNotifierProvider.family<
    ItineraryItemsNotifier, List<ItineraryItemEntity>, String>(
  ItineraryItemsNotifier.new,
);

// ---------------------------------------------------------------------------
// User search provider
// ---------------------------------------------------------------------------

final userSearchQueryProvider = StateProvider<String>((ref) => '');

final userSearchResultsProvider =
    FutureProvider.family<List<PublicProfileEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(tripsRepositoryProvider);
  return repo.searchUsers(query);
});

// ---------------------------------------------------------------------------
// Public trip provider (no-auth, family by trip ID)
// ---------------------------------------------------------------------------

final publicTripProvider =
    FutureProvider.family<PublicTripEntity, String>((ref, id) async {
  final repo = ref.read(tripsRepositoryProvider);
  return repo.getPublicTrip(id);
});

// ---------------------------------------------------------------------------
// Publish / unpublish actions
// ---------------------------------------------------------------------------

/// Exposes publish and unpublish as simple async methods.
/// Usage: ref.read(publishTripActionsProvider).publish(id)
class PublishTripActions {
  const PublishTripActions(this._repo);

  final TripsRepository _repo;

  Future<void> publish(String id) => _repo.publishTrip(id);

  Future<void> unpublish(String id) => _repo.unpublishTrip(id);
}

final publishTripActionsProvider = Provider<PublishTripActions>((ref) {
  final repo = ref.read(tripsRepositoryProvider);
  return PublishTripActions(repo);
});
