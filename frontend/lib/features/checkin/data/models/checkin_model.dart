import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';

class MediaModel {
  const MediaModel({
    required this.id,
    required this.r2Key,
    required this.mime,
    required this.url,
    this.width,
    this.height,
    this.takenAt,
    this.lat,
    this.lng,
  });

  final String id;
  final String r2Key;
  final String mime;
  final String url;
  final int? width;
  final int? height;
  final DateTime? takenAt;
  final double? lat;
  final double? lng;

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String,
      r2Key: json['r2_key'] as String,
      mime: json['mime'] as String,
      url: json['url'] as String,
      width: json['width'] != null ? (json['width'] as num).toInt() : null,
      height: json['height'] != null ? (json['height'] as num).toInt() : null,
      takenAt: json['taken_at'] != null
          ? DateTime.tryParse(json['taken_at'] as String)
          : null,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }

  MediaEntity toEntity() {
    return MediaEntity(
      id: id,
      r2Key: r2Key,
      mime: mime,
      url: url,
      width: width,
      height: height,
      takenAt: takenAt,
      lat: lat,
      lng: lng,
    );
  }
}

class CheckinMemoryModel {
  const CheckinMemoryModel({
    this.note,
    this.mood,
    this.sharedWith,
  });

  final String? note;
  final String? mood;
  final String? sharedWith;

  factory CheckinMemoryModel.fromJson(Map<String, dynamic> json) {
    return CheckinMemoryModel(
      note: json['note'] as String?,
      mood: json['mood'] as String?,
      sharedWith: json['shared_with'] as String?,
    );
  }

  CheckinMemoryEntity toEntity() {
    return CheckinMemoryEntity(
      note: note,
      mood: mood,
      sharedWith: sharedWith,
    );
  }
}

class CheckinLogisticsModel {
  const CheckinLogisticsModel({
    this.cost,
    this.currency,
    this.notes,
  });

  final double? cost;
  final String? currency;
  final String? notes;

  factory CheckinLogisticsModel.fromJson(Map<String, dynamic> json) {
    return CheckinLogisticsModel(
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      notes: json['notes'] as String?,
    );
  }

  CheckinLogisticsEntity toEntity() {
    return CheckinLogisticsEntity(
      cost: cost,
      currency: currency,
      notes: notes,
    );
  }
}

class CheckinRecommendationModel {
  const CheckinRecommendationModel({
    this.title,
    this.body,
    required this.tags,
    this.rating,
  });

  final String? title;
  final String? body;
  final List<String> tags;
  final int? rating;

  factory CheckinRecommendationModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final List<String> tagsList = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : <String>[];
    return CheckinRecommendationModel(
      title: json['title'] as String?,
      body: json['body'] as String?,
      tags: tagsList,
      rating: json['rating'] != null ? (json['rating'] as num).toInt() : null,
    );
  }

  CheckinRecommendationEntity toEntity() {
    return CheckinRecommendationEntity(
      title: title,
      body: body,
      tags: tags,
      rating: rating,
    );
  }
}

class CheckinModel {
  const CheckinModel({
    required this.id,
    required this.tripId,
    this.itineraryItemId,
    required this.kind,
    required this.capturedAt,
    this.lat,
    this.lng,
    this.memory,
    this.logistics,
    this.recommendation,
    required this.media,
  });

  final String id;
  final String tripId;
  final String? itineraryItemId;
  final String kind;
  final DateTime capturedAt;
  final double? lat;
  final double? lng;
  final CheckinMemoryModel? memory;
  final CheckinLogisticsModel? logistics;
  final CheckinRecommendationModel? recommendation;
  final List<MediaModel> media;

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'] as List<dynamic>? ?? [];
    final memoryJson = json['memory'] as Map<String, dynamic>?;
    final logisticsJson = json['logistics'] as Map<String, dynamic>?;
    final recommendationJson = json['recommendation'] as Map<String, dynamic>?;

    return CheckinModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      itineraryItemId: json['itinerary_item_id'] as String?,
      kind: json['kind'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      memory:
          memoryJson != null ? CheckinMemoryModel.fromJson(memoryJson) : null,
      logistics: logisticsJson != null
          ? CheckinLogisticsModel.fromJson(logisticsJson)
          : null,
      recommendation: recommendationJson != null
          ? CheckinRecommendationModel.fromJson(recommendationJson)
          : null,
      media:
          mediaRaw.map((e) => MediaModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  CheckinEntity toEntity() {
    return CheckinEntity(
      id: id,
      tripId: tripId,
      itineraryItemId: itineraryItemId,
      kind: kind,
      capturedAt: capturedAt,
      lat: lat,
      lng: lng,
      memory: memory?.toEntity(),
      logistics: logistics?.toEntity(),
      recommendation: recommendation?.toEntity(),
      media: media.map((m) => m.toEntity()).toList(),
    );
  }
}
