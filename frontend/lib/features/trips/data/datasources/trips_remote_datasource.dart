import 'package:memories_app/core/demo/demo_flag.dart';
import 'package:memories_app/core/demo/mock_data.dart';
import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/features/trips/data/models/public_trip_model.dart';
import 'package:memories_app/features/trips/data/models/trip_model.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

class TripsRemoteDataSource {
  TripsRemoteDataSource(this._apiClient, {required bool demoMode})
      : _demoMode = demoMode;

  final ApiClient _apiClient;
  final bool _demoMode;

  // ---------------------------------------------------------------------------
  // Helpers — convert domain entities back to the model types used by the
  // repository layer so demo mode can reuse the same toEntity() path.
  // ---------------------------------------------------------------------------

  TripDetailModel _tripDetailToModel(TripDetailEntity detail) {
    final t = detail.trip;
    final tripModel = TripModel(
      id: t.id,
      ownerId: t.ownerId,
      title: t.title,
      destination: t.destination,
      startDate: t.startDate,
      endDate: t.endDate,
      vibes: t.vibes,
      status: t.status == TripStatus.published ? 'published' : 'active',
      createdAt: t.createdAt,
    );
    final memberModels = detail.members
        .map(
          (m) => MemberModel(
            userId: m.userId,
            handle: m.handle,
            displayName: m.displayName,
            role: m.role,
            joinedAt: DateTime(2024, 1, 1),
          ),
        )
        .toList();
    return TripDetailModel(trip: tripModel, members: memberModels);
  }

  ItineraryItemModel _itemToModel(ItineraryItemEntity e) {
    return ItineraryItemModel(
      id: e.id,
      tripId: e.tripId,
      day: e.day,
      title: e.title,
      startTime: e.startTime,
      endTime: e.endTime,
      description: e.description,
      locationName: e.locationName,
      lat: e.lat,
      lng: e.lng,
      category: e.category,
      source: e.source,
      createdAt: DateTime(2024, 5, 1),
    );
  }

  // ---------------------------------------------------------------------------
  // API methods
  // ---------------------------------------------------------------------------

