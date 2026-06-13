import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Trip Map Page
//
// Renders two distinct marker types:
//   1. Check-in photo pins  — circle with photo thumbnail or place icon (green)
//   2. Itinerary item pins  — square-cornered marker with category emoji or
//                             a map-pin icon (amber/ochre), tapping shows an
//                             _ItineraryPinCard instead of navigating.
//
// Camera / fit:
//   CameraFit.bounds across ALL points (check-ins + itinerary items) so the
//   initial view always encompasses everything. Falls back to a single-point
//   initialCenter when there is only one point.
// ---------------------------------------------------------------------------

class TripMapPage extends ConsumerStatefulWidget {
  const TripMapPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends ConsumerState<TripMapPage> {
  CheckinEntity? _selectedCheckin;
  ItineraryItemEntity? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final checkinsAsync = ref.watch(tripCheckinsProvider(widget.tripId));
    final itemsAsync = ref.watch(itineraryItemsProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Map', style: AppTextStyles.appBarTitle),
      ),
      body: checkinsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
        error: (e, _) => AppErrorState(
          message: 'Could not load map data',
          onRetry: () => ref.invalidate(tripCheckinsProvider(widget.tripId)),
        ),
        data: (checkins) {
          final geotaggedCheckins = checkins
              .where((c) => c.lat != null && c.lng != null)
              .toList();

          // Itinerary items — use current value; show nothing if still loading.
          final geotaggedItems = itemsAsync.valueOrNull
                  ?.where((i) => i.lat != null && i.lng != null)
                  .toList() ??
              [];

          final hasPoints =
              geotaggedCheckins.isNotEmpty || geotaggedItems.isNotEmpty;

          if (!hasPoints) {
            return const AppEmptyState(
              emoji: '🗺️',
              title: 'No map pins yet',
              subtitle:
                  'Check in with location enabled or add geocoded activities to see them here.',
            );
          }

          return Stack(
            children: [
              _buildMap(geotaggedCheckins, geotaggedItems),
              if (_selectedCheckin != null)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom +
                      AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _MapMemoryCard(
                    checkin: _selectedCheckin!,
                    onTap: () => context
                        .push('/memories/${_selectedCheckin!.id}'),
                    onClose: () => setState(() {
                      _selectedCheckin = null;
                    }),
                  ),
                ),
              if (_selectedItem != null)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom +
                      AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _ItineraryPinCard(
                    item: _selectedItem!,
                    onClose: () => setState(() {
                      _selectedItem = null;
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(
    List<CheckinEntity> checkins,
    List<ItineraryItemEntity> items,
  ) {
    // Collect all LatLng points.
    final allPoints = [
      ...checkins.map((c) => LatLng(c.lat!, c.lng!)),
      ...items.map((i) => LatLng(i.lat!, i.lng!)),
    ];

    // Build MapOptions: use CameraFit.bounds when there are multiple points,
    // or a plain initialCenter + zoom for a single point.
    MapOptions mapOptions;
    if (allPoints.length == 1) {
      mapOptions = MapOptions(
        initialCenter: allPoints.first,
        initialZoom: 13,
        onTap: (_, __) => setState(() {
          _selectedCheckin = null;
          _selectedItem = null;
        }),
      );
    } else {
      // Compute bounds.
      final lats = allPoints.map((p) => p.latitude).toList();
      final lngs = allPoints.map((p) => p.longitude).toList();
      final sw = LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      );
      final ne = LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      );
      final bounds = LatLngBounds(sw, ne);
      mapOptions = MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
        onTap: (_, __) => setState(() {
          _selectedCheckin = null;
          _selectedItem = null;
        }),
      );
    }

    return FlutterMap(
      options: mapOptions,
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.memoriesapp',
        ),
        // Itinerary item markers (rendered first so check-in pins appear on top).
        MarkerLayer(
          markers: items.map((item) {
            final isSelected = _selectedItem?.id == item.id;
            final emoji = item.category != null && item.category!.isNotEmpty
                ? item.category
                : null;
            return Marker(
              point: LatLng(item.lat!, item.lng!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedItem = item;
                  _selectedCheckin = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: isSelected ? AppColors.text : AppColors.amber,
                    border: Border.all(
                      color: AppColors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: AppShadows.card,
                  ),
                  child: Center(
                    child: emoji != null
                        ? Text(
                            emoji,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          )
                        : Icon(
                            Icons.place,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.amberLight,
                            size: 20,
                          ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Check-in photo markers.
        MarkerLayer(
          markers: checkins.map((c) {
            final hasMedia = c.media.isNotEmpty;
            final isSelected = _selectedCheckin?.id == c.id;
            return Marker(
              point: LatLng(c.lat!, c.lng!),
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedCheckin = c;
                  _selectedItem = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.text
                        : AppColors.accentGreen,
                    border: Border.all(
                      color: AppColors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: AppShadows.card,
                  ),
                  child: hasMedia
                      ? ClipOval(
                          child: Image.network(
                            c.media.first.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.place,
                                    color: AppColors.white, size: 22),
                          ),
                        )
                      : const Icon(Icons.place,
                          color: AppColors.white, size: 22),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Map memory card — check-in tap card (unchanged behaviour)
// ---------------------------------------------------------------------------

class _MapMemoryCard extends StatelessWidget {
  const _MapMemoryCard({
    required this.checkin,
    required this.onTap,
    required this.onClose,
  });

  final CheckinEntity checkin;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final note = checkin.memory?.note;
    final hasMedia = checkin.media.isNotEmpty;
    final h = checkin.capturedAt.hour.toString().padLeft(2, '0');
    final m = checkin.capturedAt.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.elevated,
        ),
        child: Row(
          children: [
            // Thumbnail
            if (hasMedia)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
                child: Image.network(
                  checkin.media.first.url,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.surfaceVariant,
                  ),
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreenLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.card),
                    bottomLeft: Radius.circular(AppRadius.card),
                  ),
                ),
                child: const Icon(Icons.place,
                    color: AppColors.accentGreen, size: 28),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$h:$m',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                    Text(
                      note != null && note.isNotEmpty
                          ? note
                          : 'Spontaneous moment',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.close,
                    size: 16, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Itinerary pin card — shown when an itinerary marker is tapped
// ---------------------------------------------------------------------------

class _ItineraryPinCard extends StatelessWidget {
  const _ItineraryPinCard({
    required this.item,
    required this.onClose,
  });

  final ItineraryItemEntity item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final locationName = item.locationName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          // Icon block (amber tinted, mirrors check-in green block)
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                bottomLeft: Radius.circular(AppRadius.card),
              ),
            ),
            child: Center(
              child: category != null && category.isNotEmpty
                  ? Text(category, style: const TextStyle(fontSize: 26))
                  : const Icon(Icons.place,
                      color: AppColors.amber, size: 28),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locationName != null && locationName.isNotEmpty)
                    Text(
                      locationName,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.close,
                  size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
