class MediaEntity {
  const MediaEntity({
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
}

class CheckinMemoryEntity {
  const CheckinMemoryEntity({
    this.note,
    this.mood,
    this.sharedWith,
  });

  final String? note;
  final String? mood;
  final String? sharedWith;
}

class CheckinLogisticsEntity {
  const CheckinLogisticsEntity({
    this.cost,
    this.currency,
    this.notes,
  });

  final double? cost;
  final String? currency;
  final String? notes;
}

class CheckinRecommendationEntity {
  const CheckinRecommendationEntity({
    this.title,
    this.body,
    required this.tags,
    this.rating,
  });

  final String? title;
  final String? body;
  final List<String> tags;
  final int? rating;
}

class CheckinEntity {
  const CheckinEntity({
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
  final CheckinMemoryEntity? memory;
  final CheckinLogisticsEntity? logistics;
  final CheckinRecommendationEntity? recommendation;
  final List<MediaEntity> media;
}
