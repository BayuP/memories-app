import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

enum TripStatus { ongoing, upcoming, past }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  final TripStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, text) = switch (status) {
      TripStatus.ongoing => (
          AppColors.badgeOngoing,
          AppColors.accentGreen,
          Icons.radio_button_checked_rounded,
          label ?? 'Ongoing',
        ),
      TripStatus.upcoming => (
          AppColors.badgeUpcoming,
          AppColors.primary,
          Icons.schedule_rounded,
          label ?? 'Upcoming',
        ),
      TripStatus.past => (
          AppColors.badgePast,
          AppColors.textSecondary,
          Icons.check_circle_outline_rounded,
          label ?? 'Past',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(color: fg, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
