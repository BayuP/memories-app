import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

class PublicMediaEntity {
  const PublicMediaEntity({
    required this.id,
    required this.url,
    required this.mime,
  });

  final String id;
  final String url;
  final String mime;
}

class PublicCheckinRecEntity {
  const PublicCheckinRecEntity({
    required this.checkinId,
    this.itineraryItemId,
    required this.day,
    required this.title,
    required this.body,
    required this.tags,
    this.rating,
    required this.media,
    required this.isSpontaneous,
  });

  final String checkinId;
  final String? itineraryItemId;
  final int day;
  final String title;
  final String body;
  final List<String> tags;
  final int? rating;
  final List<PublicMediaEntity> media;
  final bool isSpontaneous;
}

class PublicTripEntity {
  const PublicTripEntity({
    required this.trip,
    required this.members,
    required this.items,
    required this.checkinRecommendations,
  });

  final TripEntity trip;
  final List<MemberEntity> members;
  final List<ItineraryItemEntity> items;
  final List<PublicCheckinRecEntity> checkinRecommendations;
}
