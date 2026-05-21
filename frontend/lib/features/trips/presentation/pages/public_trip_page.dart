import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:memories_app/features/trips/domain/entities/public_trip_entity.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/features/trips/presentation/widgets/trip_card.dart';

class PublicTripPage extends ConsumerWidget {
  const PublicTripPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(publicTripProvider(tripId));

    return tripAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accentGreen,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.coral, size: 36),
                const SizedBox(height: 12),
                Text(
                  'could not load trip',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  e.toString(),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(publicTripProvider(tripId)),
                  child: const Text('retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (publicTrip) => _PublicTripContent(
        tripId: tripId,
        publicTrip: publicTrip,
      ),
    );
  }
}

class _PublicTripContent extends ConsumerStatefulWidget {
  const _PublicTripContent({
    required this.tripId,
    required this.publicTrip,
  });

  final String tripId;
  final PublicTripEntity publicTrip;

  @override
  ConsumerState<_PublicTripContent> createState() =>
      _PublicTripContentState();
}

class _PublicTripContentState extends ConsumerState<_PublicTripContent> {
  bool _allDaysExpanded = false;
  bool _isPublishing = false;

  PublicTripEntity get _pub => widget.publicTrip;
  TripEntity get _trip => _pub.trip;

  int get _tripDurationDays {
    if (_trip.startDate == null || _trip.endDate == null) return 0;
    return _trip.endDate!.difference(_trip.startDate!).inDays + 1;
  }

  String get _durationLabel {
    final vibeStr = _trip.vibes.take(2).join(' · ');
    final days = _tripDurationDays;
    final dayStr = days > 0 ? '$days day${days == 1 ? '' : 's'}' : '';
    if (vibeStr.isNotEmpty && dayStr.isNotEmpty) {
      return '$vibeStr · $dayStr';
    } else if (vibeStr.isNotEmpty) {
      return vibeStr;
    }
    return dayStr;
  }

  String get _destinationDateLine {
    final parts = <String>[_trip.destination];
    if (_trip.startDate != null) {
      parts.add(DateFormat('MMM yyyy').format(_trip.startDate!));
    }
    return parts.join(' · ');
  }

  MemberEntity? get _owner {
    try {
      return _pub.members.firstWhere((m) => m.role == 'owner');
    } catch (_) {
      return _pub.members.isNotEmpty ? _pub.members.first : null;
    }
  }

  int get _placesCount {
    final uniqueItems = <String>{};
    for (final rec in _pub.checkinRecommendations) {
      uniqueItems.add(rec.checkinId);
    }
    return uniqueItems.length;
  }

  int get _photoCount {
    return _pub.checkinRecommendations
        .fold(0, (sum, r) => sum + r.media.length);
  }

  int get _spontaneousCount {
    return _pub.checkinRecommendations.where((r) => r.isSpontaneous).length;
  }

  Map<int, List<PublicCheckinRecEntity>> get _recsByDay {
    final map = <int, List<PublicCheckinRecEntity>>{};
    for (final rec in _pub.checkinRecommendations) {
      map.putIfAbsent(rec.day, () => []).add(rec);
    }
    return map;
  }

  List<int> get _sortedDays {
    final days = _recsByDay.keys.toList()..sort();
    return days;
  }

  bool _isOwner(String? currentUserId) {
    if (currentUserId == null) return false;
    return _pub.members
        .any((m) => m.userId == currentUserId && m.role == 'owner');
  }

