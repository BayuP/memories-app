import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/shared/widgets/app_state_badge.dart';
import 'package:memories_app/shared/widgets/avatar_circle.dart';

enum TripCardVariant { hero, list }

/// The single trip card used everywhere. [variant] picks the layout:
/// - [TripCardVariant.hero]   large gradient hero with overlaid title (Home featured)
/// - [TripCardVariant.list]   horizontal row with gradient thumbnail (Home/Profile lists)
class AppTripCard extends StatelessWidget {
  const AppTripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.members = const [],
    this.variant = TripCardVariant.list,
    this.shared = false,
  });

  final TripEntity trip;
  final VoidCallback onTap;
  final List<MemberEntity> members;
  final TripCardVariant variant;
  final bool shared;

  static const _gradients = [
    [Color(0xFF7B5E4A), Color(0xFF2D1F17)],
    [Color(0xFF4A6B5C), Color(0xFF1A2E26)],
    [Color(0xFF5C4A6B), Color(0xFF1F1726)],
    [Color(0xFF6B5E4A), Color(0xFF2E2517)],
  ];

  List<Color> _gradient() {
    final hash = trip.id.codeUnits.fold(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  List<({String label, String seed})> _avatarEntries() {
    if (members.isNotEmpty) {
      return members
          .map((m) => (
                label: m.displayName.isNotEmpty
                    ? m.displayName[0].toUpperCase()
                    : '?',
                seed: m.handle,
              ))
          .toList();
    }
    // Deterministic placeholders seeded from the trip id.
    return List.generate(3, (i) => (label: '', seed: '${trip.id}$i'));
  }

  ({AppBadgeState state, String? label}) _badge() {
    if (shared) return (state: AppBadgeState.shared, label: null);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (trip.startDate == null) {
      return trip.status == TripStatus.published
          ? (state: AppBadgeState.past, label: 'Published')
          : (state: AppBadgeState.upcoming, label: 'Active');
    }
    final start = DateUtils.dateOnly(trip.startDate!);
    final end = trip.endDate != null ? DateUtils.dateOnly(trip.endDate!) : start;
    if (today.isAfter(end)) return (state: AppBadgeState.past, label: null);
    if (!today.isBefore(start) && !today.isAfter(end)) {
      return (state: AppBadgeState.ongoing, label: null);
    }
    final days = start.difference(today).inDays;
    return (
      state: AppBadgeState.upcoming,
      label: 'In $days day${days == 1 ? '' : 's'}',
    );
  }

  String _dateRange({bool withYear = true}) {
    if (trip.startDate == null) return '';
    final short = DateFormat('MMM d');
    final long = DateFormat('MMM d, y');
    if (trip.endDate == null) {
      return withYear ? long.format(trip.startDate!) : short.format(trip.startDate!);
    }
    return '${short.format(trip.startDate!)} – ${(withYear ? long : short).format(trip.endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    return variant == TripCardVariant.hero ? _buildHero() : _buildList();
  }

  Widget _buildHero() {
    final colors = _gradient();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  trip.destination,
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_dateRange().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _dateRange(),
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AvatarStack(entries: _avatarEntries(), size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final colors = _gradient();
    final badge = _badge();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: AppTextStyles.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppStateBadge(state: badge.state, label: badge.label),
                      ],
                    ),
                    if (_dateRange().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _dateRange(),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AvatarStack(entries: _avatarEntries(), size: 20),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
