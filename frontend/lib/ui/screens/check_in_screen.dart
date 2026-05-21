import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import '../widgets/layer_tabs.dart';
import '../widgets/media_thumbnail_strip.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({
    super.key,
    this.editMode = false,
    required this.tripId,
    this.itemId,
    this.kind = 'planned',
  });

  final bool editMode;
  final String tripId;
  final String? itemId;
  final String kind;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  CheckInLayer _layer = CheckInLayer.memory;
  int _mediaIndex = 0;
  int _coverIndex = 0;
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();
  String _vibe = '';
  bool _exifConfirmed = false;

  final List<XFile> _pickedFiles = [];
  bool _isSubmitting = false;

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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() => _pickedFiles.addAll(files));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(checkinRepositoryProvider);

      // 1. Create checkin
      final checkin = await repo.createCheckin(
        tripId: widget.tripId,
        kind: widget.kind,
        capturedAt: DateTime.now(),
        itineraryItemId: widget.itemId,
      );

      // 2. Upload each picked file
      for (final file in _pickedFiles) {
        final mime = _mimeFromPath(file.path);
        final urlInfo = await repo.getMediaUploadUrl(mime);
        final bytes = await file.readAsBytes();
        await repo.uploadMediaToR2(urlInfo['upload_url']!, bytes, mime);
        await repo.attachMedia(
          urlInfo['media_id']!,
          checkinId: checkin.id,
        );
      }

      // 3. Save memory layer (note + vibe/mood)
      final note = _noteController.text.trim();
      final moodApi = _vibeToApi(_vibe);
      if (note.isNotEmpty || moodApi != null) {
        await repo.updateMemory(
          checkin.id,
          note: note.isEmpty ? null : note,
          mood: moodApi,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      _ => 'image/jpeg',
    };
  }

  String? _vibeToApi(String vibe) => switch (vibe) {
        'Loved it' => 'loved',
        'It was ok' => 'ok',
        'Meh' => 'meh',
        _ => null,
      };

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
                    files: _pickedFiles,
                    onSwipe: (i) => setState(() => _mediaIndex = i),
                    onAdd: _pickImages,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Thumbnail strip
                  MediaThumbnailStrip(
                    itemCount: _pickedFiles.length,
                    coverIndex: _coverIndex,
                    selectedIndex: _mediaIndex,
                    colors: const [],
                    onThumbnailTap: (i) => setState(() => _mediaIndex = i),
                    onSetCover: (i) => setState(() => _coverIndex = i),
                    onRemove: (i) => setState(() {
                      _pickedFiles.removeAt(i);
                      // Keep indices in bounds after removal
                      if (_mediaIndex >= _pickedFiles.length && _mediaIndex > 0) {
                        _mediaIndex = _pickedFiles.length - 1;
                      }
                      if (_coverIndex >= _pickedFiles.length && _coverIndex > 0) {
                        _coverIndex = _pickedFiles.length - 1;
                      }
                    }),
                    onAddTap: _pickImages,
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
                      CheckInLayer.logistics => const _LogisticsLayer(
                          key: ValueKey('logistics'),
                        ),
                      CheckInLayer.recommendation => const _RecommendationLayer(
                          key: ValueKey('rec'),
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
            isLoading: _isSubmitting,
            onAction: widget.editMode ? () => Navigator.of(context).pop() : _submit,
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
    required this.files,
    required this.onSwipe,
    this.onAdd,
  });

  final int selectedIndex;
  final List<XFile> files;
  final ValueChanged<int> onSwipe;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          height: 320,
          color: const Color(0xFFF0EDE8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                'Add photos',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: files.length,
            onPageChanged: onSwipe,
            itemBuilder: (context, index) => Image.file(
              File(files[index].path),
              fit: BoxFit.cover,
              width: double.infinity,
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
              files.length,
              (i) => AnimatedContainer(
                duration: AppDurations.fast,
                width: i == selectedIndex ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == selectedIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
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
                color: Colors.black.withValues(alpha: 0.45),
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
                        ? AppColors.primary.withValues(alpha: 0.1)
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
          const Row(
            children: [
              _BadgeOption(
                label: 'Must-visit',
                icon: Icons.star_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              _BadgeOption(
                label: 'Hidden gem',
                icon: Icons.eco_outlined,
                color: AppColors.accentGreen,
              ),
              SizedBox(width: AppSpacing.sm),
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
    this.isLoading = false,
  });

  final bool editMode;
  final VoidCallback onAction;
  final bool isLoading;

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
          onPressed: isLoading ? null : onAction,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  editMode
                      ? Icons.save_rounded
                      : Icons.check_circle_outline_rounded,
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
