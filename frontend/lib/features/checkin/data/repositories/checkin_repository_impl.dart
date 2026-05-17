import 'package:memories_app/features/checkin/data/datasources/checkin_remote_datasource.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/domain/repositories/checkin_repository.dart';

class CheckinRepositoryImpl implements CheckinRepository {
  const CheckinRepositoryImpl(this._dataSource);

  final CheckinRemoteDataSource _dataSource;

  @override
  Future<CheckinEntity> createCheckin({
    required String tripId,
    required String kind,
    required DateTime capturedAt,
    String? itineraryItemId,
    double? lat,
    double? lng,
  }) async {
    final model = await _dataSource.createCheckin(
      tripId: tripId,
      kind: kind,
      capturedAt: capturedAt,
      itineraryItemId: itineraryItemId,
      lat: lat,
      lng: lng,
    );
    return model.toEntity();
  }

  @override
  Future<CheckinEntity> getCheckin(String id) async {
    final model = await _dataSource.getCheckin(id);
    return model.toEntity();
  }

  @override
  Future<CheckinMemoryEntity> updateMemory(
    String id, {
    String? note,
    String? mood,
    String? sharedWith,
  }) async {
    final model = await _dataSource.updateMemory(
      id,
      note: note,
      mood: mood,
      sharedWith: sharedWith,
    );
    return model.toEntity();
  }

  @override
  Future<CheckinLogisticsEntity> updateLogistics(
    String id, {
    double? cost,
    String? currency,
    String? notes,
  }) async {
    final model = await _dataSource.updateLogistics(
      id,
      cost: cost,
      currency: currency,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<CheckinRecommendationEntity> updateRecommendation(
    String id, {
    String? title,
    String? body,
    List<String>? tags,
    int? rating,
  }) async {
    final model = await _dataSource.updateRecommendation(
      id,
      title: title,
      body: body,
      tags: tags,
      rating: rating,
    );
    return model.toEntity();
  }

  @override
  Future<Map<String, String>> getMediaUploadUrl(String mime) async {
    return _dataSource.getMediaUploadUrl(mime);
  }

  @override
  Future<void> uploadMediaToR2(
    String uploadUrl,
    List<int> fileBytes,
    String mime,
  ) async {
    await _dataSource.uploadMediaToR2(uploadUrl, fileBytes, mime);
  }

  @override
  Future<MediaEntity> attachMedia(
    String mediaId, {
    String? checkinId,
    int? width,
    int? height,
    DateTime? takenAt,
    double? lat,
    double? lng,
  }) async {
    final model = await _dataSource.attachMedia(
      mediaId,
      checkinId: checkinId,
      width: width,
      height: height,
      takenAt: takenAt,
      lat: lat,
      lng: lng,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    await _dataSource.deleteMedia(mediaId);
  }
}
