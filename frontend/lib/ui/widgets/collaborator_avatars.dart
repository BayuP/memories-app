import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

class CollaboratorAvatars extends StatelessWidget {
  const CollaboratorAvatars({
    super.key,
    required this.avatarUrls,
    this.maxVisible = 3,
    this.size = 28,
    this.borderColor = AppColors.surface,
  });

  final List<String> avatarUrls;
  final int maxVisible;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final visible = avatarUrls.take(maxVisible).toList();
    final overflow = avatarUrls.length - maxVisible;

    return SizedBox(
      height: size,
      width: visible.length * (size - 6) + (overflow > 0 ? size + 2 : 0),
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - 6),
              child: _Avatar(
                url: visible[i],
                size: size,
                borderColor: borderColor,
                label: String.fromCharCode(65 + i),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (size - 6),
              child: _OverflowBubble(
                count: overflow,
                size: size,
                borderColor: borderColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.size,
    required this.borderColor,
    required this.label,
  });

  final String url;
  final double size;
  final Color borderColor;
  final String label;

  // Mock colors for placeholder avatars
  static const _colors = [
    Color(0xFFC97D4E),
    Color(0xFF4A9B7F),
    Color(0xFF7B9EC9),
    Color(0xFFB97DBB),
    Color(0xFFE8A620),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex = label.codeUnitAt(0) % _colors.length;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        color: _colors[colorIndex],
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OverflowBubble extends StatelessWidget {
  const _OverflowBubble({
    required this.count,
    required this.size,
    required this.borderColor,
  });

  final int count;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        color: AppColors.surfaceVariant,
      ),
      child: Center(
        child: Text(
          '+$count',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }
}
