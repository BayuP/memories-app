class StoryEntity {
  const StoryEntity({
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
}
