import 'package:memories_app/features/trips/data/datasources/trips_remote_datasource.dart';
import 'package:memories_app/features/trips/domain/entities/public_trip_entity.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/domain/repositories/trips_repository.dart';

class TripsRepositoryImpl implements TripsRepository {
  const TripsRepositoryImpl(this._dataSource);

  final TripsRemoteDataSource _dataSource;

  @override
  Future<List<TripEntity>> getTrips() async {
    final models = await _dataSource.getTrips();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TripDetailEntity> createTrip({
    required String title,
    required String destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? vibes,
  }) async {
    final model = await _dataSource.createTrip(
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      vibes: vibes,
    );
    return model.toEntity();
  }

  @override
  Future<TripDetailEntity> getTripDetail(String id) async {
    final model = await _dataSource.getTripDetail(id);
    return model.toEntity();
  }

  @override
  Future<MemberEntity> addMember(String tripId, String userId) async {
    final model = await _dataSource.addMember(tripId, userId);
    return model.toEntity();
  }

  @override
  Future<void> removeMember(String tripId, String userId) async {
    await _dataSource.removeMember(tripId, userId);
  }

  @override
  Future<List<PublicProfileEntity>> searchUsers(String q) async {
    final models = await _dataSource.searchUsers(q);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ItineraryItemEntity>> generateItinerary(String tripId) async {
    final models = await _dataSource.generateItinerary(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> refineItinerary(
    String tripId,
    String message,
    List<Map<String, String>> history,
  ) async {
    return _dataSource.refineItinerary(tripId, message, history);
  }

  @override
  Future<ItineraryItemEntity> createItem(
    String tripId,
    Map<String, dynamic> body,
  ) async {
    final model = await _dataSource.createItem(tripId, body);
    return model.toEntity();
  }

  @override
  Future<List<ItineraryItemEntity>> getItems(String tripId) async {
    final models = await _dataSource.getItems(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ItineraryItemEntity> updateItem(
    String tripId,
    String itemId,
    Map<String, dynamic> body,
  ) async {
    final model = await _dataSource.updateItem(tripId, itemId, body);
    return model.toEntity();
  }

  @override
  Future<void> deleteItem(String tripId, String itemId) async {
    await _dataSource.deleteItem(tripId, itemId);
  }

  @override
  Future<PublicTripEntity> getPublicTrip(String id) async {
    final model = await _dataSource.getPublicTrip(id);
    return model.toEntity();
  }

  @override
  Future<void> publishTrip(String id) async {
    await _dataSource.publishTrip(id);
  }

  @override
  Future<void> unpublishTrip(String id) async {
    await _dataSource.unpublishTrip(id);
  }
}
