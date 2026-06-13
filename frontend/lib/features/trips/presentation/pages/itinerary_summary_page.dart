import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/presentation/pages/itinerary_review_page.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

/// Full-page recap shown after tapping "Next" on the itinerary editor.
/// Back (app bar) returns to the editor to modify; "Confirm" goes to the trip.
class ItinerarySummaryPage extends ConsumerWidget {
  const ItinerarySummaryPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(tripDetailProvider(tripId)).value;
    final items = ref.watch(itineraryItemsProvider(tripId)).value ?? const [];
    final grouped = groupItemsByDay(items);
    final sortedDays = grouped.keys.toList()..sort();
    final totalItems = items.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: const BackButton(),
        title: const Text('Review trip'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
          children: [
            if (detail != null) ...[
              Text(
                detail.trip.title,
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      detail.trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  if (detail.trip.startDate != null &&
                      detail.trip.endDate != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${DateFormat('MMM d').format(detail.trip.startDate!)} – ${DateFormat('MMM d').format(detail.trip.endDate!)}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              '${sortedDays.length} ${sortedDays.length == 1 ? 'day' : 'days'} · $totalItems ${totalItems == 1 ? 'plan' : 'plans'}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final day in sortedDays) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 6),
                child: Text(
                  dayLabelFor(day, detail),
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.text),
                ),
              ),
              ...grouped[day]!.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemEmojiFor(item), style: AppTextStyles.bodyLarge),
                      const SizedBox(width: AppSpacing.sm),
                      if (formatTime(item.startTime) != null) ...[
                        Text(
                          formatTime(item.startTime)!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.locationName != null &&
                                item.locationName!.isNotEmpty)
                              Text(
                                item.locationName!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 12, AppSpacing.md, AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Back to edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/trips/$tripId/timeline'),
                child: const Text("Confirm — let's go"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
