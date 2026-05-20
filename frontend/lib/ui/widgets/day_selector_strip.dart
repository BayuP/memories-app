import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

class DayItem {
  const DayItem({
    required this.label,
    required this.dayNumber,
    this.isToday = false,
    this.date,
  });

  final String label;
  final int dayNumber;
  final bool isToday;
  final String? date;
}

class DaySelectorStrip extends StatefulWidget {
  const DaySelectorStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  final List<DayItem> days;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  @override
  State<DaySelectorStrip> createState() => _DaySelectorStripState();
}

class _DaySelectorStripState extends State<DaySelectorStrip> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.surface,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        itemCount: widget.days.length,
        itemBuilder: (context, index) {
          final day = widget.days[index];
          final isSelected = index == widget.selectedIndex;
          return GestureDetector(
            onTap: () => widget.onDaySelected(index),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : day.isToday
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : day.isToday
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  if (day.date != null)
                    Text(
                      day.date!,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textDisabled,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
