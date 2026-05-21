import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.members,
    required this.onTap,
  });

  final TripEntity trip;
  final List<MemberEntity> members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover area
            Stack(
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      topRight: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: _StatusBadge(trip: trip),
                ),
              ],
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _buildSubtitle(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (members.isNotEmpty)
                        _MemberAvatarStack(members: members),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (trip.startDate != null && trip.endDate != null) {
      final fmt = DateFormat('MMM d');
      parts.add(
          '${fmt.format(trip.startDate!)} – ${fmt.format(trip.endDate!)}');
    } else if (trip.startDate != null) {
      parts.add(DateFormat('MMM d').format(trip.startDate!));
    }

    if (members.isNotEmpty) {
      parts.add('${members.length} traveller${members.length == 1 ? '' : 's'}');
    }

    return parts.join(' · ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String label;
    Color bgColor;
    Color textColor;

    if (trip.startDate != null && trip.endDate != null) {
      final start = DateTime(
          trip.startDate!.year, trip.startDate!.month, trip.startDate!.day);
      final end = DateTime(
          trip.endDate!.year, trip.endDate!.month, trip.endDate!.day);

      if (today.isAfter(end)) {
        label = 'past';
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.textMuted;
      } else if (!today.isBefore(start) && !today.isAfter(end)) {
        label = 'ongoing';
        bgColor = AppColors.accentGreen;
        textColor = AppColors.accentGreenLight;
      } else {
        final daysUntil = start.difference(today).inDays;
        label = 'in $daysUntil day${daysUntil == 1 ? '' : 's'}';
        bgColor = const Color(0xFF378ADD);
        textColor = const Color(0xFFDBEEFB);
      }
    } else {
      label = trip.status == TripStatus.published ? 'published' : 'active';
      bgColor = AppColors.accentGreenLight;
      textColor = AppColors.accentGreenDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: label == 'past'
            ? Border.all(color: AppColors.border, width: 0.5)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.members});

  final List<MemberEntity> members;

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    const overlap = 5.0;
    final displayCount = members.length > 4 ? 4 : members.length;

    return SizedBox(
      height: size,
      width: size + (displayCount - 1) * (size - overlap),
      child: Stack(
        children: List.generate(displayCount, (i) {
          final member = members[i];
          return Positioned(
            left: i * (size - overlap),
            child: AvatarCircleWidget(
              label: member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              seed: member.handle,
              size: size,
              borderWidth: 1.5,
            ),
          );
        }),
      ),
    );
  }
}

/// A reusable avatar circle widget that generates a deterministic background
/// color from [seed] and shows [label] (typically an initial).
class AvatarCircleWidget extends StatelessWidget {
  const AvatarCircleWidget({
    super.key,
    required this.label,
    required this.seed,
    required this.size,
    this.borderWidth = 0,
  });

  final String label;
  final String seed;
  final double size;
  final double borderWidth;

  static const _palette = [
    Color(0xFF9FE1CB),
    Color(0xFFF5C4B3),
    Color(0xFFFAEEDA),
    Color(0xFFD3D1C7),
    Color(0xFFBBD6F5),
    Color(0xFFF9D9A0),
  ];

  Color _bgColor() {
    final hash = seed.codeUnits.fold(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor(),
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: AppColors.white, width: borderWidth)
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.text,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
