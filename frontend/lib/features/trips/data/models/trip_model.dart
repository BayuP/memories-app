import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

class TripModel {
  const TripModel({
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
  final String status;
  final DateTime createdAt;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final vibesRaw = json['vibes'];
    final List<String> vibesList = vibesRaw is List
        ? vibesRaw.map((e) => e.toString()).toList()
        : <String>[];

    return TripModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      title: json['title'] as String,
      destination: json['destination'] as String,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      vibes: vibesList,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  TripEntity toEntity() {
    return TripEntity(
      id: id,
      ownerId: ownerId,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      vibes: vibes,
      status: status == 'published' ? TripStatus.published : TripStatus.active,
      createdAt: createdAt,
    );
  }
}

class TripDetailModel {
  const TripDetailModel({
    required this.trip,
    required this.members,
  });

  final TripModel trip;
  final List<MemberModel> members;

  factory TripDetailModel.fromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'] as Map<String, dynamic>;
    final membersJson = json['members'] as List<dynamic>? ?? [];
    return TripDetailModel(
      trip: TripModel.fromJson(tripJson),
      members: membersJson
          .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  TripDetailEntity toEntity() {
    return TripDetailEntity(
      trip: trip.toEntity(),
      members: members.map((m) => m.toEntity()).toList(),
    );
  }
}

class MemberModel {
  const MemberModel({
    required this.userId,
    required this.handle,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String handle;
  final String displayName;
  final String role;
  final DateTime joinedAt;

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final joinedRaw =
        (json['joined_at'] ?? json['created_at']) as String?;
    return MemberModel(
      userId: json['user_id'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: joinedRaw != null
          ? (DateTime.tryParse(joinedRaw) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  MemberEntity toEntity() {
    return MemberEntity(
      userId: userId,
      handle: handle,
      displayName: displayName,
      role: role,
    );
  }
}

class ItineraryItemModel {
  const ItineraryItemModel({
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
    required this.createdAt,
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
  final DateTime createdAt;

  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) {
    return ItineraryItemModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      day: (json['day'] as num).toInt(),
      title: json['title'] as String,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      description: json['description'] as String?,
      locationName: json['location_name'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      category: json['category'] as String?,
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ItineraryItemEntity toEntity() {
    return ItineraryItemEntity(
      id: id,
      tripId: tripId,
      day: day,
      title: title,
      startTime: startTime,
      endTime: endTime,
      description: description,
      locationName: locationName,
      lat: lat,
      lng: lng,
      category: category,
      source: source,
    );
  }
}

class PublicProfileModel {
  const PublicProfileModel({
    required this.id,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String handle;
  final String displayName;
  final String? avatarUrl;

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'] as String,
      handle: json['handle'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  PublicProfileEntity toEntity() {
    return PublicProfileEntity(
      id: id,
      handle: handle,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
