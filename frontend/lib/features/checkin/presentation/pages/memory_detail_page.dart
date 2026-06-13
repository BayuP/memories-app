import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/presentation/feelings.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Memory detail read view
// ---------------------------------------------------------------------------

class MemoryDetailPage extends ConsumerWidget {
  const MemoryDetailPage({
    super.key,
    required this.checkinId,
  });

  final String checkinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinAsync = ref.watch(checkinDetailProvider(checkinId));

    return checkinAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(context, null),
        body: const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(context, null),
        body: AppErrorState(
          message: 'Could not load memory',
          onRetry: () => ref.invalidate(checkinDetailProvider(checkinId)),
        ),
      ),
      data: (checkin) => Scaffold(
        backgroundColor: AppColors.bg,
        body: _MemoryDetailBody(checkin: checkin),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CheckinEntity? checkin) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (checkin != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.text),
            onPressed: () {
              context.push('/checkins/${checkin.id}?tripId=${checkin.tripId}');
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _MemoryDetailBody extends StatelessWidget {
  const _MemoryDetailBody({required this.checkin});

  final CheckinEntity checkin;

  @override
  Widget build(BuildContext context) {
    final memory = checkin.memory;
    final media = checkin.media;
    final mood = memory?.mood;
    final note = memory?.note;

    return CustomScrollView(
      slivers: [
        // Hero image in a SliverAppBar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.bg,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.text),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.text),
              ),
              onPressed: () {
                context.push('/checkins/${checkin.id}?tripId=${checkin.tripId}');
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: media.isNotEmpty
                ? Image.network(
                    media.first.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _HeroPlaceholder(),
                  )
                : _HeroPlaceholder(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date pill
                _DatePill(capturedAt: checkin.capturedAt),
                const SizedBox(height: AppSpacing.lg),

                // Feeling section
                if (mood != null && mood.isNotEmpty) ...[
                  Text(
                    'Feeling',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        moodEmoji(mood),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        moodLabel(mood),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Thoughts section
                if (note != null && note.isNotEmpty) ...[
                  Text(
                    'Thoughts',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    note,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.text,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Photos section
                if (media.isNotEmpty) ...[
                  Text(
                    'Photos',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PhotoGrid(media: media),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Empty state when nothing to show
                if ((mood == null || mood.isEmpty) &&
                    (note == null || note.isEmpty) &&
                    media.isEmpty)
                  const AppEmptyState(
                    emoji: '📷',
                    title: 'Nothing captured yet',
                    subtitle: 'Tap edit to add a feeling, thoughts, or photos.',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date pill
// ---------------------------------------------------------------------------

class _DatePill extends StatelessWidget {
  const _DatePill({required this.capturedAt});

  final DateTime capturedAt;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final d = capturedAt;
    final text =
        '${d.day} ${_months[d.month - 1]} ${d.year}  ·  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo grid
// ---------------------------------------------------------------------------

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.media});

  final List<MediaEntity> media;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final m = media[index];
        return GestureDetector(
          onTap: () => _openViewer(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              m.url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textMuted, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PhotoViewerContent(media: media, initialIndex: initialIndex),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewerContent extends StatefulWidget {
  const _PhotoViewerContent({
    required this.media,
    required this.initialIndex,
  });

  final List<MediaEntity> media;
  final int initialIndex;

  @override
  State<_PhotoViewerContent> createState() => _PhotoViewerContentState();
}

class _PhotoViewerContentState extends State<_PhotoViewerContent> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.media.length,
      itemBuilder: (context, index) {
        return InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.media[index].url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero placeholder
// ---------------------------------------------------------------------------

class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.photo_camera_outlined,
            color: AppColors.textMuted, size: 48),
      ),
    );
  }
}
