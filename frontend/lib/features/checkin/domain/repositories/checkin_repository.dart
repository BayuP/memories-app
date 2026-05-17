import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';

abstract class CheckinRepository {
  Future<CheckinEntity> createCheckin({
    required String tripId,
    required String kind,
    required DateTime capturedAt,
    String? itineraryItemId,
    double? lat,
    double? lng,
  });

  Future<CheckinEntity> getCheckin(String id);

  Future<CheckinMemoryEntity> updateMemory(
    String id, {
    String? note,
    String? mood,
    String? sharedWith,
  });

  Future<CheckinLogisticsEntity> updateLogistics(
    String id, {
    double? cost,
    String? currency,
    String? notes,
  });

  Future<CheckinRecommendationEntity> updateRecommendation(
    String id, {
    String? title,
    String? body,
    List<String>? tags,
    int? rating,
  });

  Future<Map<String, String>> getMediaUploadUrl(String mime);

  Future<void> uploadMediaToR2(
    String uploadUrl,
    List<int> fileBytes,
    String mime,
  );

  Future<MediaEntity> attachMedia(
    String mediaId, {
    String? checkinId,
    int? width,
    int? height,
    DateTime? takenAt,
    double? lat,
    double? lng,
  });

  Future<void> deleteMedia(String mediaId);
}
