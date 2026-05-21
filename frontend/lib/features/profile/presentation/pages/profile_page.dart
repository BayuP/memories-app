import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/demo/demo_flag.dart' show demoModeProvider;
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/profile/domain/entities/profile_entity.dart';
import 'package:memories_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/features/trips/presentation/widgets/trip_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
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
                  'could not load profile',
                  style:
                      AppTextStyles.bodyMedium(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(profileProvider.notifier).refresh(),
                  child: const Text('retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) => _ProfileContent(profile: profile),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref),
            Expanded(
              child: tripsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'failed to load trips',
                    style: AppTextStyles.bodySmall(),
                  ),
                ),
                data: (trips) => RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: () async {
                    await ref.read(tripsProvider.notifier).refresh();
                    await ref.read(profileProvider.notifier).refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _buildStatsRow(trips),
                      const SizedBox(height: 16),
                      if (trips.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              'no trips yet',
                              style: AppTextStyles.bodyMedium(
                                  color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ...trips.map(
                          (trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TripCard(
                              trip: trip,
                              members: const [],
                              onTap: () {
                                if (trip.status == TripStatus.published) {
                                  context
                                      .push('/public/trips/${trip.id}');
                                } else {
                                  context.push(
                                      '/trips/${trip.id}/timeline');
                                }
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _DemoModeToggle(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : profile.handle[0].toUpperCase();

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back + actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.text),
                onPressed: () => context.pop(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showEditSheet(context, ref),
                child: Text(
                  'edit profile',
                  style: AppTextStyles.uiLabel(color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                },
                child: Text(
                  'sign out',
                  style: AppTextStyles.uiLabel(color: AppColors.coral),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar + name row
          Row(
            children: [
              AvatarCircleWidget(
                label: initial,
                seed: profile.handle,
                size: 60,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTextStyles.displaySmall(color: AppColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.handle}',
                      style: AppTextStyles.bodySmall(
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<TripEntity> trips) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          _StatChip(
            value: '${trips.length}',
            label: 'trip${trips.length == 1 ? '' : 's'}',
          ),
          const SizedBox(width: 8),
          _StatChip(
            value: '${trips.where((t) => t.status == TripStatus.published).length}',
            label: 'published',
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (sheetContext) => _EditProfileSheet(
        profile: profile,
        onSave: (newName) async {
          Navigator.of(sheetContext).pop();
          await ref
              .read(profileProvider.notifier)
              .updateProfile(displayName: newName);
        },
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
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'trips',
                selected: false,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'explore',
                selected: false,
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
              _NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'activity',
                selected: false,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'profile',
                selected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.onSave});

  final ProfileEntity profile;
  final Future<void> Function(String displayName) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayMid,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'edit profile',
            style: AppTextStyles.bodyLarge(color: AppColors.text)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'display name',
            style: AppTextStyles.uiLabel(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTextStyles.uiInput(),
            decoration: const InputDecoration(
              hintText: 'your name',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    setState(() => _saving = true);
                    try {
                      await widget.onSave(name);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('failed to save: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('save'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DemoModeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(demoModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(
          'Demo Mode',
          style: AppTextStyles.bodyMedium(color: AppColors.text),
        ),
        subtitle: Text(
          isDemo ? 'Using mock data' : 'Using real backend',
          style: AppTextStyles.bodySmall(color: AppColors.textMuted),
        ),
        value: isDemo,
        activeColor: AppColors.teal,
        onChanged: (val) {
          ref.read(demoModeProvider.notifier).state = val;
        },
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
