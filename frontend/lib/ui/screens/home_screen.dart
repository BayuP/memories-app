import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import '../widgets/trip_card.dart';
import '../widgets/status_badge.dart';
import 'create_trip_screen.dart';
import 'trip_view_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

class _MockTrip {
  const _MockTrip({
    required this.id,
    required this.name,
    required this.destination,
    required this.status,
    required this.statusLabel,
    required this.collaborators,
    required this.checkInCount,
    required this.coverColor,
  });

  final String id;
  final String name;
  final String destination;
  final TripStatus status;
  final String statusLabel;
  final List<String> collaborators;
  final int checkInCount;
  final Color coverColor;
}

const _mockTrips = [
  _MockTrip(
    id: '1',
    name: 'Bali with the crew',
    destination: 'Bali, Indonesia',
    status: TripStatus.ongoing,
    statusLabel: 'Ongoing',
    collaborators: ['A', 'B', 'C', 'D'],
    checkInCount: 12,
    coverColor: Color(0xFFC97D4E),
  ),
  _MockTrip(
    id: '2',
    name: 'Japan cherry blossom',
    destination: 'Tokyo & Kyoto, Japan',
    status: TripStatus.upcoming,
    statusLabel: 'In 14 days',
    collaborators: ['E', 'F'],
    checkInCount: 0,
    coverColor: Color(0xFF7B9EC9),
  ),
  _MockTrip(
    id: '3',
    name: 'Yogyakarta temple run',
    destination: 'Yogyakarta, Indonesia',
    status: TripStatus.past,
    statusLabel: 'Last month',
    collaborators: ['G', 'H', 'I'],
    checkInCount: 28,
    coverColor: Color(0xFF4A9B7F),
  ),
  _MockTrip(
    id: '4',
    name: 'Singapore food trip',
    destination: 'Singapore',
    status: TripStatus.past,
    statusLabel: '3 months ago',
    collaborators: ['J', 'K'],
    checkInCount: 19,
    coverColor: Color(0xFFB97DBB),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  String _filter = 'All';

  static const _filters = ['All', 'Upcoming', 'Past'];

  List<_MockTrip> get _filtered {
    return switch (_filter) {
      'Upcoming' =>
        _mockTrips.where((t) => t.status == TripStatus.upcoming).toList(),
      'Past' =>
        _mockTrips.where((t) => t.status == TripStatus.past).toList(),
      _ => _mockTrips,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _TripsTab(
            filter: _filter,
            trips: _filtered,
            filters: _filters,
            onFilterChanged: (f) => setState(() => _filter = f),
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
  });

  final String filter;
  final List<_MockTrip> trips;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
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
        if (trips.isEmpty)
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
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TripCard(
                      tripName: trip.name,
                      destination: trip.destination,
                      status: trip.status,
                      statusLabel: trip.statusLabel,
                      collaboratorUrls: trip.collaborators,
                      checkInCount: trip.checkInCount,
                      coverColor: trip.coverColor,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TripViewScreen()),
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
          decoration: BoxDecoration(
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
        Icon(
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
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
        ? AppColors.textDisabled.withOpacity(0.4)
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
                    _StatCell(value: '4', label: 'Trips'),
                    _VertDivider(),
                    _StatCell(value: '59', label: 'Check-ins'),
                    _VertDivider(),
                    _StatCell(value: '2', label: 'Published'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & feedback',
                ),
                _SettingsTile(
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
