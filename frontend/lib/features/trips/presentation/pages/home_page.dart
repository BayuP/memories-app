import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

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
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _NewJourneyButton(
                    onTap: () => context.push(AppRoutes.createTrip),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        children: [
          _buildHeader(),
          if (myTrips.isEmpty && sharedTrips.isEmpty)
            _buildEmptyState()
          else ...[
            if (myTrips.isNotEmpty) ...[
              _buildSectionLabel('Your latest journey'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FeaturedTripCard(
                  trip: myTrips.first,
                  onTap: () => _onTripTap(myTrips.first),
                ),
              ),
            ],
            if (sharedTrips.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionLabel('Shared with you'),
              ...sharedTrips.take(3).map((t) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _CompactTripCard(
                      trip: t,
                      onTap: () => _onTripTap(t),
                      showOwnerBadge: true,
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  // Tab 1 — journeys: all trips grouped by ongoing / upcoming / past
  Widget _buildJourneysTab(
      List<TripEntity> myTrips, List<TripEntity> sharedTrips) {
    final all = [...myTrips, ...sharedTrips];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isOngoing(TripEntity t) {
      if (t.startDate == null) return false;
      final start = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
      final end = t.endDate != null
          ? DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day)
          : start;
      return !today.isBefore(start) && !today.isAfter(end);
    }

    bool isUpcoming(TripEntity t) {
      if (t.startDate == null) return false;
      final start = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
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
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        children: [
          if (all.isEmpty) _buildEmptyState(),
          if (ongoing.isNotEmpty) ...[
            _buildGroupLabel('ongoing', const Color(0xFF4A6B5C)),
            ..._tripCards(ongoing, myTrips),
          ],
          if (upcoming.isNotEmpty) ...[
            if (ongoing.isNotEmpty) const SizedBox(height: 8),
            _buildGroupLabel('upcoming', const Color(0xFF9A6C1A)),
            ..._tripCards(upcoming, myTrips),
          ],
          if (past.isNotEmpty) ...[
            if (ongoing.isNotEmpty || upcoming.isNotEmpty)
              const SizedBox(height: 8),
            _buildGroupLabel('past', AppColors.textMuted),
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _CompactTripCard(
          trip: t,
          onTap: () => _onTripTap(t),
          showOwnerBadge: isShared,
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
          const SizedBox(height: 4),
          Text(
            'Collect moments. Share feelings. Create stories.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
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
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Text(
            '✈️',
            style: TextStyle(fontSize: 40),
          ),
          SizedBox(height: 16),
          Text(
            'no journeys yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'tap new journey to start planning',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
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
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Journeys',
                selected: _navIndex == 1,
                onTap: () => setState(() => _navIndex = 1),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                label: 'Add',
                selected: _navIndex == 2,
                onTap: () => context.push(AppRoutes.createTrip),
              ),
              _NavItem(
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: 'Memories',
                selected: _navIndex == 3,
                onTap: () => setState(() => _navIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
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

// ---------------------------------------------------------------------------
// Featured trip card (first trip — large hero)
// ---------------------------------------------------------------------------

class _FeaturedTripCard extends StatelessWidget {
  const _FeaturedTripCard({required this.trip, required this.onTap});

  final TripEntity trip;
  final VoidCallback onTap;

  static const _gradients = [
    [Color(0xFF7B5E4A), Color(0xFF2D1F17)],
    [Color(0xFF4A6B5C), Color(0xFF1A2E26)],
    [Color(0xFF5C4A6B), Color(0xFF1F1726)],
    [Color(0xFF6B5E4A), Color(0xFF2E2517)],
  ];

  List<Color> _gradient() {
    final hash = trip.id.codeUnits.fold(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  String _dateRange() {
    if (trip.startDate == null) return '';
    final fmt = DateFormat('MMM d');
    if (trip.endDate == null) return fmt.format(trip.startDate!);
    if (trip.startDate!.year == trip.endDate!.year) {
      return '${fmt.format(trip.startDate!)} – ${DateFormat('MMM d, y').format(trip.endDate!)}';
    }
    return '${DateFormat('MMM d, y').format(trip.startDate!)} – ${DateFormat('MMM d, y').format(trip.endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            // Destination hint — subtle top-right
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trip.destination,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Bottom info overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_dateRange().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _dateRange(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (trip.vibes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _PlaceholderAvatarRow(seed: trip.id),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact trip card (remaining trips — horizontal)
// ---------------------------------------------------------------------------

class _CompactTripCard extends StatelessWidget {
  const _CompactTripCard({
    required this.trip,
    required this.onTap,
    this.showOwnerBadge = false,
  });

  final TripEntity trip;
  final VoidCallback onTap;
  final bool showOwnerBadge;

  static const _thumbGradients = [
    [Color(0xFF9F8B7A), Color(0xFF5C4A3D)],
    [Color(0xFF7A9F8B), Color(0xFF3D5C4A)],
    [Color(0xFF8B7A9F), Color(0xFF4A3D5C)],
    [Color(0xFF9F9A7A), Color(0xFF5C573D)],
  ];

  List<Color> _gradient() {
    final hash = trip.id.codeUnits.fold(0, (a, b) => a + b) + 1;
    return _thumbGradients[hash % _thumbGradients.length];
  }

  String _dateLabel() {
    if (trip.startDate == null) return '';
    return DateFormat('MMM d, y').format(trip.startDate!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showOwnerBadge)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4EAF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'shared',
                              style: TextStyle(
                                color: Color(0xFF5B7AAA),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_dateLabel().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _dateLabel(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _PlaceholderAvatarRow(seed: trip.id, size: 20),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder avatar row (3 circles + optional overflow badge)
// ---------------------------------------------------------------------------

class _PlaceholderAvatarRow extends StatelessWidget {
  const _PlaceholderAvatarRow({required this.seed, this.size = 24});

  final String seed;
  final double size;

  static const _palette = [
    Color(0xFF9FE1CB),
    Color(0xFFF5C4B3),
    Color(0xFFFAEEDA),
    Color(0xFFD3D1C7),
    Color(0xFFBBD6F5),
    Color(0xFFF9D9A0),
  ];

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold(0, (a, b) => a + b);
    final avatars = List.generate(3, (i) {
      final color = _palette[(hash + i) % _palette.length];
      final labels = ['A', 'B', 'C'];
      return (color: color, label: labels[i]);
    });
    const overlap = 5.0;

    return Row(
      children: [
        SizedBox(
          height: size,
          width: size + 2 * (size - overlap),
          child: Stack(
            children: avatars.asMap().entries.map((e) {
              return Positioned(
                left: e.key * (size - overlap),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: e.value.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'New Journey',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav item
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
