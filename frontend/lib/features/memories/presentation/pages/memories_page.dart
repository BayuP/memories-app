import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/memories/presentation/providers/memories_provider.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Memories page — calendar-style grid grouped by month
// ---------------------------------------------------------------------------

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(allMemoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Memories', style: AppTextStyles.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: memoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
        error: (e, _) => AppErrorState(
          message: 'Could not load memories',
          onRetry: () => ref.invalidate(allMemoriesProvider),
        ),
        data: (memories) {
          if (memories.isEmpty) {
            return const AppEmptyState(
              emoji: '📷',
              title: 'No memories yet',
              subtitle: 'Check in on a trip to capture your first memory.',
            );
          }

          final sections = _groupByMonth(memories);

          return RefreshIndicator(
            color: AppColors.accentGreen,
            onRefresh: () async {
              ref.invalidate(allMemoriesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
              itemCount: sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = sections[sectionIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
                      child: Text(
                        section.monthLabel.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                      ),
                      itemCount: section.checkins.length,
                      itemBuilder: (context, index) {
                        final checkin = section.checkins[index];
                        return _MemoryThumbnail(
                          checkin: checkin,
                          onTap: () => context.push('/memories/${checkin.id}'),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<_MonthSection> _groupByMonth(List<CheckinEntity> checkins) {
    final map = <String, List<CheckinEntity>>{};
    final fmt = DateFormat('MMMM yyyy');

    for (final c in checkins) {
      final key = fmt.format(c.capturedAt);
      map.putIfAbsent(key, () => []).add(c);
    }

    // Preserve sorted order (newest first — checkins already sorted)
    final seen = <String>{};
    final sections = <_MonthSection>[];
    for (final c in checkins) {
      final key = fmt.format(c.capturedAt);
      if (seen.add(key)) {
        sections.add(_MonthSection(monthLabel: key, checkins: map[key]!));
      }
    }

    return sections;
  }
}

// ---------------------------------------------------------------------------
// Month section data holder
// ---------------------------------------------------------------------------

class _MonthSection {
  const _MonthSection({required this.monthLabel, required this.checkins});

  final String monthLabel;
  final List<CheckinEntity> checkins;
}

// ---------------------------------------------------------------------------
// Memory thumbnail cell
// ---------------------------------------------------------------------------

class _MemoryThumbnail extends StatelessWidget {
  const _MemoryThumbnail({
    required this.checkin,
    required this.onTap,
  });

  final CheckinEntity checkin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstMedia = checkin.media.isNotEmpty ? checkin.media.first : null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: firstMedia != null
            ? Image.network(
                firstMedia.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderCell(),
              )
            : _PlaceholderCell(),
      ),
    );
  }
}

class _PlaceholderCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.photo_outlined, color: AppColors.textMuted, size: 24),
      ),
    );
  }
}
