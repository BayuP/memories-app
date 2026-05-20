import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

class SpontaneousBucket extends StatelessWidget {
  const SpontaneousBucket({
    super.key,
    this.itemCount = 0,
    this.onAdd,
    this.previewItems = const [],
  });

  final int itemCount;
  final VoidCallback? onAdd;
  final List<SpontaneousPreviewItem> previewItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.5,
          // Dashed via CustomPainter — approximated with styled border
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.badgeUpcoming,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spontaneous moments',
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      itemCount == 0
                          ? 'Add unplanned memories here'
                          : '$itemCount moment${itemCount > 1 ? 's' : ''} captured',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Preview items
          if (previewItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            ...previewItems.map(
              (item) => _PreviewTile(item: item),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class SpontaneousPreviewItem {
  const SpontaneousPreviewItem({
    required this.name,
    required this.time,
    this.hasPhoto = false,
  });

  final String name;
  final String time;
  final bool hasPhoto;
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.item});

  final SpontaneousPreviewItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              item.hasPhoto
                  ? Icons.photo_outlined
                  : Icons.bolt_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.labelMedium),
                Text(item.time, style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}

/// A custom painter that draws a dashed border — used for a more precise
/// dashed effect if needed.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    this.dashLength = 6,
    this.dashGap = 4,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    final dashPath = _dashPath(path, dashLength, dashGap);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double dashLen, double dashGap) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashLen).clamp(0.0, metric.length);
        dest.addPath(metric.extractPath(dist, end), Offset.zero);
        dist += dashLen + dashGap;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
