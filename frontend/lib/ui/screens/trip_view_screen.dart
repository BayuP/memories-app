import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import '../widgets/day_selector_strip.dart';
import '../widgets/timeline_item.dart';
import '../widgets/spontaneous_bucket.dart';
import '../widgets/collaborator_avatars.dart';
import 'check_in_screen.dart';
import 'spontaneous_add_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class TripViewScreen extends ConsumerStatefulWidget {
  const TripViewScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  final String tripId;
  final String? tripTitle;

  @override
  ConsumerState<TripViewScreen> createState() => _TripViewScreenState();
}

class _TripViewScreenState extends ConsumerState<TripViewScreen> {
  // Index into the _days list derived from API data.
  int _selectedIndex = 0;

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<DayItem> _buildDayItems(
      List<ItineraryItemEntity> items, DateTime? startDate) {
    final days = items.map((e) => e.day).toSet().toList()..sort();
    if (days.isEmpty) {
      return [
        const DayItem(label: 'D0', dayNumber: 0, date: 'Day 0'),
      ];
    }
    final today = DateTime.now();
    return days.map((d) {
      final date = startDate?.add(Duration(days: d - 1));
      final isToday = date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final label = 'D$d';
      final dateStr =
          date != null ? '${_monthName(date.month)} ${date.day}' : 'Day $d';
      return DayItem(
        label: label,
        dayNumber: d,
        date: dateStr,
        isToday: isToday,
      );
    }).toList();
  }

  String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];

  TimelineItemState _itemState(
      ItineraryItemEntity item, DayItem day, bool isFirstUpcomingToday) {
    if (!day.isToday) {
      // Determine whether this day is in the past or future by checking its
      // date string against today. We use the isToday flag as the pivot: any
      // day without an absolute date falls back to upcoming.
      //
      // To find past vs future we need the actual date. Since DayItem.date is
      // a display string, we re-derive the date from startDate via the day
      // number stored on the item. Here we use a simple heuristic: if the
      // DayItem was constructed with a real date and the day label implies it
      // has already passed, mark checkedIn. We rely on the caller always
      // passing days in order, so we compare dayNumber to today's trip day.
      final todayOrdinal = DateTime.now();
      // Reconstruct the item date from the display string is brittle, so
      // instead we use the startDate from the provider in the build method
      // (passed via closure). For a V1 simplification, if !isToday we check
      // the date string for a past date by computing from the snapshot below.
      // The cleanest approach: accept a DateTime? per DayItem. Since DayItem
      // only has a String date, we use a different approach — read the
      // startDate from the provider here via ref.
      final detail = ref
          .read(tripDetailProvider(widget.tripId))
          .valueOrNull;
      final startDate = detail?.trip.startDate;
      if (startDate != null) {
        final dayDate = startDate.add(Duration(days: item.day - 1));
        final dayDateNorm =
            DateTime(dayDate.year, dayDate.month, dayDate.day);
        final todayNorm = DateTime(
            todayOrdinal.year, todayOrdinal.month, todayOrdinal.day);
        if (dayDateNorm.isBefore(todayNorm)) {
          return TimelineItemState.checkedIn;
        }
      }
      return TimelineItemState.upcoming;
    }

    // Today: compare item start time to now.
    final now = TimeOfDay.now();
    if (item.startTime != null) {
      final parts = item.startTime!.split(':');
      final itemHour = int.tryParse(parts[0]) ?? 0;
      final itemMin =
          int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      if (itemHour < now.hour ||
          (itemHour == now.hour && itemMin <= now.minute)) {
        return TimelineItemState.checkedIn;
      }
    }
    // First upcoming item on today becomes "current".
    if (isFirstUpcomingToday) return TimelineItemState.current;
    return TimelineItemState.upcoming;
  }

  // Assign states to all items for a given day, promoting the first upcoming
  // item on today to `current`.
  List<TimelineItemState> _assignStates(
      List<ItineraryItemEntity> items, DayItem day) {
    // First pass: determine raw states without current promotion.
    final raw = items
        .map((item) => _itemState(item, day, false))
        .toList();

    if (!day.isToday) return raw;

    // Second pass: promote first non-checkedIn item to current.
    bool promoted = false;
    return raw.map((s) {
      if (!promoted && s != TimelineItemState.checkedIn) {
        promoted = true;
        return TimelineItemState.current;
      }
      return s;
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itineraryItemsProvider(widget.tripId));
    final detailAsync = ref.watch(tripDetailProvider(widget.tripId));

    return itemsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Failed to load itinerary:\n$err',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ),
      data: (items) {
        final startDate = detailAsync.valueOrNull?.trip.startDate;
        final days = _buildDayItems(items, startDate);

        // Clamp selected index in case data changed.
        final safeIndex =
            _selectedIndex.clamp(0, days.length - 1).toInt();

        final selectedDay = days[safeIndex];
        final selectedDayNumber = selectedDay.dayNumber;

        final dayItems = items
            .where((e) => e.day == selectedDayNumber)
            .toList()
          ..sort((a, b) {
            final aTime = a.startTime ?? '';
            final bTime = b.startTime ?? '';
            return aTime.compareTo(bTime);
          });

        final states = _assignStates(dayItems, selectedDay);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _TripSliverAppBar(
                tripTitle: widget.tripTitle ?? 'Loading...',
              ),
            ],
            body: Column(
              children: [
                DaySelectorStrip(
                  days: days,
                  selectedIndex: safeIndex,
                  onDaySelected: (i) => setState(() => _selectedIndex = i),
                ),
                const Divider(height: 1),
                Expanded(
                  child: dayItems.isEmpty
                      ? const _EmptyDayState()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              0, AppSpacing.md, 0, 100),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < dayItems.length;
                                      i++)
                                    Builder(builder: (_) {
                                      final entry = dayItems[i];
                                      return TimelineItem(
                                        state: states[i],
                                        time: entry.startTime ?? '--:--',
                                        name: entry.title,
                                        location: entry.locationName,
                                        photoCount: 0,
                                        quote: entry.description,
                                        isLast: i == dayItems.length - 1,
                                        onTap: () =>
                                            Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => CheckInScreen(
                                              tripId: widget.tripId,
                                              itemId: entry.id,
                                              kind: 'planned',
                                            ),
                                          ),
                                        ),
                                        onCheckIn: () =>
                                            Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => CheckInScreen(
                                              tripId: widget.tripId,
                                              itemId: entry.id,
                                              kind: 'planned',
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            // Spontaneous bucket — real data wired in follow-up.
                            SpontaneousBucket(
                              itemCount: 0,
                              previewItems: const [],
                              onAdd: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const SpontaneousAddSheet(),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver app bar
// ─────────────────────────────────────────────────────────────────────────────

class _TripSliverAppBar extends StatelessWidget {
  const _TripSliverAppBar({required this.tripTitle});

  final String tripTitle;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.8),
                AppColors.primaryDark,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 80, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      tripTitle,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Collaborator avatars — real member list wired via follow-up.
              const CollaboratorAvatars(
                avatarUrls: [],
                size: 32,
                borderColor: Colors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Invite icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 40, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text('Nothing planned yet', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Tap + to add a moment', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
