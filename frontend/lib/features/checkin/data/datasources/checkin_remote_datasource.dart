import 'package:dio/dio.dart';
import 'package:memories_app/core/demo/demo_flag.dart';
import 'package:memories_app/core/demo/mock_data.dart';
import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/features/checkin/data/models/checkin_model.dart';

class CheckinRemoteDataSource {
  const CheckinRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CheckinModel> createCheckin({
    required String tripId,
    required String kind,
    required DateTime capturedAt,
    String? itineraryItemId,
    double? lat,
    double? lng,
  }) async {
    // DEMO: return a stub checkin (no server round-trip)
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return CheckinModel(
        id: 'checkin-demo-${DateTime.now().millisecondsSinceEpoch}',
        tripId: tripId,
        itineraryItemId: itineraryItemId,
        kind: kind,
        capturedAt: capturedAt,
        lat: lat,
        lng: lng,
        memory: null,
        logistics: null,
        recommendation: null,
        media: const [],
      );
    }
    // DEMO: real API call below
    final body = <String, dynamic>{
      'kind': kind,
      'captured_at': capturedAt.toUtc().toIso8601String(),
    };
    if (itineraryItemId != null) body['itinerary_item_id'] = itineraryItemId;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;

    final data = await _apiClient.post('/api/v1/trips/$tripId/checkins', data: body);
    return CheckinModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckinModel> getCheckin(String id) async {
    // DEMO: look up in mock data
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 250));
      final entity = mockCheckinById(id);
      return CheckinModel(
        id: entity.id,
        tripId: entity.tripId,
        itineraryItemId: entity.itineraryItemId,
        kind: entity.kind,
        capturedAt: entity.capturedAt,
        lat: entity.lat,
        lng: entity.lng,
        memory: entity.memory == null
            ? null
            : CheckinMemoryModel(
                note: entity.memory!.note,
                mood: entity.memory!.mood,
                sharedWith: entity.memory!.sharedWith,
              ),
        logistics: entity.logistics == null
            ? null
            : CheckinLogisticsModel(
                cost: entity.logistics!.cost,
                currency: entity.logistics!.currency,
                notes: entity.logistics!.notes,
              ),
        recommendation: entity.recommendation == null
            ? null
            : CheckinRecommendationModel(
                title: entity.recommendation!.title,
                body: entity.recommendation!.body,
                tags: entity.recommendation!.tags,
                rating: entity.recommendation!.rating,
              ),
        media: entity.media
            .map(
              (m) => MediaModel(
                id: m.id,
                r2Key: m.r2Key,
                mime: m.mime,
                url: m.url,
                width: m.width,
                height: m.height,
                takenAt: m.takenAt,
                lat: m.lat,
                lng: m.lng,
              ),
            )
            .toList(),
      );
    }
    // DEMO: real API call below
    final data = await _apiClient.get('/api/v1/checkins/$id');
    return CheckinModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckinMemoryModel> updateMemory(
    String id, {
    String? note,
    String? mood,
    String? sharedWith,
  }) async {
    // DEMO: return stub memory model
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return CheckinMemoryModel(note: note, mood: mood, sharedWith: sharedWith);
    }
    // DEMO: real API call below
    final body = <String, dynamic>{};
    if (note != null) body['note'] = note;
    if (mood != null) body['mood'] = mood;
    if (sharedWith != null) body['shared_with'] = sharedWith;

    final data = await _apiClient.put('/api/v1/checkins/$id/memory', data: body);
    return CheckinMemoryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckinLogisticsModel> updateLogistics(
    String id, {
    double? cost,
    String? currency,
    String? notes,
  }) async {
    // DEMO: return stub logistics model
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return CheckinLogisticsModel(cost: cost, currency: currency, notes: notes);
    }
    // DEMO: real API call below
    final body = <String, dynamic>{};
    if (cost != null) body['cost'] = cost;
    if (currency != null) body['currency'] = currency;
    if (notes != null) body['notes'] = notes;

    final data = await _apiClient.put('/api/v1/checkins/$id/logistics', data: body);
    return CheckinLogisticsModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckinRecommendationModel> updateRecommendation(
    String id, {
    String? title,
    String? body,
    List<String>? tags,
    int? rating,
  }) async {
    // DEMO: return stub recommendation model
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return CheckinRecommendationModel(
        title: title,
        body: body,
        tags: tags ?? const [],
        rating: rating,
      );
    }
    // DEMO: real API call below
    final reqBody = <String, dynamic>{};
    if (title != null) reqBody['title'] = title;
    if (body != null) reqBody['body'] = body;
    if (tags != null) reqBody['tags'] = tags;
    if (rating != null) reqBody['rating'] = rating;

    final data = await _apiClient.put(
      '/api/v1/checkins/$id/recommendation',
      data: reqBody,
    );
    return CheckinRecommendationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, String>> getMediaUploadUrl(String mime) async {
    // DEMO: return fake upload URL (upload step is skipped in demo)
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 100));
      return {
        'media_id': 'media-demo-${DateTime.now().millisecondsSinceEpoch}',
        'upload_url': 'https://demo.invalid/upload',
        'r2_key': 'demo/placeholder.jpg',
      };
    }
    // DEMO: real API call below
    final data = await _apiClient.post(
      '/api/v1/media/upload-url',
      data: {'mime': mime},
    );
    final map = data as Map<String, dynamic>;
    return {
      'media_id': map['media_id'] as String,
      'upload_url': map['upload_url'] as String,
      'r2_key': map['r2_key'] as String,
    };
  }

  Future<void> uploadMediaToR2(
    String uploadUrl,
    List<int> fileBytes,
    String mime,
  ) async {
    // DEMO: skip actual upload
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }
    // DEMO: real upload below
    final bytes = List<int>.from(fileBytes);
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': mime,
          'Content-Length': bytes.length,
        },
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<MediaModel> attachMedia(
    String mediaId, {
    String? checkinId,
    int? width,
    int? height,
    DateTime? takenAt,
    double? lat,
    double? lng,
  }) async {
    // DEMO: return stub media model (no server attachment)
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 100));
      return MediaModel(
        id: mediaId,
        r2Key: 'demo/placeholder.jpg',
        mime: 'image/jpeg',
        url: 'https://picsum.photos/seed/$mediaId/800/600',
        width: width,
        height: height,
        takenAt: takenAt,
        lat: lat,
        lng: lng,
      );
    }
    // DEMO: real API call below
    final body = <String, dynamic>{};
    if (checkinId != null) body['checkin_id'] = checkinId;
    if (width != null) body['width'] = width;
    if (height != null) body['height'] = height;
    if (takenAt != null) body['taken_at'] = takenAt.toUtc().toIso8601String();
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;

    final data = await _apiClient.patch('/api/v1/media/$mediaId', data: body);
    return MediaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMedia(String mediaId) async {
    // DEMO: no-op
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }
    // DEMO: real API call below
    await _apiClient.delete('/api/v1/media/$mediaId');
  }
}
