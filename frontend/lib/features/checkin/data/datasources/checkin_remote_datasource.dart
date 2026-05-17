import 'package:dio/dio.dart';
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
    final data = await _apiClient.get('/api/v1/checkins/$id');
    return CheckinModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckinMemoryModel> updateMemory(
    String id, {
    String? note,
    String? mood,
    String? sharedWith,
  }) async {
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
    await _apiClient.delete('/api/v1/media/$mediaId');
  }
}
