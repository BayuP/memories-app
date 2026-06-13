import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

/// A horizontal underline tab selector, styled to match `_buildTabSelector`
/// in `checkin_page.dart`.
///
/// [labels] — the tab titles.
/// [selectedIndex] — currently selected tab (0-based).
/// [onSelect] — called with the new index when a tab is tapped.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == selectedIndex;
        final label = labels[i];
        return GestureDetector(
          onTap: () => onSelect(i),
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.text : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 2,
                  width: label.length * 6.5,
                  color: isActive ? AppColors.text : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
