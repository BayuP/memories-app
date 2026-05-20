import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

class VibeChip extends StatelessWidget {
  const VibeChip({
    super.key,
    required this.label,
    required this.emoji,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : AppSpacing.md,
          vertical: compact ? 6 : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: compact ? 13 : 15)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Predefined vibe options for use across screens
class VibeOptions {
  static const all = [
    (emoji: '🏔', label: 'Adventure'),
    (emoji: '☕', label: 'Relaxed'),
    (emoji: '🍜', label: 'Foodie'),
    (emoji: '🏛', label: 'Culture'),
    (emoji: '💸', label: 'Budget'),
    (emoji: '🌊', label: 'Beach'),
    (emoji: '🌿', label: 'Nature'),
    (emoji: '🎉', label: 'Party'),
  ];
}
