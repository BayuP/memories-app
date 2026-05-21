import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart'
    as domain;
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/trip_card.dart';
import 'create_trip_screen.dart';
import 'trip_view_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mapping helpers
// ─────────────────────────────────────────────────────────────────────────────

TripStatus _uiStatus(domain.TripEntity t) {
  final now = DateTime.now();
  if (t.startDate != null && t.endDate != null) {
    if (now.isBefore(t.startDate!)) return TripStatus.upcoming;
    if (now.isAfter(t.endDate!)) return TripStatus.past;
    return TripStatus.ongoing;
  }
  return t.status == domain.TripStatus.published
      ? TripStatus.past
      : TripStatus.ongoing;
}

String _statusLabel(domain.TripEntity t) {
  final s = _uiStatus(t);
  final now = DateTime.now();
  if (s == TripStatus.upcoming && t.startDate != null) {
    final days = t.startDate!.difference(now).inDays;
    return 'In $days days';
  }
  if (s == TripStatus.past && t.endDate != null) {
    final days = now.difference(t.endDate!).inDays;
    if (days < 30) return '$days days ago';
    if (days < 365) return '${(days / 30).round()} months ago';
    return '${(days / 365).round()} years ago';
  }
  return 'Ongoing';
}

Color _coverColor(String id) {
  const colors = [
    Color(0xFFC97D4E),
    Color(0xFF7B9EC9),
    Color(0xFF4A9B7F),
    Color(0xFFB97DBB),
    Color(0xFFB8893D),
    Color(0xFF7A8FA6),
  ];
  return colors[id.hashCode.abs() % colors.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  String _filter = 'All';

  static const _filters = ['All', 'Upcoming', 'Past'];

  List<domain.TripEntity> _filtered(List<domain.TripEntity> all) {
    return switch (_filter) {
      'Upcoming' => all.where((t) => _uiStatus(t) == TripStatus.upcoming).toList(),
      'Past' => all.where((t) => _uiStatus(t) == TripStatus.past).toList(),
      _ => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          tripsAsync.when(
            loading: () => _TripsTab(
              filter: _filter,
              trips: const [],
              filters: _filters,
              onFilterChanged: (f) => setState(() => _filter = f),
              isLoading: true,
            ),
            error: (e, _) => _TripsTab(
              filter: _filter,
              trips: const [],
              filters: _filters,
              onFilterChanged: (f) => setState(() => _filter = f),
              error: e.toString(),
            ),
            data: (all) => _TripsTab(
              filter: _filter,
              trips: _filtered(all),
              filters: _filters,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          ),
          // Explore — V2 placeholder
          const _PlaceholderTab(
            icon: Icons.explore_outlined,
            label: 'Explore coming soon',
          ),
          // Activity
          const _ActivityTab(),
          // Profile
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      floatingActionButton: _CreateFab(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateTripScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trips tab
// ─────────────────────────────────────────────────────────────────────────────

class _TripsTab extends StatelessWidget {
  const _TripsTab({
    required this.filter,
    required this.trips,
    required this.filters,
    required this.onFilterChanged,
    this.isLoading = false,
    this.error,
  });

  final String filter;
  final List<domain.TripEntity> trips;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          backgroundColor: AppColors.background,
          floating: true,
          pinned: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          expandedHeight: 0,
          flexibleSpace: null,
          title: null,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(),
                const SizedBox(height: AppSpacing.lg),
                _FilterPills(
                  selected: filter,
                  options: filters,
                  onChanged: onFilterChanged,
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (error != null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Failed to load trips.\n$error',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else if (trips.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: _EmptyState(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = trips[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TripCard(
                      tripName: trip.title,
                      destination: trip.destination,
                      status: _uiStatus(trip),
                      statusLabel: _statusLabel(trip),
                      collaboratorUrls: const [],
                      checkInCount: 0,
                      coverColor: _coverColor(trip.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => TripViewScreen(
                                  tripId: trip.id,
                                  tripTitle: trip.title,
                                )),
                      ),
                    ),
                  );
                },
                childCount: trips.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your trips', style: AppTextStyles.displaySmall),
              const SizedBox(height: 2),
              Text(
                'Bayu — 4 trips',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              'B',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              option,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.luggage_outlined,
          size: 56,
          color: AppColors.textDisabled,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('No trips here yet', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Tap + to plan your first adventure',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Trips',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Explore',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
                disabled: true,
              ),
              // Center spacer for FAB
              const Expanded(child: SizedBox()),
              _NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Activity',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
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
    this.disabled = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? AppColors.textDisabled.withValues(alpha: 0.4)
        : selected
            ? AppColors.primary
            : AppColors.textDisabled;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: AppShadows.fab,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder tabs
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          )),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Activity', style: AppTextStyles.displaySmall),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ActivityItem(
                avatarLabel: ['A', 'C', 'E'][i % 3],
                message: [
                  'Ayu checked in at Tanah Lot',
                  'Citra added 3 photos to Day 2',
                  'Eko joined Bali with the crew',
                ][i % 3],
                time: '${i + 1}h ago',
              ),
              childCount: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.avatarLabel,
    required this.message,
    required this.time,
  });

  final String avatarLabel;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Center(
              child: Text(
                avatarLabel,
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Bayu Pabisa', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 2),
                Text('@bayu', style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xl),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _StatCell(value: '4', label: 'Trips'),
                    _VertDivider(),
                    const _StatCell(value: '59', label: 'Check-ins'),
                    _VertDivider(),
                    const _StatCell(value: '2', label: 'Published'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(height: 1),
                const _SettingsTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
                const _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & feedback',
                ),
                const _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign out',
                  destructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineLarge),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color)),
      trailing: destructive
          ? null
          : const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textDisabled),
      onTap: () {},
    );
  }
}
