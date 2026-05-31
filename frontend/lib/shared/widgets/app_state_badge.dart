import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

/// The semantic states a trip / itinerary item can present.
enum AppBadgeState { ongoing, upcoming, past, now, done, shared }

/// A single pill badge with consistent colors drawn from the semantic tokens
/// in [AppColors]. Replaces the per-screen ad-hoc badges.
class AppStateBadge extends StatelessWidget {
  const AppStateBadge({
    super.key,
    required this.state,
    this.label,
    this.icon,
  });

  final AppBadgeState state;

  /// Overrides the default label text (e.g. "In 3 days").
  final String? label;
  final IconData? icon;

  ({Color bg, Color fg, String text}) get _style => switch (state) {
        AppBadgeState.ongoing => (
            bg: AppColors.accentGreen,
            fg: AppColors.accentGreenLight,
            text: 'Ongoing',
          ),
        AppBadgeState.upcoming => (
            bg: AppColors.infoBg,
            fg: AppColors.infoText,
            text: 'Upcoming',
          ),
        AppBadgeState.past => (
            bg: AppColors.surfaceVariant,
            fg: AppColors.textMuted,
            text: 'Past',
          ),
        AppBadgeState.now => (
            bg: AppColors.nowBg,
            fg: AppColors.nowText,
            text: 'Now',
          ),
        AppBadgeState.done => (
            bg: AppColors.doneBg,
            fg: AppColors.doneText,
            text: 'Done',
          ),
        AppBadgeState.shared => (
            bg: AppColors.infoBg,
            fg: AppColors.infoText,
            text: 'Shared',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: state == AppBadgeState.past
            ? Border.all(color: AppColors.border, width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: s.fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label ?? s.text,
            style: AppTextStyles.labelSmall.copyWith(
              color: s.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
