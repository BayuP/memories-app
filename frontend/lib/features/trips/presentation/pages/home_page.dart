import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/shared/widgets/app_bottom_nav.dart';
import 'package:memories_app/shared/widgets/app_states.dart';
import 'package:memories_app/shared/widgets/app_trip_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;

  void _onTripTap(TripEntity trip) {
    if (trip.status == TripStatus.published) {
      context.push('/public/trips/${trip.id}');
    } else {
      context.push('/trips/${trip.id}/timeline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: tripsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.accentGreen,
              strokeWidth: 2,
            ),
          ),
          error: (e, _) => AppErrorState(
            message: 'Failed to load trips',
            onRetry: () => ref.read(tripsProvider.notifier).refresh(),
          ),
          data: (trips) {
            final myTrips = currentUserId != null
                ? trips.where((t) => t.ownerId == currentUserId).toList()
                : trips;
            final sharedTrips = currentUserId != null
                ? trips.where((t) => t.ownerId != currentUserId).toList()
                : <TripEntity>[];

            final body = _navIndex == 1
                ? _buildJourneysTab(myTrips, sharedTrips)
                : _buildHomeTab(myTrips, sharedTrips);

            return Column(
              children: [
                Expanded(child: body),
                Container(
                  color: AppColors.bg,
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 12, AppSpacing.md, AppSpacing.md),
                  child: _NewJourneyButton(
                    onTap: () => context.push(AppRoutes.createTrip),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: _navIndex == 1 ? AppTab.journeys : AppTab.home,
        onSelect: (tab) {
          switch (tab) {
            case AppTab.home:
              setState(() => _navIndex = 0);
            case AppTab.journeys:
              setState(() => _navIndex = 1);
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

  // Tab 0 — dashboard: greeting + featured own trip + shared preview
  Widget _buildHomeTab(
      List<TripEntity> myTrips, List<TripEntity> sharedTrips) {
    return RefreshIndicator(
      color: AppColors.accentGreen,
      backgroundColor: AppColors.white,
      onRefresh: () => ref.read(tripsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.md),
        children: [
          _buildHeader(),
          if (myTrips.isEmpty && sharedTrips.isEmpty)
            const AppEmptyState(
              emoji: '✈️',
              title: 'No journeys yet',
              subtitle: 'Tap New Journey to start planning',
            )
          else ...[
            if (myTrips.isNotEmpty) ...[
              _buildSectionLabel('Your latest journey'),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppTripCard(
                  trip: myTrips.first,
                  onTap: () => _onTripTap(myTrips.first),
                  variant: TripCardVariant.hero,
                ),
              ),
            ],
            if (sharedTrips.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionLabel('Shared with you'),
              ...sharedTrips.take(3).map((t) => Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                    child: AppTripCard(
                      trip: t,
                      onTap: () => _onTripTap(t),
                      variant: TripCardVariant.list,
                      shared: true,
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  // Tab 1 — journeys: all trips grouped by Ongoing / Upcoming / Past
  Widget _buildJourneysTab(
      List<TripEntity> myTrips, List<TripEntity> sharedTrips) {
    final all = [...myTrips, ...sharedTrips];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isOngoing(TripEntity t) {
      if (t.startDate == null) return false;
      final start = DateTime(
          t.startDate!.year, t.startDate!.month, t.startDate!.day);
      final end = t.endDate != null
          ? DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day)
          : start;
      return !today.isBefore(start) && !today.isAfter(end);
    }

    bool isUpcoming(TripEntity t) {
      if (t.startDate == null) return false;
      final start = DateTime(
          t.startDate!.year, t.startDate!.month, t.startDate!.day);
      return today.isBefore(start);
    }

    final ongoing = all.where(isOngoing).toList();
    final upcoming = all.where(isUpcoming).toList()
      ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    final past = all
        .where((t) => !isOngoing(t) && !isUpcoming(t))
        .toList()
          ..sort((a, b) => (b.startDate ?? b.createdAt)
              .compareTo(a.startDate ?? a.createdAt));

    return RefreshIndicator(
      color: AppColors.accentGreen,
      backgroundColor: AppColors.white,
      onRefresh: () => ref.read(tripsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.md),
        children: [
          if (all.isEmpty)
            const AppEmptyState(
              emoji: '✈️',
              title: 'No journeys yet',
              subtitle: 'Tap New Journey to start planning',
            ),
          if (ongoing.isNotEmpty) ...[
            _buildGroupLabel('Ongoing', const Color(0xFF4A6B5C)),
            ..._tripCards(ongoing, myTrips),
          ],
          if (upcoming.isNotEmpty) ...[
            if (ongoing.isNotEmpty) const SizedBox(height: AppSpacing.sm),
            _buildGroupLabel('Upcoming', const Color(0xFF9A6C1A)),
            ..._tripCards(upcoming, myTrips),
          ],
          if (past.isNotEmpty) ...[
            if (ongoing.isNotEmpty || upcoming.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            _buildGroupLabel('Past', AppColors.textMuted),
            ..._tripCards(past, myTrips),
          ],
        ],
      ),
    );
  }

  List<Widget> _tripCards(List<TripEntity> trips, List<TripEntity> myTrips) {
    return trips.map((t) {
      final isShared = !myTrips.any((m) => m.id == t.id);
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
        child: AppTripCard(
          trip: t,
          onTap: () => _onTripTap(t),
          variant: TripCardVariant.list,
          shared: isShared,
        ),
      );
    }).toList();
  }

  Widget _buildGroupLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memories',
            style: GoogleFonts.playfairDisplay(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.text,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Collect moments. Share feelings. Create stories.',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        label,
        style: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.text,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Journey button
// ---------------------------------------------------------------------------

class _NewJourneyButton extends StatelessWidget {
  const _NewJourneyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.text,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'New Journey',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
