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
import 'package:memories_app/shared/widgets/app_bottom_nav.dart';
import 'package:memories_app/shared/widgets/app_trip_card.dart';
import 'package:memories_app/shared/widgets/avatar_circle.dart';

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
            color: AppColors.accentGreen,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.coral, size: 36),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Could not load profile',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(profileProvider.notifier).refresh(),
                  child: const Text('Retry'),
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
                    color: AppColors.accentGreen,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load trips',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                data: (trips) => RefreshIndicator(
                  color: AppColors.accentGreen,
                  onRefresh: () async {
                    await ref.read(tripsProvider.notifier).refresh();
                    await ref.read(profileProvider.notifier).refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                    children: [
                      _buildStatsRow(trips),
                      const SizedBox(height: AppSpacing.md),
                      if (trips.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              'No trips yet',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ...trips.map(
                          (trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppTripCard(
                              trip: trip,
                              members: const [],
                              variant: TripCardVariant.list,
                              onTap: () {
                                if (trip.status == TripStatus.published) {
                                  context.push('/public/trips/${trip.id}');
                                } else {
                                  context.push('/trips/${trip.id}/timeline');
                                }
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      _DemoModeToggle(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.profile,
        onSelect: (tab) {
          switch (tab) {
            case AppTab.home:
              context.go('/home');
            case AppTab.journeys:
              context.go('/home');
            case AppTab.memories:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            case AppTab.profile:
              // Already here — no-op.
              break;
          }
        },
        onAdd: () => context.push('/trips/create'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : profile.handle[0].toUpperCase();

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back + actions
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.text),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showEditSheet(context, ref),
                child: Text(
                  'Edit profile',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.accentGreen),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () async {
                  ref.invalidate(tripsProvider);
                  ref.invalidate(currentUserIdProvider);
                  ref.invalidate(profileProvider);
                  await ref.read(authProvider.notifier).signOut();
                },
                child: Text(
                  'Sign out',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.coral),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Avatar + name row
          Row(
            children: [
              AvatarCircle(
                label: initial,
                seed: profile.handle,
                size: 60,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTextStyles.displaySmall
                          .copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '@${profile.handle}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
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
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          _StatChip(
            value: '${trips.length}',
            label: trips.length == 1 ? 'Trip' : 'Trips',
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatChip(
            value:
                '${trips.where((t) => t.status == TripStatus.published).length}',
            label: 'Published',
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
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
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
        left: AppSpacing.md + 4,
        right: AppSpacing.md + 4,
        top: AppSpacing.md + 4,
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
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          Text(
            'Edit profile',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Display name',
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Your name',
            ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
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
                          SnackBar(content: Text('Failed to save: $e')),
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
                : const Text('Save'),
          ),
          const SizedBox(height: AppSpacing.lg),
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
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
        ),
        subtitle: Text(
          isDemo ? 'Using mock data' : 'Using real backend',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        value: isDemo,
        activeColor: AppColors.primary,
        onChanged: (val) {
          ref.read(demoModeProvider.notifier).state = val;
        },
      ),
    );
  }
}
