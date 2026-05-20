import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

enum TimelineItemState { checkedIn, current, upcoming }

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.state,
    required this.time,
    required this.name,
    this.location,
    this.photoCount = 0,
    this.quote,
    this.isLast = false,
    this.onTap,
    this.onCheckIn,
  });

  final TimelineItemState state;
  final String time;
  final String name;
  final String? location;
  final int photoCount;
  final String? quote;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline gutter
          SizedBox(
            width: 48,
            child: Column(
              children: [
                const SizedBox(height: 2),
                _Dot(state: state),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: state == TimelineItemState.checkedIn
                          ? AppColors.accentGreen.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: AppDurations.normal,
                margin: const EdgeInsets.only(bottom: 12, right: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: switch (state) {
                      TimelineItemState.checkedIn => Colors.transparent,
                      TimelineItemState.current => AppColors.primary,
                      TimelineItemState.upcoming => AppColors.border,
                    },
                    width: state == TimelineItemState.current ? 2 : 1,
                  ),
                  boxShadow:
                      state == TimelineItemState.current ? AppShadows.card : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + name row
                    Row(
                      children: [
                        Text(
                          time,
                          style: AppTextStyles.caption.copyWith(
                            color: state == TimelineItemState.upcoming
                                ? AppColors.textDisabled
                                : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (state == TimelineItemState.checkedIn &&
                            photoCount > 0)
                          _PhotoBadge(count: photoCount),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: switch (state) {
                          TimelineItemState.checkedIn => AppColors.textPrimary,
                          TimelineItemState.current => AppColors.primary,
                          TimelineItemState.upcoming =>
                            AppColors.textSecondary,
                        },
                        fontWeight: state == TimelineItemState.current
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(location!, style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                    if (quote != null &&
                        state == TimelineItemState.checkedIn) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreenLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '"$quote"',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentGreen,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (state == TimelineItemState.current) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: onCheckIn,
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Check in here'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            textStyle: AppTextStyles.labelMedium
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final TimelineItemState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(left: 17, top: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          TimelineItemState.checkedIn => AppColors.accentGreen,
          TimelineItemState.current => AppColors.primary,
          TimelineItemState.upcoming => AppColors.surface,
        },
        border: Border.all(
          color: switch (state) {
            TimelineItemState.checkedIn => AppColors.accentGreen,
            TimelineItemState.current => AppColors.primary,
            TimelineItemState.upcoming => AppColors.border,
          },
          width: 2,
        ),
      ),
      child: state == TimelineItemState.checkedIn
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : null,
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentGreenLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_outlined, size: 10, color: AppColors.accentGreen),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
