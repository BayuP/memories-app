import 'package:memories_app/features/trips/domain/entities/public_trip_entity.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

abstract class TripsRepository {
  Future<List<TripEntity>> getTrips();

  Future<TripDetailEntity> createTrip({
    required String title,
    required String destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? vibes,
  });

  Future<TripDetailEntity> getTripDetail(String id);

  Future<MemberEntity> addMember(String tripId, String userId);

  Future<List<PublicProfileEntity>> searchUsers(String q);

  Future<List<ItineraryItemEntity>> generateItinerary(String tripId);

  Future<String> refineItinerary(
    String tripId,
    String message,
    List<Map<String, String>> history,
  );

  Future<List<ItineraryItemEntity>> getItems(String tripId);

  Future<ItineraryItemEntity> updateItem(
    String tripId,
    String itemId,
    Map<String, dynamic> body,
  );

  Future<void> deleteItem(String tripId, String itemId);

  Future<PublicTripEntity> getPublicTrip(String id);

  Future<void> publishTrip(String id);

  Future<void> unpublishTrip(String id);
}
