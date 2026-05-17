import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/features/trips/data/models/public_trip_model.dart';
import 'package:memories_app/features/trips/data/models/trip_model.dart';

class TripsRemoteDataSource {
  const TripsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TripModel>> getTrips() async {
    final data = await _apiClient.get('/api/v1/trips');
    final tripsList = data['trips'] as List<dynamic>;
    return tripsList
        .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripDetailModel> createTrip({
    required String title,
    required String destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? vibes,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'destination': destination,
    };
    if (startDate != null) {
      body['start_date'] =
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    if (endDate != null) {
      body['end_date'] =
          '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    if (vibes != null && vibes.isNotEmpty) {
      body['vibes'] = vibes;
    }
    final data = await _apiClient.post('/api/v1/trips', data: body);
    return TripDetailModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TripDetailModel> getTripDetail(String id) async {
    final data = await _apiClient.get('/api/v1/trips/$id');
    return TripDetailModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MemberModel> addMember(String tripId, String userId) async {
    final data = await _apiClient.post(
      '/api/v1/trips/$tripId/members',
      data: {'user_id': userId},
    );
    return MemberModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PublicProfileModel>> searchUsers(String q) async {
    final data = await _apiClient.get(
      '/api/v1/users/search',
      queryParameters: {'q': q},
    );
    final usersList = data['users'] as List<dynamic>;
    return usersList
        .map((e) => PublicProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ItineraryItemModel>> generateItinerary(String tripId) async {
    final data = await _apiClient.post('/api/v1/trips/$tripId/ai/generate');
    final itemsList = data['items'] as List<dynamic>;
    return itemsList
        .map((e) => ItineraryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> refineItinerary(
    String tripId,
    String message,
    List<Map<String, String>> history,
  ) async {
    final data = await _apiClient.post(
      '/api/v1/trips/$tripId/ai/refine',
      data: {
        'message': message,
        'history': history,
      },
    );
    return (data as Map<String, dynamic>)['reply'] as String;
  }

  Future<List<ItineraryItemModel>> getItems(String tripId) async {
    final data = await _apiClient.get('/api/v1/trips/$tripId/items');
    final itemsList = data['items'] as List<dynamic>;
    return itemsList
        .map((e) => ItineraryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ItineraryItemModel> updateItem(
    String tripId,
    String itemId,
    Map<String, dynamic> body,
  ) async {
    final data = await _apiClient.patch(
      '/api/v1/trips/$tripId/items/$itemId',
      data: body,
    );
    return ItineraryItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteItem(String tripId, String itemId) async {
    await _apiClient.delete('/api/v1/trips/$tripId/items/$itemId');
  }

  Future<PublicTripModel> getPublicTrip(String id) async {
    final data = await _apiClient.get('/api/v1/public/trips/$id');
    return PublicTripModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> publishTrip(String id) async {
    await _apiClient.post('/api/v1/trips/$id/publish');
  }

  Future<void> unpublishTrip(String id) async {
    await _apiClient.post('/api/v1/trips/$id/unpublish');
  }
}
