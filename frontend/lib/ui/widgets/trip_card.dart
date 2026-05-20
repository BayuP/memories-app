import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'status_badge.dart';
import 'collaborator_avatars.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.tripName,
    required this.destination,
    required this.status,
    required this.statusLabel,
    required this.collaboratorUrls,
    required this.checkInCount,
    required this.coverColor,
    this.onTap,
  });

  final String tripName;
  final String destination;
  final TripStatus status;
  final String statusLabel;
  final List<String> collaboratorUrls;
  final int checkInCount;
  final Color coverColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover photo placeholder
            _CoverPhoto(color: coverColor, status: status, statusLabel: statusLabel),
            // Card body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tripName,
                    style: AppTextStyles.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        destination,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      CollaboratorAvatars(
                        avatarUrls: collaboratorUrls,
                        size: 26,
                      ),
                      const Spacer(),
                      _CheckInCount(count: checkInCount),
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
}

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({
    required this.color,
    required this.status,
    required this.statusLabel,
  });

  final Color color;
  final TripStatus status;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          color: color,
          child: Center(
            child: Icon(
              Icons.photo_camera_outlined,
              size: 32,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
        // Gradient overlay
        Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.25),
              ],
            ),
          ),
        ),
        // Status badge
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: StatusBadge(status: status, label: statusLabel),
        ),
      ],
    );
  }
}

class _CheckInCount extends StatelessWidget {
  const _CheckInCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 11,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                '$count check-ins',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
