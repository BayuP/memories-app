import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Memory Book Page — cover-mock stub (v1)
// ---------------------------------------------------------------------------

class MemoryBookPage extends ConsumerWidget {
  const MemoryBookPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tripDetailProvider(tripId));
    final checkinsAsync = ref.watch(tripCheckinsProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Memory Book', style: AppTextStyles.appBarTitle),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
        error: (e, _) => AppErrorState(
          message: 'Could not load trip details',
          onRetry: () => ref.invalidate(tripDetailProvider(tripId)),
        ),
        data: (detail) {
          final trip = detail.trip;

          // Find the first media item across all checkins for the cover photo
          final firstMediaUrl = checkinsAsync.maybeWhen(
            data: (checkins) {
              for (final c in checkins) {
                if (c.media.isNotEmpty) return c.media.first.url;
              }
              return null;
            },
            orElse: () => null,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Book cover mock
                Center(
                  child: _BookCoverMock(
                    title: trip.title,
                    destination: trip.destination,
                    coverUrl: firstMediaUrl,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Subtitle
                Text(
                  trip.destination,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preview coming soon')),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: const Text('Preview Book'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCustomizeSheet(context),
                    icon: const Icon(Icons.tune_outlined, size: 16),
                    label: const Text('Customize'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCustomizeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(
                      bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              Text(
                'Customize Book',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _CustomizeRow(
                icon: Icons.photo_camera_outlined,
                label: 'Cover Photo',
                subtitle: 'Coming soon',
              ),
              const SizedBox(height: AppSpacing.sm),
              const _CustomizeRow(
                icon: Icons.title_outlined,
                label: 'Title',
                subtitle: 'Coming soon',
              ),
              const SizedBox(height: AppSpacing.sm),
              const _CustomizeRow(
                icon: Icons.palette_outlined,
                label: 'Theme',
                subtitle: 'Coming soon',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book cover mock
// ---------------------------------------------------------------------------

class _BookCoverMock extends StatelessWidget {
  const _BookCoverMock({
    required this.title,
    required this.destination,
    this.coverUrl,
  });

  final String title;
  final String destination;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    const width = 220.0;
    const height = 290.0;
    const spineWidth = 22.0;

    return SizedBox(
      width: width + spineWidth,
      height: height,
      child: Row(
        children: [
          // Spine
          Container(
            width: spineWidth,
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF1A1815),
                  Color(0xFF3D3A36),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: AppShadows.elevated,
            ),
          ),

          // Cover
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
                boxShadow: AppShadows.elevated,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background photo or gradient
                    if (coverUrl != null)
                      Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _CoverGradient(),
                      )
                    else
                      _CoverGradient(),

                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.text.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),

                    // Title
                    Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.white,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B8F71),
            Color(0xFF2D2A26),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customize row
// ---------------------------------------------------------------------------

class _CustomizeRow extends StatelessWidget {
  const _CustomizeRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium),
                Text(
                  subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
