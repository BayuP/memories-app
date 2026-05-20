import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import '../widgets/vibe_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

class _PublishedPlace {
  const _PublishedPlace({
    required this.dayLabel,
    required this.name,
    required this.tip,
    required this.badge,
    required this.color,
    this.location,
  });

  final String dayLabel;
  final String name;
  final String tip;
  final String badge; // 'must-visit' | 'unplanned' | 'hidden gem'
  final Color color;
  final String? location;
}

const _mockPlaces = [
  _PublishedPlace(
    dayLabel: 'Day 1',
    name: 'Seminyak Square',
    tip: 'Great for local batik and souvenirs. Skip the tourist traps on the main strip — duck into the side streets.',
    badge: 'must-visit',
    color: Color(0xFFC97D4E),
    location: 'Seminyak, Bali',
  ),
  _PublishedPlace(
    dayLabel: 'Day 1',
    name: 'Ku De Ta sunset',
    tip: 'Book a table minimum 3 days ahead. Worth every rupiah for the view.',
    badge: 'must-visit',
    color: Color(0xFF7B9EC9),
    location: 'Jl. Kayu Aya',
  ),
  _PublishedPlace(
    dayLabel: 'Day 2',
    name: 'Tegallalang Rice Terrace',
    tip: 'Go before 8 AM. Empty, golden light, no crowds. Bring mosquito repellent.',
    badge: 'must-visit',
    color: Color(0xFF4A9B7F),
    location: 'Tegallalang, Ubud',
  ),
  _PublishedPlace(
    dayLabel: 'Day 2',
    name: 'Warung Ibu Oka',
    tip: 'Found this randomly. The babi guling here beats any tourist place. Cash only.',
    badge: 'unplanned',
    color: Color(0xFFE8A620),
    location: 'Ubud Market area',
  ),
  _PublishedPlace(
    dayLabel: 'Day 3',
    name: 'Mount Batur sunrise',
    tip: 'The hardest morning of the trip, the best memory. Bring a proper jacket — it is cold at the top.',
    badge: 'must-visit',
    color: Color(0xFFB97DBB),
    location: 'Kintamani',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PublishedTripScreen extends StatelessWidget {
  const PublishedTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _PublishedSliverAppBar(),
          // Trip meta
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  _AuthorRow(),
                  const SizedBox(height: AppSpacing.md),
                  // Stats
                  _StatsRow(),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  // Vibes
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: const [
                      VibeChip(
                          emoji: '🍜', label: 'Foodie', selected: false),
                      VibeChip(
                          emoji: '☕', label: 'Relaxed', selected: false),
                      VibeChip(
                          emoji: '🏛', label: 'Culture', selected: false),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  // Logistics notice
                  _LogisticsLockNotice(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Places & tips',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_mockPlaces.length} places  ·  4 days  ·  Bali',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          // Place cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = _mockPlaces[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PlaceCard(place: place),
                  );
                },
                childCount: _mockPlaces.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PublishedBottomNav(),
    );
  }
}

class _PublishedSliverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      expandedHeight: 260,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover photo placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Photo placeholder icon
            const Center(
              child: Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: Colors.white24,
              ),
            ),
            // Bottom overlay with trip name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bali with the crew',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'May 19–23, 2026',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _AuthorRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Author avatar
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              'B',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bayu Pabisa', style: AppTextStyles.labelLarge),
              Text('@bayu  ·  142 followers',
                  style: AppTextStyles.caption),
            ],
          ),
        ),
        // Follow button
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(80, 36),
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: const Text('Follow'),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(
          icon: Icons.location_on_outlined,
          value: '${_mockPlaces.length}',
          label: 'places',
        ),
        const SizedBox(width: AppSpacing.md),
        const _StatBadge(
          icon: Icons.photo_outlined,
          value: '47',
          label: 'photos',
        ),
        const SizedBox(width: AppSpacing.md),
        const _StatBadge(
          icon: Icons.bolt_rounded,
          value: '3',
          label: 'spontaneous',
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogisticsLockNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Logistics never shown here',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final _PublishedPlace place;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo thumbnail
          Container(
            width: 90,
            height: 110,
            color: place.color,
            child: Center(
              child: Icon(
                Icons.photo_outlined,
                size: 24,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        place.dayLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _PlaceBadge(badge: place.badge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    style: AppTextStyles.labelLarge,
                  ),
                  if (place.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(place.location!,
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    place.tip,
                    style: AppTextStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceBadge extends StatelessWidget {
  const _PlaceBadge({required this.badge});

  final String badge;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (badge) {
      'must-visit' => (
          AppColors.badgeUpcoming,
          AppColors.primary,
          Icons.star_rounded,
          'Must-visit',
        ),
      'unplanned' => (
          AppColors.badgeOngoing,
          AppColors.accentGreen,
          Icons.bolt_rounded,
          'Unplanned',
        ),
      _ => (
          AppColors.badgePast,
          AppColors.textSecondary,
          Icons.eco_outlined,
          'Hidden gem',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishedBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(
            icon: Icons.home_outlined,
            label: 'Trips',
            onTap: () => Navigator.of(context).pop(),
          ),
          _NavBtn(
            icon: Icons.explore_rounded,
            label: 'Explore',
            selected: true,
            onTap: () {},
          ),
          _NavBtn(
            icon: Icons.notifications_outlined,
            label: 'Activity',
            onTap: () {},
          ),
          _NavBtn(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.primary : AppColors.textDisabled;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
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
    );
  }
}
