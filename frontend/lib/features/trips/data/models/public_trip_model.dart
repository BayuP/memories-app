import 'package:memories_app/features/trips/data/models/trip_model.dart';
import 'package:memories_app/features/trips/domain/entities/public_trip_entity.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

class PublicMediaModel {
  const PublicMediaModel({
    required this.id,
    required this.url,
    required this.mime,
  });

  final String id;
  final String url;
  final String mime;

  factory PublicMediaModel.fromJson(Map<String, dynamic> json) {
    return PublicMediaModel(
      id: json['id'] as String,
      url: json['url'] as String,
      mime: json['mime'] as String? ?? 'image/jpeg',
    );
  }

  PublicMediaEntity toEntity() {
    return PublicMediaEntity(id: id, url: url, mime: mime);
  }
}

class PublicCheckinRecModel {
  const PublicCheckinRecModel({
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
  final List<PublicMediaModel> media;
  final bool isSpontaneous;

  factory PublicCheckinRecModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final List<String> tagsList = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final mediaRaw = json['media'];
    final List<PublicMediaModel> mediaList = mediaRaw is List
        ? mediaRaw
            .map((e) => PublicMediaModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <PublicMediaModel>[];

    return PublicCheckinRecModel(
      checkinId: json['checkin_id'] as String,
      itineraryItemId: json['itinerary_item_id'] as String?,
      day: (json['day'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tags: tagsList,
      rating: json['rating'] != null ? (json['rating'] as num).toInt() : null,
      media: mediaList,
      isSpontaneous: json['is_spontaneous'] as bool? ?? false,
    );
  }

  PublicCheckinRecEntity toEntity() {
    return PublicCheckinRecEntity(
      checkinId: checkinId,
      itineraryItemId: itineraryItemId,
      day: day,
      title: title,
      body: body,
      tags: tags,
      rating: rating,
      media: media.map((m) => m.toEntity()).toList(),
      isSpontaneous: isSpontaneous,
    );
  }
}

class PublicTripModel {
  const PublicTripModel({
    required this.trip,
    required this.members,
    required this.items,
    required this.checkinRecommendations,
  });

  final TripModel trip;
  final List<MemberModel> members;
  final List<ItineraryItemModel> items;
  final List<PublicCheckinRecModel> checkinRecommendations;

  /// DEMO: Construct from in-memory domain entities (no JSON parsing needed).
  factory PublicTripModel.fromDemoData(
    TripDetailEntity detail,
    List<ItineraryItemEntity> items,
  ) {
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
    final itemModels = items
        .map(
          (i) => ItineraryItemModel(
            id: i.id,
            tripId: i.tripId,
            day: i.day,
            title: i.title,
            startTime: i.startTime,
            endTime: i.endTime,
            description: i.description,
            locationName: i.locationName,
            lat: i.lat,
            lng: i.lng,
            source: i.source,
            createdAt: DateTime(2024, 5, 1),
          ),
        )
        .toList();
    return PublicTripModel(
      trip: tripModel,
      members: memberModels,
      items: itemModels,
      checkinRecommendations: const [],
    );
  }

  factory PublicTripModel.fromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'] as Map<String, dynamic>;
    final membersJson = json['members'] as List<dynamic>? ?? [];
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final recsJson = json['checkin_recommendations'] as List<dynamic>? ?? [];

    return PublicTripModel(
      trip: TripModel.fromJson(tripJson),
      members: membersJson
          .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      items: itemsJson
          .map((i) => ItineraryItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      checkinRecommendations: recsJson
          .map((r) =>
              PublicCheckinRecModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  PublicTripEntity toEntity() {
    return PublicTripEntity(
      trip: trip.toEntity(),
      members: members.map((m) => m.toEntity()).toList(),
      items: items.map((i) => i.toEntity()).toList(),
      checkinRecommendations:
          checkinRecommendations.map((r) => r.toEntity()).toList(),
    );
  }
}
