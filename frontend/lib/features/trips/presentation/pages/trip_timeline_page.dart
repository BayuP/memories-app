import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/checkin/presentation/feelings.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/shared/widgets/app_bottom_nav.dart';
import 'package:memories_app/shared/widgets/app_segmented_tabs.dart';
import 'package:memories_app/shared/widgets/app_state_badge.dart';
import 'package:memories_app/shared/widgets/app_states.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _fmtTime(String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

String _weekdayName(int weekday) {
  const names = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  return names[(weekday - 1) % 7];
}

String _monthName(int month) {
  const names = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
  ];
  return names[(month - 1) % 12];
}

int? _currentTripDay(DateTime? startDate, DateTime? endDate) {
  if (startDate == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  if (today.isBefore(start)) return null;
  if (endDate != null) {
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (today.isAfter(end)) return null;
  }
  return today.difference(start).inDays + 1;
}

DateTime? _dateForDay(DateTime? startDate, int day) {
  if (startDate == null) return null;
  return startDate.add(Duration(days: day - 1));
}

int _tripDayCount(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return 1;
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  final diff = end.difference(start).inDays + 1;
  return diff < 1 ? 1 : diff;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class TripTimelinePage extends ConsumerStatefulWidget {
  const TripTimelinePage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripTimelinePage> createState() => _TripTimelinePageState();
}

class _TripTimelinePageState extends ConsumerState<TripTimelinePage> {
  int _selectedDay = 1;
  bool _spontaneousExpanded = false;
  final _daySelectorScrollController = ScrollController();

  @override
  void dispose() {
    _daySelectorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripDetailAsync = ref.watch(tripDetailProvider(widget.tripId));
    final itemsAsync = ref.watch(itineraryItemsProvider(widget.tripId));

    return tripDetailAsync.when(
      loading: () => _buildScaffold(
        body: const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
      ),
      error: (e, _) => _buildScaffold(
        body: _buildErrorState(onRetry: () {
          ref.invalidate(tripDetailProvider(widget.tripId));
          ref.invalidate(itineraryItemsProvider(widget.tripId));
        }),
      ),
      data: (detail) {
        final trip = detail.trip;
        final members = detail.members;
        final dayCount = _tripDayCount(trip.startDate, trip.endDate);
        final currentDay = _currentTripDay(trip.startDate, trip.endDate);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && currentDay != null && _selectedDay == 1) {
            setState(() => _selectedDay = currentDay);
          }
        });

        final checkinsForSubheader =
            ref.watch(tripCheckinsProvider(widget.tripId)).maybeWhen(
                  data: (c) => c,
                  orElse: () => <CheckinEntity>[],
                );

        return _buildScaffold(
          appBar: _buildAppBar(context, trip),
          body: Column(
            children: [
              _buildSubheaderRow(members, itemsAsync, checkinsForSubheader),
              _buildSegmentedTabs(context, trip),
              _buildDaySelector(dayCount, currentDay, trip.startDate),
              const Divider(height: 1, thickness: 0.5),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentGreen, strokeWidth: 2),
                  ),
                  error: (e, _) => _buildErrorState(
                    onRetry: () =>
                        ref.invalidate(itineraryItemsProvider(widget.tripId)),
                  ),
                  data: (items) {
                    final checkinsAsync =
                        ref.watch(tripCheckinsProvider(widget.tripId));
                    final checkins = checkinsAsync.maybeWhen(
                      data: (c) => c,
                      orElse: () => <CheckinEntity>[],
                    );
                    final dayItems = items
                        .where((i) => i.day == _selectedDay)
                        .toList()
                      ..sort((a, b) {
                        final aTime = a.startTime ?? '';
                        final bTime = b.startTime ?? '';
                        return aTime.compareTo(bTime);
                      });
                    return RefreshIndicator(
                      color: AppColors.accentGreen,
                      onRefresh: () async {
                        ref.invalidate(tripDetailProvider(widget.tripId));
                        ref.invalidate(itineraryItemsProvider(widget.tripId));
                        ref.invalidate(tripCheckinsProvider(widget.tripId));
                      },
                      child: _buildTimeline(dayItems, currentDay, trip, checkins),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Scaffold
  // ---------------------------------------------------------------------------

  Widget _buildScaffold({Widget? body, PreferredSizeWidget? appBar}) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: appBar ??
          AppBar(
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
      body: body ?? const SizedBox.shrink(),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelect: (tab) {
          switch (tab) {
            case AppTab.home:
              context.go(AppRoutes.home);
            case AppTab.journeys:
              context.go(AppRoutes.home);
            case AppTab.memories:
              context.push('/memories');
            case AppTab.profile:
              context.push(AppRoutes.profile);
          }
        },
        onAdd: () => context.push(AppRoutes.createTrip),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, TripEntity trip) {
    final currentDay = _currentTripDay(trip.startDate, trip.endDate);
    final dayCount = _tripDayCount(trip.startDate, trip.endDate);

    String subtitle = '';
    if (currentDay != null) {
      final date = _dateForDay(trip.startDate, currentDay);
      if (date != null) {
        subtitle =
            'day $currentDay of $dayCount · ${_weekdayName(date.weekday)}, ${date.day} ${_monthName(date.month)}';
      }
    } else if (trip.startDate != null) {
      subtitle =
          '${_weekdayName(trip.startDate!.weekday)}, ${trip.startDate!.day} ${_monthName(trip.startDate!.month)}';
    }

    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trip.title,
            style: AppTextStyles.appBarTitle,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: AppTextStyles.appBarSubtitle,
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined,
              color: AppColors.textMuted, size: 20),
          onPressed: () =>
              context.push('/trips/${trip.id}/people'),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert,
              color: AppColors.textMuted, size: 20),
          onPressed: () => _showTripOverflowMenu(context, trip),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Trip overflow menu (Story + Memory Book)
  // ---------------------------------------------------------------------------

  void _showTripOverflowMenu(BuildContext context, TripEntity trip) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories_outlined,
                  color: AppColors.text),
              title: const Text('Story'),
              subtitle: const Text('Generate your trip narrative'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/trips/${trip.id}/story');
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined,
                  color: AppColors.text),
              title: const Text('Memory Book'),
              subtitle: const Text('Create a book of this trip'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/trips/${trip.id}/book');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Subheader: avatars + progress
  // ---------------------------------------------------------------------------

  Widget _buildSubheaderRow(
    List<MemberEntity> members,
    AsyncValue<List<ItineraryItemEntity>> itemsAsync,
    List<CheckinEntity> checkins,
  ) {
    final checkedInItemIds = checkins
        .where((c) => c.itineraryItemId != null)
        .map((c) => c.itineraryItemId!)
        .toSet();
    final doneCount = itemsAsync.maybeWhen(
      data: (items) => items
          .where((i) => i.day == _selectedDay && checkedInItemIds.contains(i.id))
          .length,
      orElse: () => 0,
    );
    final totalCount = itemsAsync.maybeWhen(
      data: (items) => items.where((i) => i.day == _selectedDay).length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          // Stacked avatars
          if (members.isNotEmpty) ...[
            SizedBox(
              height: 22,
              width: math.min(members.length, 5) * 15.0 + 7,
              child: Stack(
                children: [
                  for (int i = 0; i < members.length && i < 5; i++)
                    Positioned(
                      left: i * 15.0,
                      child: _AvatarCircle(
                        initial: members[i].displayName.isNotEmpty
                            ? members[i].displayName[0].toUpperCase()
                            : '?',
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${members.length} ${members.length == 1 ? 'person' : 'people'} on this trip',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
          const Spacer(),
          // Progress pill
          if (totalCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: doneCount == totalCount
                    ? AppColors.accentGreenLight
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: doneCount == totalCount
                      ? AppColors.accentGreen
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                '$doneCount of $totalCount done',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: doneCount == totalCount
                      ? AppColors.accentGreenDark
                      : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segmented tabs (Timeline / Map / People)
  // ---------------------------------------------------------------------------

  Widget _buildSegmentedTabs(BuildContext context, TripEntity trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 0, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSegmentedTabs(
            labels: const ['Timeline', 'Map', 'People'],
            selectedIndex: 0, // Timeline is always active on this page
            onSelect: (index) {
              if (index == 1) context.push('/trips/${trip.id}/map');
              if (index == 2) context.push('/trips/${trip.id}/people');
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Day selector
  // ---------------------------------------------------------------------------

  Widget _buildDaySelector(
    int dayCount,
    int? currentDay,
    DateTime? startDate,
  ) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: _daySelectorScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        itemCount: dayCount,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = index + 1;
          final isToday = day == currentDay;
          final isSelected = day == _selectedDay;
          final label = isToday ? 'd$index · today' : 'd$index';
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.text : AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color:
                      isSelected ? AppColors.text : AppColors.border,
                  width: isSelected ? 1.0 : 0.5,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timeline
  // ---------------------------------------------------------------------------

  Widget _buildTimeline(
    List<ItineraryItemEntity> items,
    int? currentDay,
    TripEntity trip,
    List<CheckinEntity> checkins,
  ) {
    final checkedInItemIds = checkins
        .where((c) => c.itineraryItemId != null)
        .map((c) => c.itineraryItemId!)
        .toSet();

    // Spontaneous checkins for the selected day
    final selectedDate = _dateForDay(trip.startDate, _selectedDay);
    final spontaneousForDay = checkins
        .where((c) => c.kind == 'spontaneous' && c.itineraryItemId == null)
        .where((c) {
          if (selectedDate == null) return true; // no dates → show all
          final cd = DateTime(c.capturedAt.year, c.capturedAt.month, c.capturedAt.day);
          final sd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          return cd == sd;
        })
        .toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    final isOnTripDay = currentDay == _selectedDay;

    int? nowIndex;
    if (isOnTripDay) {
      for (int i = 0; i < items.length; i++) {
        if (!checkedInItemIds.contains(items[i].id)) {
          nowIndex = i;
          break;
        }
      }
    }

    // Total rows: items * 2 (item + insert-after row) + "add activity" button + spontaneous group
    // index mapping:
    //   0..items.length*2-1 → item rows (even) and insert rows (odd)
    //   items.length*2      → "add activity" button
    //   items.length*2+1    → spontaneous group
    final totalCount = items.length * 2 + 2;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // "add activity" button row
        if (index == items.length * 2) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => _showActivitySheet(trip),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Add activity',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Spontaneous group
        if (index == items.length * 2 + 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      _buildSpontaneousDot(),
                    ],
                  ),
                ),
                Expanded(
                  child: _SpontaneousGroup(
                    checkins: spontaneousForDay,
                    expanded: _spontaneousExpanded,
                    onToggle: () => setState(
                        () => _spontaneousExpanded = !_spontaneousExpanded),
                    onAdd: () => _openCheckinCreate(
                      tripId: trip.id,
                      itemId: null,
                      kind: 'spontaneous',
                    ),
                    onTapCheckin: (c) => context.push(
                      '/memories/${c.id}',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final itemIndex = index ~/ 2;

        // Insert "add here" row (odd indices)
        if (index.isOdd) {
          return GestureDetector(
            onTap: () => _showActivitySheet(trip, insertIndex: itemIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                          color: AppColors.bg,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Add activity here',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        // Item card row (even indices)
        final item = items[itemIndex];
        final isNow = nowIndex != null && itemIndex == nowIndex;
        final isDone = checkedInItemIds.contains(item.id);

        // Find the matching checkin for this item (for photo count/thumbnail)
        final matchedCheckin = isDone
            ? checkins.firstWhere(
                (c) => c.itineraryItemId == item.id,
                orElse: () => checkins.first,
              )
            : null;

        return _TimelineRow(
          isLast: false,
          hasConnector: true,
          dot: _buildDot(isDone: isDone, isNow: isNow),
          card: _buildItemCard(
            item: item,
            isDone: isDone,
            isNow: isNow,
            matchedCheckin: matchedCheckin,
            onCheckin: () => _openCheckinCreate(
              tripId: trip.id,
              itemId: item.id,
              kind: 'planned',
            ),
            onEdit: () => _showActivitySheet(trip, item: item),
            onDelete: () => _confirmDeleteItem(trip.id, item),
          ),
        );
      },
    );
  }

  Future<void> _openCheckinCreate({
    required String tripId,
    required String? itemId,
    required String kind,
  }) async {
    final params = <String, String>{'kind': kind};
    if (itemId != null) params['itemId'] = itemId;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final result = await context.push<bool>(
        '/trips/$tripId/checkin/create?$query');
    if (result == true && mounted) {
      ref.invalidate(tripCheckinsProvider(tripId));
    }
  }

  // ---------------------------------------------------------------------------
  // Activity sheet helpers
  // ---------------------------------------------------------------------------

  void _showActivitySheet(
    TripEntity trip, {
    int? insertIndex,
    ItineraryItemEntity? item,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ActivitySheet(
          tripId: trip.id,
          item: item,
          insertAfterDay: _selectedDay,
          insertAfterIndex: insertIndex,
          onSaved: () {},
        ),
      ),
    );
  }

  void _confirmDeleteItem(String tripId, ItineraryItemEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text('Remove "${item.title}" from this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(itineraryItemsProvider(tripId).notifier)
                  .deleteItem(item.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dots
  // ---------------------------------------------------------------------------

  Widget _buildDot({required bool isDone, required bool isNow}) {
    if (isDone) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded,
            color: AppColors.white, size: 12),
      );
    }
    if (isNow) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.nowBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.nowText, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.nowText,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    // Upcoming
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
    );
  }

  Widget _buildSpontaneousDot() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: const Center(
        child: Icon(Icons.add, size: 12, color: AppColors.textMuted),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------------------

  Widget _buildItemCard({
    required ItineraryItemEntity item,
    required bool isDone,
    required bool isNow,
    CheckinEntity? matchedCheckin,
    required VoidCallback onCheckin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    if (isDone) {
      return _DoneCard(
        item: item,
        checkin: matchedCheckin,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }
    if (isNow) {
      return _NowCard(
        item: item,
        onCheckin: onCheckin,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }
    return _UpcomingCard(item: item, onEdit: onEdit, onDelete: onDelete);
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return AppErrorState(
      message: 'Failed to load timeline',
      onRetry: onRetry,
    );
  }
}

// ---------------------------------------------------------------------------
// Activity bottom sheet
// ---------------------------------------------------------------------------

class _ActivitySheet extends ConsumerStatefulWidget {
  const _ActivitySheet({
    required this.tripId,
    required this.item,
    required this.insertAfterDay,
    required this.insertAfterIndex,
    required this.onSaved,
  });

  final String tripId;
  final ItineraryItemEntity? item;
  final int insertAfterDay;
  final int? insertAfterIndex;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends ConsumerState<_ActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  TimeOfDay? _startTime;
  bool _saving = false;

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.title ?? '');
    _locationController = TextEditingController(text: item?.locationName ?? '');

    if (item?.startTime != null) {
      final parts = item!.startTime!.split(':');
      if (parts.length >= 2) {
        _startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    if (_startTime == null) return '';
    final h = _startTime!.hour.toString().padLeft(2, '0');
    final m = _startTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final notifier =
          ref.read(itineraryItemsProvider(widget.tripId).notifier);

      if (_isEditMode) {
        final body = <String, dynamic>{
          'title': _nameController.text.trim(),
          if (_locationController.text.trim().isNotEmpty)
            'location_name': _locationController.text.trim(),
          if (_startTime != null)
            'start_time':
                '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
        };
        await notifier.updateItem(widget.item!.id, body);
      } else {
        final body = <String, dynamic>{
          'day': widget.insertAfterDay,
          'title': _nameController.text.trim(),
          if (_locationController.text.trim().isNotEmpty)
            'location_name': _locationController.text.trim(),
          if (_startTime != null)
            'start_time':
                '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
        };
        await notifier.createItem(body);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameIsEmpty = _nameController.text.trim().isEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Sheet title
              Text(
                _isEditMode ? 'Edit activity' : 'Add activity',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),

              // Name field
              const _SheetLabel(text: 'name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditMode,
                textCapitalization: TextCapitalization.none,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.text),
                decoration: _inputDecoration('activity name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Location field
              const _SheetLabel(text: 'location'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.none,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.text),
                decoration: _inputDecoration('location (optional)'),
              ),
              const SizedBox(height: 14),

              // Start time picker
              const _SheetLabel(text: 'start time'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _startTime != null
                            ? _formattedTime
                            : 'tap to set time',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _startTime != null
                              ? AppColors.text
                              : AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (_startTime != null)
                        GestureDetector(
                          onTap: () => setState(() => _startTime = null),
                          child: const Icon(Icons.close,
                              size: 14, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Save button
              GestureDetector(
                onTap: nameIsEmpty || _saving ? null : _save,
                child: AnimatedOpacity(
                  opacity: nameIsEmpty ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.text,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditMode ? 'save changes' : 'Add activity',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.text, width: 1.0),
      ),
    );
  }
}

// Sheet field label
class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card: done
// ---------------------------------------------------------------------------

class _DoneCard extends StatelessWidget {
  const _DoneCard({
    required this.item,
    this.checkin,
    required this.onEdit,
    required this.onDelete,
  });

  final ItineraryItemEntity item;
  final CheckinEntity? checkin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final photoCount = checkin?.media.length ?? 0;
    final thumbUrl = checkin != null && checkin!.media.isNotEmpty
        ? checkin!.media.first.url
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.accentGreenLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentGreen, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional leading thumbnail
          if (thumbUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.network(
                thumbUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: AppColors.accentGreen.withOpacity(0.2),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.startTime != null)
                  Text(
                    _fmtTime(item.startTime!),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accentGreen),
                  ),
                Text(
                  item.title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentGreenDark,
                  ),
                ),
                if (item.locationName != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.accentGreen),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.locationName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.accentGreen),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.photo_camera_outlined,
                        size: 11, color: AppColors.accentGreen),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.accentGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action icons + done badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardIconButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 2),
                  _CardIconButton(
                    icon: Icons.delete_outline,
                    onTap: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const AppStateBadge(
                state: AppBadgeState.done,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card: now
// ---------------------------------------------------------------------------

class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.item,
    required this.onCheckin,
    required this.onEdit,
    required this.onDelete,
  });

  final ItineraryItemEntity item;
  final VoidCallback onCheckin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.text, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.startTime != null)
                      Text(
                        _fmtTime(item.startTime!),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (item.locationName != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.locationName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Action icons + now badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CardIconButton(
                        icon: Icons.edit_outlined,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 2),
                      _CardIconButton(
                        icon: Icons.delete_outline,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const AppStateBadge(state: AppBadgeState.now),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // CTA button — 44dp touch target
          GestureDetector(
            onTap: onCheckin,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.text,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 14, color: AppColors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Check in here',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        letterSpacing: 0.1,
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

// ---------------------------------------------------------------------------
// Spontaneous group (collapsible)
// ---------------------------------------------------------------------------

class _SpontaneousGroup extends StatelessWidget {
  const _SpontaneousGroup({
    required this.checkins,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
    required this.onTapCheckin,
  });

  final List<CheckinEntity> checkins;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final void Function(CheckinEntity) onTapCheckin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header — always visible
        GestureDetector(
          onTap: onToggle,
          child: _DashedBorderBox(
            color: AppColors.border,
            borderRadius: AppRadius.card,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Icon(Icons.bolt_outlined,
                        size: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkins.isEmpty
                              ? 'Spontaneous moments'
                              : '${checkins.length} spontaneous moment${checkins.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: checkins.isNotEmpty
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: checkins.isNotEmpty
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          checkins.isEmpty
                              ? 'Log something unplanned'
                              : expanded ? 'Tap to collapse' : 'Tap to expand',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expanded: list of logged moments + add button
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    children: [
                      ...checkins.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _SpontaneousCheckinCard(
                              checkin: c,
                              onTap: () => onTapCheckin(c),
                            ),
                          )),
                      // Add button
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                                color: AppColors.border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 13, color: AppColors.textMuted),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Log another moment',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // When collapsed and empty: show add inline
        if (!expanded && checkins.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Something unplanned happened?',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card: spontaneous checkin (logged)
// ---------------------------------------------------------------------------

class _SpontaneousCheckinCard extends StatelessWidget {
  const _SpontaneousCheckinCard({
    required this.checkin,
    required this.onTap,
  });

  final CheckinEntity checkin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = checkin.capturedAt.hour.toString().padLeft(2, '0');
    final m = checkin.capturedAt.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';
    final note = checkin.memory?.note;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.accentGreenLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.accentGreen, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accentGreen),
                  ),
                  Text(
                    note != null && note.isNotEmpty ? note : 'spontaneous moment',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentGreenDark,
                    ),
                  ),
                  if (checkin.memory?.mood != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _moodEmoji(checkin.memory!.mood!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.accentGreen),
          ],
        ),
      ),
    );
  }

  String _moodEmoji(String mood) => moodEmoji(mood);
}

// ---------------------------------------------------------------------------
// Card: upcoming
// ---------------------------------------------------------------------------

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ItineraryItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.startTime != null)
                  Text(
                    _fmtTime(item.startTime!),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                Text(
                  item.title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.locationName != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.locationName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Action icons + upcoming badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardIconButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 2),
                  _CardIconButton(
                    icon: Icons.delete_outline,
                    onTap: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const AppStateBadge(state: AppBadgeState.upcoming),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card icon button (edit / delete) — 40dp touch target
// ---------------------------------------------------------------------------

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(icon, size: 14, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline row
// ---------------------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.dot,
    required this.card,
    required this.isLast,
    required this.hasConnector,
  });

  final Widget dot;
  final Widget card;
  final bool isLast;
  final bool hasConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 6),
                dot,
                if (hasConnector)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed border box
// ---------------------------------------------------------------------------

class _DashedBorderBox extends StatelessWidget {
  const _DashedBorderBox({
    required this.child,
    required this.color,
    required this.borderRadius,
    this.dashLength = 5.0,
    this.gapLength = 4.0,
    this.strokeWidth = 1.0,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        borderRadius: borderRadius,
        dashLength: dashLength,
        gapLength: gapLength,
        strokeWidth: strokeWidth,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.0,
    this.dashLength = 5.0,
    this.gapLength = 4.0,
  });

  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}

// ---------------------------------------------------------------------------
// Avatar circle
// ---------------------------------------------------------------------------

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentGreenLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
            color: AppColors.accentGreenDark,
          ),
        ),
      ),
    );
  }
}
