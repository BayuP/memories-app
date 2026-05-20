import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';

/// Spontaneous add — bottom sheet accessible in max 2 taps from trip view.
/// Photo upload + EXIF notice with 1-tap confirm + when field + note.
class SpontaneousAddSheet extends StatefulWidget {
  const SpontaneousAddSheet({super.key});

  @override
  State<SpontaneousAddSheet> createState() => _SpontaneousAddSheetState();
}

class _SpontaneousAddSheetState extends State<SpontaneousAddSheet> {
  bool _useExifTime = false;
  bool _exifConfirmed = false;
  String _timeMode = 'exif'; // 'exif' | 'manual'
  final _noteController = TextEditingController();
  final _manualTimeController = TextEditingController(text: '11:23');
  int _mockPhotoCount = 0;

  @override
  void dispose() {
    _noteController.dispose();
    _manualTimeController.dispose();
    super.dispose();
  }

  void _addPhoto() {
    setState(() {
      _mockPhotoCount++;
      _useExifTime = true; // Simulate EXIF detected
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header
            Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Spontaneous moment',
                  style: AppTextStyles.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Add something unplanned to your day',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Photo / video upload area
            _PhotoUploadArea(
              photoCount: _mockPhotoCount,
              onAdd: _addPhoto,
            ),
            const SizedBox(height: AppSpacing.lg),

            // EXIF notice — show when photo added
            if (_useExifTime && !_exifConfirmed) ...[
              _ExifChip(
                detectedTime: '11:23 AM',
                onConfirm: () => setState(() {
                  _exifConfirmed = true;
                  _timeMode = 'exif';
                }),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // When-did-this-happen
            Text('When did this happen?', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            _TimeSelector(
              mode: _timeMode,
              exifTime: '11:23 AM',
              manualController: _manualTimeController,
              exifConfirmed: _exifConfirmed,
              onModeChange: (m) => setState(() => _timeMode = m),
            ),
            const SizedBox(height: AppSpacing.md),

            // Note
            Text('Note', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 4,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'What happened? Keep it raw.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  'Save to timeline',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _PhotoUploadArea extends StatelessWidget {
  const _PhotoUploadArea({
    required this.photoCount,
    required this.onAdd,
  });

  final int photoCount;
  final VoidCallback onAdd;

  static const _mockColors = [
    Color(0xFFC97D4E),
    Color(0xFF4A9B7F),
    Color(0xFF7B9EC9),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos / video', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        if (photoCount == 0)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      size: 28, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Tap to add photo or video',
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text('EXIF time will be auto-detected',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: Row(
              children: [
                for (int i = 0; i < photoCount && i < 3; i++)
                  Container(
                    width: 72,
                    height: 72,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _mockColors[i % _mockColors.length],
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.photo_outlined,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExifChip extends StatelessWidget {
  const _ExifChip({
    required this.detectedTime,
    required this.onConfirm,
  });

  final String detectedTime;
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
                  'Photo taken at $detectedTime',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Detected from photo metadata',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Use this',
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

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.mode,
    required this.exifTime,
    required this.manualController,
    required this.exifConfirmed,
    required this.onModeChange,
  });

  final String mode;
  final String exifTime;
  final TextEditingController manualController;
  final bool exifConfirmed;
  final ValueChanged<String> onModeChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode pills
        Row(
          children: [
            _ModePill(
              label: 'From photo',
              icon: Icons.photo_outlined,
              selected: mode == 'exif',
              onTap: () => onModeChange('exif'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ModePill(
              label: 'Set manually',
              icon: Icons.edit_outlined,
              selected: mode == 'manual',
              onTap: () => onModeChange('manual'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (mode == 'exif')
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: exifConfirmed
                  ? AppColors.accentGreenLight
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: exifConfirmed
                    ? AppColors.accentGreen
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  exifConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 16,
                  color: exifConfirmed
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  exifConfirmed
                      ? 'Using $exifTime from photo'
                      : 'Confirm time above first',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: exifConfirmed
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          TextField(
            controller: manualController,
            keyboardType: TextInputType.datetime,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'HH:MM',
              prefixIcon: Icon(Icons.access_time_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
