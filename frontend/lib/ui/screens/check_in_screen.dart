import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import '../widgets/layer_tabs.dart';
import '../widgets/media_thumbnail_strip.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    this.editMode = false,
  });

  final bool editMode;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  CheckInLayer _layer = CheckInLayer.memory;
  int _mediaIndex = 0;
  int _coverIndex = 0;
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();
  String _vibe = '';
  bool _exifConfirmed = false;

  static const _mockMediaCount = 4;
  static const _mockMediaColors = [
    Color(0xFFC97D4E),
    Color(0xFF4A9B7F),
    Color(0xFF7B9EC9),
    Color(0xFFB97DBB),
  ];

  static const _vibeOptions = [
    ('😍', 'Loved it'),
    ('😊', 'It was ok'),
    ('😐', 'Meh'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.editMode
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Check-in'),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.badgeUpcoming,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Editing',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              )
            : const Text('Check in'),
        actions: [
          if (widget.editMode)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media viewer
                  _MediaViewer(
                    selectedIndex: _mediaIndex,
                    totalCount: _mockMediaCount,
                    colors: _mockMediaColors,
                    onSwipe: (i) => setState(() => _mediaIndex = i),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Thumbnail strip
                  MediaThumbnailStrip(
                    itemCount: _mockMediaCount,
                    coverIndex: _coverIndex,
                    selectedIndex: _mediaIndex,
                    colors: _mockMediaColors,
                    onThumbnailTap: (i) => setState(() => _mediaIndex = i),
                    onSetCover: (i) => setState(() => _coverIndex = i),
                    onRemove: (i) {},
                    onAddTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Layer tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: LayerTabs(
                      selected: _layer,
                      onChanged: (l) => setState(() => _layer = l),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Layer content
                  AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: switch (_layer) {
                      CheckInLayer.memory => _MemoryLayer(
                          key: const ValueKey('memory'),
                          noteController: _noteController,
                          vibe: _vibe,
                          vibeOptions: _vibeOptions,
                          exifConfirmed: _exifConfirmed,
                          onVibeChanged: (v) => setState(() => _vibe = v),
                          onExifConfirm: () =>
                              setState(() => _exifConfirmed = true),
                        ),
                      CheckInLayer.logistics => _LogisticsLayer(
                          key: const ValueKey('logistics'),
                        ),
                      CheckInLayer.recommendation => _RecommendationLayer(
                          key: const ValueKey('rec'),
                        ),
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom action bar
          _BottomActionBar(
            editMode: widget.editMode,
            onAction: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Media viewer with swipe
// ─────────────────────────────────────────────────────────────────────────────

class _MediaViewer extends StatelessWidget {
  const _MediaViewer({
    required this.selectedIndex,
    required this.totalCount,
    required this.colors,
    required this.onSwipe,
  });

  final int selectedIndex;
  final int totalCount;
  final List<Color> colors;
  final ValueChanged<int> onSwipe;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: totalCount,
            onPageChanged: onSwipe,
            itemBuilder: (context, index) => Container(
              color: colors[index % colors.length],
              child: Center(
                child: Icon(
                  Icons.photo_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
        // Dot indicator
        Positioned(
          bottom: AppSpacing.md,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalCount,
              (i) => AnimatedContainer(
                duration: AppDurations.fast,
                width: i == selectedIndex ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == selectedIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        // Cover indicator
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Tap thumbnail to set cover',
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Memory layer
// ─────────────────────────────────────────────────────────────────────────────

class _MemoryLayer extends StatelessWidget {
  const _MemoryLayer({
    super.key,
    required this.noteController,
    required this.vibe,
    required this.vibeOptions,
    required this.exifConfirmed,
    required this.onVibeChanged,
    required this.onExifConfirm,
  });

  final TextEditingController noteController;
  final String vibe;
  final List<(String, String)> vibeOptions;
  final bool exifConfirmed;
  final ValueChanged<String> onVibeChanged;
  final VoidCallback onExifConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EXIF notice
          if (!exifConfirmed)
            _ExifNotice(onConfirm: onExifConfirm),
          if (!exifConfirmed) const SizedBox(height: AppSpacing.md),

          // Location
          Text('Location', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          const _LocationField(),
          const SizedBox(height: AppSpacing.md),

          // Note
          Text('Your note', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: noteController,
            maxLines: 5,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'What made this moment special?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Vibe picker
          Text('How was it?', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: vibeOptions.map((v) {
              final selected = vibe == v.$2;
              return GestureDetector(
                onTap: () => onVibeChanged(v.$2),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.1)
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
                      Text(v.$1,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        v.$2,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ExifNotice extends StatelessWidget {
  const _ExifNotice({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.badgeUpcoming,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo taken at 11:23 AM today',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From photo metadata',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Use this time',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ubud Monkey Forest',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.accentGreen),
          const SizedBox(width: 4),
          Text('Auto-detected',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentGreen,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logistics layer
// ─────────────────────────────────────────────────────────────────────────────

class _LogisticsLayer extends StatelessWidget {
  const _LogisticsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Private notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Private — never shown on published trips',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Booking ref
          Text('Booking reference', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              hintText: 'e.g. GXKL72',
              prefixIcon: Icon(Icons.confirmation_number_outlined,
                  size: 16, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Cost
          Text('Cost', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('IDR',
                      style: AppTextStyles.labelMedium),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '0'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Notes
          Text('Private notes', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tickets, reservation details, anything...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommendation layer
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationLayer extends StatelessWidget {
  const _RecommendationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your tip', style: AppTextStyles.labelMedium),
          const SizedBox(height: 4),
          Text(
            'This will appear on the published trip for others to see',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'e.g. Go early morning — fewer crowds and better light',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Badge', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _BadgeOption(
                label: 'Must-visit',
                icon: Icons.star_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _BadgeOption(
                label: 'Hidden gem',
                icon: Icons.eco_outlined,
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: AppSpacing.sm),
              _BadgeOption(
                label: 'Skip it',
                icon: Icons.thumb_down_outlined,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeOption extends StatelessWidget {
  const _BadgeOption({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.editMode,
    required this.onAction,
  });

  final bool editMode;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onAction,
          icon: Icon(
            editMode ? Icons.save_rounded : Icons.check_circle_outline_rounded,
            size: 18,
          ),
          label: Text(
            editMode ? 'Save changes' : 'Check in',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
