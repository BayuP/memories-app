import 'package:memories_app/features/story/domain/entities/story_entity.dart';

class StoryModel {
  const StoryModel({
    required this.id,
    required this.tripId,
    this.title,
    this.body,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tripId;
  final String? title;
  final String? body;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      title: json['title'] as String?,
      body: json['body'] as String?,
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  StoryEntity toEntity() => StoryEntity(
        id: id,
        tripId: tripId,
        title: title,
        body: body,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