  Future<void> _handlePublishToggle(BuildContext context) async {
    setState(() => _isPublishing = true);
    try {
      final actions = ref.read(publishTripActionsProvider);
      if (_trip.status == TripStatus.published) {
        await actions.unpublish(widget.tripId);
      } else {
        await actions.publish(widget.tripId);
      }
      ref.invalidate(publicTripProvider(widget.tripId));
      ref.invalidate(tripsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _trip.status == TripStatus.published
                  ? 'trip unpublished'
                  : 'trip published',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profileAsync = isAuthenticated ? ref.watch(profileProvider) : null;
    final currentUserId = profileAsync?.valueOrNull?.id;
    final isOwner = _isOwner(currentUserId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, isOwner),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVibeBadgesRow(),
                    _buildTripHeader(),
                    _buildOwnerRow(),
                    _buildDivider(),
                    _buildStatsRow(),
                    _buildDivider(),
                    _buildDaySections(),
                    _buildLockNotice(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
          // Publish button for non-published trips (owner only)
          if (isOwner && _trip.status != TripStatus.published)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed:
                      _isPublishing ? null : () => _handlePublishToggle(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('publish this trip'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isOwner) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withAlpha(220),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: AppColors.text),
        ),
      ),
      actions: [
        if (isOwner && _trip.status == TripStatus.published)
          TextButton(
            onPressed: _isPublishing
                ? null
                : () => _handlePublishToggle(context),
            child: _isPublishing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.textMuted,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'unpublish',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
          ),
        IconButton(
          icon: const Icon(Icons.ios_share,
              size: 20, color: AppColors.text),
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                  text:
                      'Check out this trip: ${_trip.title}'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('link copied')),
            );
          },
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border,
              size: 20, color: AppColors.text),
          onPressed: () {},
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.surfaceVariant,
        ),
      ),
    );
  }

  Widget _buildVibeBadgesRow() {
    if (_durationLabel.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              _durationLabel,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _trip.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _destinationDateLine,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerRow() {
    final owner = _owner;
    if (owner == null) return const SizedBox.shrink();

    final initial =
        owner.displayName.isNotEmpty ? owner.displayName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          AvatarCircleWidget(
            label: initial,
            seed: owner.handle,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner.displayName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${owner.handle} · ${_pub.members.length} people went',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Text(
              'follow',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColors.surfaceVariant,
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '$_placesCount',
              label: 'places',
            ),
          ),
          const VerticalDivider(
            color: AppColors.surfaceVariant,
            thickness: 1,
            width: 1,
          ),
          Expanded(
            child: _StatCell(
              value: '$_photoCount',
              label: 'photos',
            ),
          ),
          const VerticalDivider(
            color: AppColors.surfaceVariant,
            thickness: 1,
            width: 1,
          ),
          Expanded(
            child: _StatCell(
              value: '✶ $_spontaneousCount',
              label: 'unplanned',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySections() {
    if (_pub.checkinRecommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'no public memories yet',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    final days = _sortedDays;
    final recsByDay = _recsByDay;
    final hasMoreThan2Days = days.length > 2;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day
            in _allDaysExpanded ? days : days.take(2).toList()) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Day $day',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ...() {
            final recs = recsByDay[day] ?? [];
            final toShow =
                _allDaysExpanded ? recs : recs.take(2).toList();
            return toShow
                .map((rec) => _RecItem(rec: rec))
                .toList();
          }(),
          if (!_allDaysExpanded && (recsByDay[day]?.length ?? 0) > 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GestureDetector(
                onTap: () => setState(() => _allDaysExpanded = true),
                child: Text(
                  'see all ${recsByDay[day]!.length} stops',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
        if (hasMoreThan2Days && !_allDaysExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: GestureDetector(
              onTap: () => setState(() => _allDaysExpanded = true),
              child: Row(
                children: [
                  Text(
                    'see all ${days.length} days',
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more,
                      size: 16, color: AppColors.accentGreen),
                ],
              ),
            ),
          ),
        if (_allDaysExpanded && hasMoreThan2Days)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: GestureDetector(
              onTap: () => setState(() => _allDaysExpanded = false),
              child: Row(
                children: [
                  const Text(
                    'show less',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_less,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
      ],
    );

    return content;
  }

  Widget _buildLockNotice() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 16),
      child: const Text(
        '🔒 logistics and private notes are never shown here',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
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
              _BottomNavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'trips',
                selected: false,
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'explore',
                selected: true,
                onTap: () {},
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/trips/create'),
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
              _BottomNavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'activity',
                selected: false,
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'profile',
                selected: false,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecItem extends StatelessWidget {
  const _RecItem({required this.rec});

  final PublicCheckinRecEntity rec;

  @override
  Widget build(BuildContext context) {
    final hasMedia = rec.media.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: hasMedia
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      rec.media.first.url,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: AppColors.border,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: AppColors.border,
                  ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rec.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _RecBadge(isSpontaneous: rec.isSpontaneous),
                  ],
                ),
                if (rec.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    rec.body,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (rec.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${rec.tags.first}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecBadge extends StatelessWidget {
  const _RecBadge({required this.isSpontaneous});

  final bool isSpontaneous;

  @override
  Widget build(BuildContext context) {
    final bg =
        isSpontaneous ? AppColors.coralLight : AppColors.accentGreenLight;
    final textColor =
        isSpontaneous ? AppColors.coral : AppColors.accentGreenDark;
    final label =
        isSpontaneous ? '✶ unplanned' : 'must visit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
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
