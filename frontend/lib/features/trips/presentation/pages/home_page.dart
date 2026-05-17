import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/features/trips/presentation/widgets/trip_card.dart';

enum _TripFilter { all, upcoming, past }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;
  _TripFilter _filter = _TripFilter.all;

  // Dummy handle for avatar — in a real app we'd get this from the user profile
  String get _userHandle {
    return 'me';
  }

  String get _userInitial => _userHandle.isNotEmpty
      ? _userHandle[0].toUpperCase()
      : 'M';

  List<TripEntity> _applyFilter(List<TripEntity> trips) {
    if (_filter == _TripFilter.all) return trips;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return trips.where((t) {
      if (t.startDate == null || t.endDate == null) {
        return _filter == _TripFilter.upcoming;
      }
      final start =
          DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
      final end =
          DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day);

      if (_filter == _TripFilter.upcoming) {
        return today.isBefore(start) ||
            (!today.isBefore(start) && !today.isAfter(end));
      } else {
        return today.isAfter(end);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildFilterPills(),
            Expanded(
              child: tripsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.coral, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          'failed to load trips',
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () =>
                              ref.read(tripsProvider.notifier).refresh(),
                          child: const Text('retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (trips) {
                  final filtered = _applyFilter(trips);
                  return RefreshIndicator(
                    color: AppColors.teal,
                    onRefresh: () =>
                        ref.read(tripsProvider.notifier).refresh(),
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final trip = filtered[index];
                              return TripCard(
                                trip: trip,
                                members: const [],
                                onTap: () {
                                  if (trip.status == TripStatus.published) {
                                    context.push(
                                        '/public/trips/${trip.id}');
                                  } else {
                                    context.push(
                                        '/trips/${trip.id}/timeline');
                                  }
                                },
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Text(
            'your trips',
            style: AppTextStyles.bodyLarge(color: AppColors.text).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textMuted, size: 22),
            onPressed: () {},
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.grayLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _userInitial,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterPill(
            label: 'all',
            selected: _filter == _TripFilter.all,
            onTap: () => setState(() => _filter = _TripFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'upcoming',
            selected: _filter == _TripFilter.upcoming,
            onTap: () => setState(() => _filter = _TripFilter.upcoming),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'past',
            selected: _filter == _TripFilter.past,
            onTap: () => setState(() => _filter = _TripFilter.past),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Column(
          children: [
            Icon(Icons.map_outlined, size: 48, color: AppColors.teal),
            SizedBox(height: 16),
            Text(
              'no trips yet',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'tap + to plan your first trip',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

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
                onTap: () => setState(() => _navIndex = 0),
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
              // Centre + button
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
                onTap: () {
                  setState(() => _navIndex = 4);
                  context.push(AppRoutes.profile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : AppColors.grayLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: selected
              ? null
              : Border.all(color: AppColors.grayMid, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

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
    final color = selected ? AppColors.text : AppColors.textHint;
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
