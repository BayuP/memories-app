import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

// ---------------------------------------------------------------------------
// allMemoriesProvider
//
// Fans out over all trips, fetches per-trip checkins, concatenates,
// keeps only checkins that have at least one media item, and sorts by
// capturedAt descending.
// ---------------------------------------------------------------------------

final allMemoriesProvider = FutureProvider<List<CheckinEntity>>((ref) async {
  final tripsAsync = await ref.watch(tripsProvider.future);

  final allCheckins = <CheckinEntity>[];
  for (final trip in tripsAsync) {
    final checkins =
        await ref.watch(tripCheckinsProvider(trip.id).future);
    allCheckins.addAll(checkins);
  }

  // Keep only checkins with media
  final withMedia = allCheckins.where((c) => c.media.isNotEmpty).toList();

  // Sort newest first
  withMedia.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

  return withMedia;
});
