import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/features/story/domain/entities/story_entity.dart';
import 'package:memories_app/features/story/presentation/providers/story_provider.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Trip Story Page
// ---------------------------------------------------------------------------

class TripStoryPage extends ConsumerWidget {
  const TripStoryPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyProvider(tripId));
    final checkinsAsync = ref.watch(tripCheckinsProvider(tripId));

    final mediaItems = checkinsAsync.maybeWhen(
      data: (checkins) =>
          checkins.expand((c) => c.media).take(8).toList(),
      orElse: () => <MediaEntity>[],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Our Story', style: AppTextStyles.appBarTitle),
      ),
      body: storyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
        error: (e, _) => AppErrorState(
          message: 'Could not load story',
          onRetry: () => ref.invalidate(storyProvider(tripId)),
        ),
        data: (story) => _StoryBody(
          tripId: tripId,
          story: story,
          mediaItems: mediaItems,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Story body
// ---------------------------------------------------------------------------

class _StoryBody extends ConsumerStatefulWidget {
  const _StoryBody({
    required this.tripId,
    required this.story,
    required this.mediaItems,
  });

  final String tripId;
  final StoryEntity? story;
  final List<MediaEntity> mediaItems;

  @override
  ConsumerState<_StoryBody> createState() => _StoryBodyState();
}

class _StoryBodyState extends ConsumerState<_StoryBody> {
  bool _isEditing = false;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.story?.title ?? '');
    _bodyController = TextEditingController(
        text: widget.story?.body ?? '');
  }

  @override
  void didUpdateWidget(covariant _StoryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story != widget.story) {
      _titleController.text = widget.story?.title ?? '';
      _bodyController.text = widget.story?.body ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyProvider(widget.tripId));
    final isLoading = storyAsync.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Polaroid collage
          if (widget.mediaItems.isNotEmpty) ...[
            _PolaroidCollage(mediaItems: widget.mediaItems),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Title
          if (_isEditing)
            TextField(
              controller: _titleController,
              style: AppTextStyles.headlineLarge.copyWith(
                fontStyle: FontStyle.italic,
              ),
              decoration: const InputDecoration(
                hintText: 'Story title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            )
          else if (widget.story?.title != null &&
              widget.story!.title!.isNotEmpty)
            Text(
              widget.story!.title!,
              style: AppTextStyles.headlineLarge.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Body
          if (_isEditing)
            TextField(
              controller: _bodyController,
              minLines: 6,
              maxLines: null,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
              decoration: const InputDecoration(
                hintText: 'Your story begins here...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            )
          else if (widget.story?.body != null &&
              widget.story!.body!.isNotEmpty)
            Text(
              widget.story!.body!,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
            )
          else
            AppEmptyState(
              emoji: '✍️',
              title: 'No story yet',
              subtitle: widget.mediaItems.isEmpty
                  ? 'Add memories to your trip first, then generate a story.'
                  : 'Tap "Generate" to create a narrative from your memories.',
            ),

          const SizedBox(height: AppSpacing.xl),

          // Action row
          _ActionRow(
            isEditing: _isEditing,
            isLoading: isLoading,
            hasStory: widget.story != null,
            onGenerate: () =>
                ref.read(storyProvider(widget.tripId).notifier).generate(),
            onEdit: () => setState(() => _isEditing = true),
            onSave: () async {
              await ref.read(storyProvider(widget.tripId).notifier).saveEdits(
                    title: _titleController.text.trim().isEmpty
                        ? null
                        : _titleController.text.trim(),
                    body: _bodyController.text.trim().isEmpty
                        ? null
                        : _bodyController.text.trim(),
                  );
              if (mounted) setState(() => _isEditing = false);
            },
            onCancel: () {
              _titleController.text = widget.story?.title ?? '';
              _bodyController.text = widget.story?.body ?? '';
              setState(() => _isEditing = false);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action row (Generate / Edit / Save / Cancel)
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isEditing,
    required this.isLoading,
    required this.hasStory,
    required this.onGenerate,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final bool isEditing;
  final bool isLoading;
  final bool hasStory;
  final VoidCallback onGenerate;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentGreen),
              ),
              SizedBox(width: AppSpacing.sm),
              Text('Generating story…'),
            ],
          ),
        ),
      );
    }

    if (isEditing) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text('Save'),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_outlined, size: 16),
              label: Text(hasStory ? 'Regenerate' : 'Generate'),
            ),
          ),
        ),
        if (hasStory) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Polaroid collage
// ---------------------------------------------------------------------------

class _PolaroidCollage extends StatelessWidget {
  const _PolaroidCollage({required this.mediaItems});

  final List<MediaEntity> mediaItems;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42); // deterministic seed for stable rotations
    final count = mediaItems.length.clamp(1, 6);
    final size = MediaQuery.of(context).size.width * 0.38;

    return SizedBox(
      height: size * 1.35,
      child: Wrap(
        spacing: -size * 0.2,
        runSpacing: AppSpacing.sm,
        children: List.generate(count, (i) {
          final angle = (rng.nextDouble() - 0.5) * 0.25;
          return Transform.rotate(
            angle: angle,
            child: _PolaroidCard(
              url: mediaItems[i].url,
              size: size,
            ),
          );
        }),
      ),
    );
  }
}

class _PolaroidCard extends StatelessWidget {
  const _PolaroidCard({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: AppShadows.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: EdgeInsets.fromLTRB(
          size * 0.06, size * 0.06, size * 0.06, size * 0.18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.photo_outlined,
                  color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
