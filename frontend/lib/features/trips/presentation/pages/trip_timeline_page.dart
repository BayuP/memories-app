import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

/// Returns the 1-based day number currently active relative to trip start.
/// Day 1 = startDate. Returns null if trip hasn't started or no startDate.
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

/// Returns the date for a given 1-based day number.
DateTime? _dateForDay(DateTime? startDate, int day) {
  if (startDate == null) return null;
  return startDate.add(Duration(days: day - 1));
}

/// Number of days in the trip.
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
  int _navIndex = 0;
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
        tripTitle: null,
        members: const [],
        startDate: null,
        endDate: null,
        body: const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
      ),
      error: (e, _) => _buildScaffold(
        tripTitle: null,
        members: const [],
        startDate: null,
        endDate: null,
        body: _buildErrorState(
          onRetry: () {
            ref.invalidate(tripDetailProvider(widget.tripId));
            ref.invalidate(itineraryItemsProvider(widget.tripId));
          },
        ),
      ),
      data: (detail) {
        final trip = detail.trip;
        final members = detail.members;
        final dayCount = _tripDayCount(trip.startDate, trip.endDate);
        final currentDay = _currentTripDay(trip.startDate, trip.endDate);

        // Auto-select current day once on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && currentDay != null && _selectedDay == 1) {
            setState(() => _selectedDay = currentDay);
          }
        });

        return _buildScaffold(
          tripTitle: trip.title,
          members: members,
          startDate: trip.startDate,
          endDate: trip.endDate,
          customAppBar: _buildAppBar(context, trip, members.length),
          body: Column(
            children: [
              _buildCollaboratorRow(members),
              _buildDaySelector(dayCount, currentDay, trip.startDate),
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
                      },
                      child: _buildTimeline(
                        dayItems,
                        currentDay,
                        trip,
                      ),
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
  // Scaffold wrapper
  // ---------------------------------------------------------------------------

  Widget _buildScaffold({
    required String? tripTitle,
    required List<MemberEntity> members,
    required DateTime? startDate,
    required DateTime? endDate,
    required Widget body,
    PreferredSizeWidget? customAppBar,
  }) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: customAppBar ??
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.text, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              tripTitle ?? 'trip timeline',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
      body: body,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TripEntity trip,
    int memberCount,
  ) {
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trip.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined,
              color: AppColors.textMuted, size: 20),
          onPressed: () {},
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert,
              color: AppColors.textMuted, size: 20),
          onPressed: () {},
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Collaborator row
  // ---------------------------------------------------------------------------

  Widget _buildCollaboratorRow(List<MemberEntity> members) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          SizedBox(
            height: 22,
            width: members.length * 16.0 + 6,
            child: Stack(
              children: [
                for (int i = 0; i < members.length && i < 5; i++)
                  Positioned(
                    left: i * 16.0,
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
          const SizedBox(width: 8),
          Text(
            '${members.length} ${members.length == 1 ? 'person' : 'people'} on this trip',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
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
      height: 38,
      child: ListView.separated(
        controller: _daySelectorScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dayCount,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = index + 1;
          final isToday = day == currentDay;
          final isSelected = day == _selectedDay;
          final label = isToday ? 'd$index · today' : 'd$index';
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.text : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
  ) {
    final isOnTripDay = currentDay == _selectedDay;

    // Determine which item is "now": first item without a check-in on today
    // For V1, we treat the first item of the current day as "now"
    // (no check-in data embedded in items yet, so we use index 0 for today)
    int? nowIndex = isOnTripDay && items.isNotEmpty ? 0 : null;

    final totalRows = items.length + 1; // +1 for spontaneous bucket

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: totalRows,
      itemBuilder: (context, index) {
        if (index < items.length) {
          final item = items[index];
          final isNow = nowIndex != null && index == nowIndex;
          final isDone = false; // In V1 we have no check-in ids on items

          return _TimelineRow(
            isLast: false,
            dot: _buildDot(isDone: isDone, isNow: isNow),
            card: _buildItemCard(
              item: item,
              isDone: isDone,
              isNow: isNow,
              onCheckin: () => _openCheckinCreate(
                tripId: trip.id,
                itemId: item.id,
                kind: 'planned',
              ),
            ),
          );
        } else {
          // Spontaneous bucket
          return _TimelineRow(
            isLast: true,
            dot: _buildSpontaneousDot(),
            card: _buildSpontaneousCard(
              onTap: () => _openCheckinCreate(
                tripId: trip.id,
                itemId: null,
                kind: 'spontaneous',
              ),
            ),
          );
        }
      },
    );
  }

  void _openCheckinCreate({
    required String tripId,
    required String? itemId,
    required String kind,
  }) {
    final params = <String, String>{'kind': kind};
    if (itemId != null) params['itemId'] = itemId;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    context.push('/trips/$tripId/checkin/create?$query');
  }

  // ---------------------------------------------------------------------------
  // Dot builders
  // ---------------------------------------------------------------------------

  Widget _buildDot({required bool isDone, required bool isNow}) {
    if (isDone) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.white, size: 11),
      );
    }
    if (isNow) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.text,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.text, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    // Upcoming
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );
  }

  Widget _buildSpontaneousDot() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: const Center(
        child: Icon(Icons.add, size: 11, color: AppColors.textMuted),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card builders
  // ---------------------------------------------------------------------------

  Widget _buildItemCard({
    required ItineraryItemEntity item,
    required bool isDone,
    required bool isNow,
    required VoidCallback onCheckin,
  }) {
    Color bgColor;
    Color borderColor;
    Color titleColor;
    double borderWidth;

    if (isDone) {
      bgColor = AppColors.accentGreenLight;
      borderColor = AppColors.accentGreen;
      titleColor = AppColors.accentGreenDark;
      borderWidth = 1.0;
    } else if (isNow) {
      bgColor = AppColors.white;
      borderColor = AppColors.text;
      titleColor = AppColors.text;
      borderWidth = 1.5;
    } else {
      bgColor = AppColors.surfaceVariant;
      borderColor = AppColors.border;
      titleColor = AppColors.textMuted;
      borderWidth = 1.0;
    }

    return GestureDetector(
      onTap: isDone
          ? () {
              // navigate to checkin detail if we had the id
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.startTime != null)
              Text(
                item.startTime!,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            if (isDone) ...[
              const SizedBox(height: 3),
              const Text(
                '0 photos',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.accentGreen,
                ),
              ),
            ] else if (isNow) ...[
              if (item.description != null &&
                  item.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              if (item.locationName != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 9, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        item.locationName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onCheckin,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.text,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      '📷  check in here',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (item.description != null &&
                  item.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpontaneousCard({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
            // dashed effect via custom painter below
          ),
        ),
        child: const Text(
          'something unplanned happened?',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.coral, size: 36),
            const SizedBox(height: 12),
            const Text(
              'failed to load timeline',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom nav
  // ---------------------------------------------------------------------------

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'trips',
                selected: _navIndex == 0,
                onTap: () {
                  setState(() => _navIndex = 0);
                  context.go(AppRoutes.home);
                },
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'explore',
                selected: _navIndex == 1,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('coming soon')),
                  );
                },
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(AppRoutes.createTrip),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.text,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: AppColors.white, size: 22),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'activity',
                selected: _navIndex == 3,
                onTap: () => setState(() => _navIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'profile',
                selected: _navIndex == 4,
                onTap: () => setState(() => _navIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline row widget
// ---------------------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.dot,
    required this.card,
    required this.isLast,
  });

  final Widget dot;
  final Widget card;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 4),
                dot,
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        color: AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
            fontSize: size * 0.45,
            fontWeight: FontWeight.w600,
            color: AppColors.accentGreenDark,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav item (mirrored from home page)
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.text : AppColors.textMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
