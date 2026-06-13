import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Trip Map Page
// ---------------------------------------------------------------------------

class TripMapPage extends ConsumerStatefulWidget {
  const TripMapPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends ConsumerState<TripMapPage> {
  CheckinEntity? _selectedCheckin;

  @override
  Widget build(BuildContext context) {
    final checkinsAsync = ref.watch(tripCheckinsProvider(widget.tripId));

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
          final geotagged = checkins
              .where((c) => c.lat != null && c.lng != null)
              .toList();

          if (geotagged.isEmpty) {
            return const AppEmptyState(
              emoji: '🗺️',
              title: 'No map pins yet',
              subtitle:
                  'Check in with location enabled to see your memories on the map.',
            );
          }

          return Stack(
            children: [
              _buildMap(geotagged),
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
                    onClose: () =>
                        setState(() => _selectedCheckin = null),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<CheckinEntity> checkins) {
    // Compute initial centre from first geotagged checkin
    final first = checkins.first;
    final centre = LatLng(first.lat!, first.lng!);

    return FlutterMap(
      options: MapOptions(
        initialCenter: centre,
        initialZoom: 13,
        onTap: (_, __) => setState(() => _selectedCheckin = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.memoriesapp',
        ),
        MarkerLayer(
          markers: checkins.map((c) {
            final hasMedia = c.media.isNotEmpty;
            final isSelected = _selectedCheckin?.id == c.id;
            return Marker(
              point: LatLng(c.lat!, c.lng!),
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () => setState(() => _selectedCheckin = c),
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
// Map memory card
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