  Future<List<TripModel>> getTrips() async {
    // DEMO: return mock trips list
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockTripsList.map<TripModel>((t) {
        return TripModel(
          id: t.id,
          ownerId: t.ownerId,
          title: t.title,
          destination: t.destination,
          startDate: t.startDate,
          endDate: t.endDate,
          vibes: t.vibes,
          status: t.status == TripStatus.published ? 'published' : 'active',
          createdAt: t.createdAt,
        );
      }).toList();
    }
    // DEMO: real API call below
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
    // DEMO: return mock Bali trip detail as the "newly created" trip
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _tripDetailToModel(mockTripBaliDetail);
    }
    // DEMO: real API call below
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
    // DEMO: return matching mock trip detail
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _tripDetailToModel(mockTripDetailFor(id));
    }
    // DEMO: real API call below
    final data = await _apiClient.get('/api/v1/trips/$id');
    return TripDetailModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MemberModel> addMember(String tripId, String userId) async {
    // DEMO: return mock member (no-op in demo)
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MemberModel(
        userId: userId,
        handle: 'demo_user',
        displayName: 'Demo User',
        role: 'member',
        joinedAt: DateTime.now(),
      );
    }
    // DEMO: real API call below
    final data = await _apiClient.post(
      '/api/v1/trips/$tripId/members',
      data: {'user_id': userId},
    );
    return MemberModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PublicProfileModel>> searchUsers(String q) async {
    // DEMO: filter mock users by query
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 250));
      return mockSearchUsersFor(q).map((u) {
        return PublicProfileModel(
          id: u.id,
          handle: u.handle,
          displayName: u.displayName,
          avatarUrl: u.avatarUrl,
        );
      }).toList();
    }
    // DEMO: real API call below
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
    // DEMO: return Bali itinerary (the "AI-generated" result)
    if (kDemoMode || kStubAi) {
      await Future.delayed(const Duration(seconds: 3)); // simulate AI latency
      return mockBaliItinerary.map(_itemToModel).toList();
    }
    // DEMO: real API call below
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
    // DEMO: echo a canned AI reply
    if (kDemoMode || kStubAi) {
      await Future.delayed(const Duration(milliseconds: 800));
      return 'Got it! In demo mode the itinerary is fixed, but in the real app '
          'I would refine the plan based on your message: "$message"';
    }
    // DEMO: real API call below
    final data = await _apiClient.post(
      '/api/v1/trips/$tripId/ai/refine',
      data: {
        'message': message,
        'history': history,
      },
    );
    return (data as Map<String, dynamic>)['reply'] as String;
  }

  Future<ItineraryItemModel> createItem(
    String tripId,
    Map<String, dynamic> body,
  ) async {
    // DEMO: build a local user item without hitting the backend
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 250));
      return ItineraryItemModel(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        tripId: tripId,
        day: (body['day'] as num?)?.toInt() ?? 1,
        title: (body['title'] as String?) ?? '',
        startTime: body['start_time'] as String?,
        endTime: body['end_time'] as String?,
        description: body['description'] as String?,
        locationName: body['location_name'] as String?,
        lat: (body['lat'] as num?)?.toDouble(),
        lng: (body['lng'] as num?)?.toDouble(),
        category: body['category'] as String?,
        source: 'user',
        createdAt: DateTime.now(),
      );
    }
    // DEMO: real API call below
    final data = await _apiClient.post(
      '/api/v1/trips/$tripId/items',
      data: body,
    );
    return ItineraryItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ItineraryItemModel>> getItems(String tripId) async {
    // DEMO: return matching mock itinerary items
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockItineraryFor(tripId).map(_itemToModel).toList();
    }
    // DEMO: real API call below
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
    // DEMO: find the item in mock data and return it with applied edits
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 250));
      final items = mockItineraryFor(tripId);
      final original = items.firstWhere(
        (i) => i.id == itemId,
        orElse: () => items.first,
      );
      // Build an updated entity with the provided body fields
      final updated = ItineraryItemEntity(
        id: original.id,
        tripId: original.tripId,
        day: original.day,
        title: (body['title'] as String?) ?? original.title,
        startTime: (body['start_time'] as String?) ?? original.startTime,
        endTime: (body['end_time'] as String?) ?? original.endTime,
        description: (body['description'] as String?) ?? original.description,
        locationName: original.locationName,
        lat: original.lat,
        lng: original.lng,
        category: (body['category'] as String?) ?? original.category,
        source: original.source,
      );
      return _itemToModel(updated);
    }
    // DEMO: real API call below
    final data = await _apiClient.patch(
      '/api/v1/trips/$tripId/items/$itemId',
      data: body,
    );
    return ItineraryItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteItem(String tripId, String itemId) async {
    // DEMO: no-op (in-memory state handled by the notifier)
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    // DEMO: real API call below
    await _apiClient.delete('/api/v1/trips/$tripId/items/$itemId');
  }

  Future<PublicTripModel> getPublicTrip(String id) async {
    // DEMO: wrap mock Bali trip as a public trip
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final detail = mockTripDetailFor(id);
      final items = mockItineraryFor(id);
      return PublicTripModel.fromDemoData(detail, items);
    }
    // DEMO: real API call below
    final data = await _apiClient.get('/api/v1/public/trips/$id');
    return PublicTripModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> publishTrip(String id) async {
    // DEMO: no-op
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    // DEMO: real API call below
    await _apiClient.post('/api/v1/trips/$id/publish');
  }

  Future<void> unpublishTrip(String id) async {
    // DEMO: no-op
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    // DEMO: real API call below
    await _apiClient.post('/api/v1/trips/$id/unpublish');
  }
}
