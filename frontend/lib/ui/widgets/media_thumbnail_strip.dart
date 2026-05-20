import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

class MediaThumbnailStrip extends StatelessWidget {
  const MediaThumbnailStrip({
    super.key,
    required this.itemCount,
    required this.coverIndex,
    required this.selectedIndex,
    required this.onThumbnailTap,
    required this.onSetCover,
    required this.onRemove,
    required this.onAddTap,
    this.colors = const [],
  });

  final int itemCount;
  final int coverIndex;
  final int selectedIndex;
  final ValueChanged<int> onThumbnailTap;
  final ValueChanged<int> onSetCover;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddTap;
  final List<Color> colors;

  static const _mockColors = [
    Color(0xFFC97D4E),
    Color(0xFF4A9B7F),
    Color(0xFF7B9EC9),
    Color(0xFFB97DBB),
    Color(0xFFE8A620),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (int i = 0; i < itemCount; i++) ...[
            _Thumbnail(
              index: i,
              color: colors.isNotEmpty
                  ? colors[i % colors.length]
                  : _mockColors[i % _mockColors.length],
              isCover: i == coverIndex,
              isSelected: i == selectedIndex,
              onTap: () => onThumbnailTap(i),
              onSetCover: () => onSetCover(i),
              onRemove: () => onRemove(i),
            ),
            const SizedBox(width: 6),
          ],
          // Add slot
          _AddSlot(onTap: onAddTap),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.index,
    required this.color,
    required this.isCover,
    required this.isSelected,
    required this.onTap,
    required this.onSetCover,
    required this.onRemove,
  });

  final int index;
  final Color color;
  final bool isCover;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSetCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onRemove,
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          // Cover dot
          if (isCover)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Cover',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
