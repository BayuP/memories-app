enum TripStatus { active, published }

class TripEntity {
  const TripEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.vibes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> vibes;
  final TripStatus status;
  final DateTime createdAt;
}

class TripDetailEntity {
  const TripDetailEntity({
    required this.trip,
    required this.members,
  });

  final TripEntity trip;
  final List<MemberEntity> members;
}

class MemberEntity {
  const MemberEntity({
    required this.userId,
    required this.handle,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String handle;
  final String displayName;
  final String role;
}

class ItineraryItemEntity {
  const ItineraryItemEntity({
    required this.id,
    required this.tripId,
    required this.day,
    required this.title,
    this.startTime,
    this.endTime,
    this.description,
    this.locationName,
    this.lat,
    this.lng,
    this.category,
    required this.source,
  });

  final String id;
  final String tripId;
  final int day;
  final String title;
  final String? startTime;
  final String? endTime;
  final String? description;
  final String? locationName;
  final double? lat;
  final double? lng;
  final String? category;
  final String source;
}

class PublicProfileEntity {
  const PublicProfileEntity({
    required this.id,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String handle;
  final String displayName;
  final String? avatarUrl;
}
