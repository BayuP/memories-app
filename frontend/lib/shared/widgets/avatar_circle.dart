import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

/// A reusable avatar circle that derives a deterministic background color from
/// [seed] and shows [label] (typically an initial). Single source of truth for
/// avatars across the app.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.label,
    required this.seed,
    required this.size,
    this.borderWidth = 0,
  });

  final String label;
  final String seed;
  final double size;
  final double borderWidth;

  static const palette = [
    Color(0xFF9FE1CB),
    Color(0xFFF5C4B3),
    Color(0xFFFAEEDA),
    Color(0xFFD3D1C7),
    Color(0xFFBBD6F5),
    Color(0xFFF9D9A0),
  ];

  Color _bgColor() {
    final hash = seed.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor(),
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: AppColors.white, width: borderWidth)
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.text,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Overlapping stack of [AvatarCircle]s with an optional "+N" overflow bubble.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.entries,
    this.maxVisible = 4,
    this.size = 22,
    this.overlap = 5,
  });

  /// Each entry: (label, seed).
  final List<({String label, String seed})> entries;
  final int maxVisible;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final visible = entries.take(maxVisible).toList();
    final overflow = entries.length - visible.length;
    final step = size - overlap;
    final count = visible.length + (overflow > 0 ? 1 : 0);

    return SizedBox(
      height: size,
      width: size + (count - 1) * step,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              child: AvatarCircle(
                label: visible[i].label,
                seed: visible[i].seed,
                size: size,
                borderWidth: 1.5,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
