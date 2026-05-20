import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

enum CheckInLayer { memory, logistics, recommendation }

class LayerTabs extends StatelessWidget {
  const LayerTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CheckInLayer selected;
  final ValueChanged<CheckInLayer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Memory',
            icon: Icons.auto_stories_outlined,
            selected: selected == CheckInLayer.memory,
            onTap: () => onChanged(CheckInLayer.memory),
          ),
          _Tab(
            label: 'Logistics',
            icon: Icons.confirmation_number_outlined,
            selected: selected == CheckInLayer.logistics,
            onTap: () => onChanged(CheckInLayer.logistics),
          ),
          _Tab(
            label: 'Rec',
            icon: Icons.star_outline_rounded,
            selected: selected == CheckInLayer.recommendation,
            onTap: () => onChanged(CheckInLayer.recommendation),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm + 1),
            boxShadow: selected ? AppShadows.card : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected ? AppColors.primary : AppColors.textDisabled,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.textDisabled,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
