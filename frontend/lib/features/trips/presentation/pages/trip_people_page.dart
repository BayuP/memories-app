import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/shared/widgets/app_state_badge.dart';
import 'package:memories_app/shared/widgets/app_states.dart';
import 'package:memories_app/shared/widgets/avatar_circle.dart';

// ---------------------------------------------------------------------------
// Trip People Page — "People in this journey"
// ---------------------------------------------------------------------------

class TripPeoplePage extends ConsumerWidget {
  const TripPeoplePage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('People', style: AppTextStyles.appBarTitle),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accentGreen, strokeWidth: 2),
        ),
        error: (e, _) => AppErrorState(
          message: 'Could not load members',
          onRetry: () => ref.invalidate(tripDetailProvider(tripId)),
        ),
        data: (detail) {
          final trip = detail.trip;
          final members = detail.members;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                child: Text(
                  'People in this journey',
                  style: AppTextStyles.headlineMedium,
                ),
              ),
              if (members.isEmpty)
                const Expanded(
                  child: AppEmptyState(
                    emoji: '👥',
                    title: 'No members yet',
                    subtitle:
                        'Invite people to share this trip with you.',
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isOwner = member.userId == trip.ownerId;

                      return _MemberRow(
                        member: member,
                        isOwner: isOwner,
                        // Show remove button for all non-owner members.
                        // The backend enforces that only the trip owner can remove.
                        canRemove: !isOwner,
                        onRemove: () => _confirmRemove(context, ref, member),
                      );
                    },
                  ),
                ),

              // Add People button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
                child: SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddPeopleSheet(context, ref, trip),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add People'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Remove member confirmation
  // ---------------------------------------------------------------------------

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    MemberEntity member,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.displayName} from this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(tripsRepositoryProvider);
                await repo.removeMember(tripId, member.userId);
                ref.invalidate(tripDetailProvider(tripId));
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to remove member')),
                  );
                }
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add people bottom sheet
  // ---------------------------------------------------------------------------

  void _showAddPeopleSheet(
    BuildContext context,
    WidgetRef ref,
    TripEntity trip,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => _AddPeopleSheet(tripId: tripId),
    );
  }
}

// ---------------------------------------------------------------------------
// Member row
// ---------------------------------------------------------------------------

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isOwner,
    required this.canRemove,
    required this.onRemove,
  });

  final MemberEntity member;
  final bool isOwner;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          AvatarCircle(
            label: initial,
            seed: member.userId,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                if (member.handle.isNotEmpty)
                  Text(
                    '@${member.handle}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          AppStateBadge(
            state: isOwner ? AppBadgeState.ongoing : AppBadgeState.shared,
            label: isOwner ? 'Owner' : 'Member',
          ),
          if (canRemove) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add People sheet — handle search
// ---------------------------------------------------------------------------

class _AddPeopleSheet extends ConsumerStatefulWidget {
  const _AddPeopleSheet({required this.tripId});

  final String tripId;

  @override
  ConsumerState<_AddPeopleSheet> createState() => _AddPeopleSheetState();
}

class _AddPeopleSheetState extends ConsumerState<_AddPeopleSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _adding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(userSearchResultsProvider(_query));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 4, AppSpacing.md, AppSpacing.sm),
              child: Text('Add People', style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by handle or name',
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.textMuted),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 0),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(Icons.close,
                              size: 16, color: AppColors.textMuted),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: searchResults.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(
                      color: AppColors.accentGreen, strokeWidth: 2),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('Search failed — try again'),
                ),
                data: (users) {
                  if (users.isEmpty && _query.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text('No users found'),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final initial = user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        leading: AvatarCircle(
                          label: initial,
                          seed: user.id,
                          size: 36,
                        ),
                        title: Text(
                          user.displayName,
                          style: AppTextStyles.labelMedium,
                        ),
                        subtitle: Text(
                          '@${user.handle}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: _adding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentGreen),
                              )
                            : TextButton(
                                onPressed: () => _addMember(user.id),
                                child: const Text('Add'),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _addMember(String userId) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final repo = ref.read(tripsRepositoryProvider);
      await repo.addMember(widget.tripId, userId);
      ref.invalidate(tripDetailProvider(widget.tripId));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add member')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}
