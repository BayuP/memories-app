import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/demo/demo_flag.dart' show demoModeProvider;
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

class ItineraryReviewPage extends ConsumerStatefulWidget {
  const ItineraryReviewPage({
    super.key,
    required this.tripId,
    required this.initialItems,
  });

  final String tripId;
  final List<ItineraryItemEntity> initialItems;

  @override
  ConsumerState<ItineraryReviewPage> createState() =>
      _ItineraryReviewPageState();
}

class _ItineraryReviewPageState extends ConsumerState<ItineraryReviewPage> {
  final _chatController = TextEditingController();
  bool _sendingMessage = false;
  final List<Map<String, String>> _chatHistory = [];

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Map<int, List<ItineraryItemEntity>> _groupByDay(
      List<ItineraryItemEntity> items) {
    final map = <int, List<ItineraryItemEntity>>{};
    for (final item in items) {
      map.putIfAbsent(item.day, () => []).add(item);
    }
    return map;
  }

  String _dayLabel(int day, TripDetailEntity? detail) {
    if (day == 0) return 'day 0 · departure';
    if (detail?.trip.startDate != null) {
      final date =
          detail!.trip.startDate!.add(Duration(days: day - 1));
      final label = DateFormat('EEE, MMM d').format(date).toLowerCase();
      return 'day $day · $label';
    }
    return 'day $day';
  }

  String _itemEmoji(ItineraryItemEntity item) {
    final titleLower = item.title.toLowerCase();
    final source = item.source.toLowerCase();
    if (source.contains('flight') ||
        titleLower.contains('flight') ||
        titleLower.contains('depart') ||
        titleLower.contains('arrive') ||
        titleLower.contains('airport')) {
      return '✈️';
    }
    if (titleLower.contains('hotel') ||
        titleLower.contains('hostel') ||
        titleLower.contains('accommodation') ||
        titleLower.contains('stay') ||
        titleLower.contains('check-in') ||
        titleLower.contains('check in')) {
      return '🏨';
    }
    return '📍';
  }

  Future<void> _sendMessage() async {
    final msg = _chatController.text.trim();
    if (msg.isEmpty) return;

    _chatController.clear();
    setState(() => _sendingMessage = true);

    _chatHistory.add({'role': 'user', 'content': msg});

    // DEMO: return a canned reply without hitting the AI endpoint
    if (ref.read(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 800));
      const reply =
          'Got it! In demo mode the itinerary stays fixed — but the AI refine feature works great with a real backend.';
      _chatHistory.add({'role': 'assistant', 'content': reply});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(reply),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _sendingMessage = false);
      }
      return;
    }
    // DEMO: real refine call below

    try {
      final reply = await ref
          .read(tripsRepositoryProvider)
          .refineItinerary(widget.tripId, msg, List.from(_chatHistory));

      _chatHistory.add({'role': 'assistant', 'content': reply});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reply),
          duration: const Duration(seconds: 5),
        ),
      );

      // Re-fetch items
      await ref.read(itineraryItemsProvider(widget.tripId).notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed to refine: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(tripDetailProvider(widget.tripId));
    final itemsAsync = ref.watch(itineraryItemsProvider(widget.tripId));

    final detail = detailAsync.value;
    final items = itemsAsync.value ?? widget.initialItems;
    final grouped = _groupByDay(items);
    final sortedDays = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: const BackButton(),
        title: Text(detail?.trip.title ?? 'itinerary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.textMuted, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip metadata
          if (detail != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        detail.trip.destination,
                        style: AppTextStyles.uiLabel(color: AppColors.textHint),
                      ),
                      if (detail.trip.startDate != null &&
                          detail.trip.endDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: AppTextStyles.uiLabel(
                              color: AppColors.textHint),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('MMM d').format(detail.trip.startDate!)} – ${DateFormat('MMM d').format(detail.trip.endDate!)}',
                          style: AppTextStyles.uiLabel(
                              color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                  if (detail.trip.vibes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: detail.trip.vibes
                          .map(
                            (v) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.grayLight,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                v,
                                style: AppTextStyles.uiLabel(
                                    color: AppColors.textHint),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          const Divider(height: 1),
          // Items list
          Expanded(
            child: itemsAsync.isLoading && items.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.teal, strokeWidth: 2),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: sortedDays.length,
                    itemBuilder: (context, dayIndex) {
                      final day = sortedDays[dayIndex];
                      final dayItems = grouped[day]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              _dayLabel(day, detail),
                              style: AppTextStyles.uiLabel(
                                      color: AppColors.textMuted)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          ...dayItems.map(
                            (item) => _ItineraryItemTile(
                              item: item,
                              emoji: _itemEmoji(item),
                              onDelete: () => _confirmDelete(item),
                              onTap: () => _showEditSheet(item),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      // Chat input + CTA
      bottomSheet: _BottomSheet(
        controller: _chatController,
        sending: _sendingMessage,
        onSend: _sendMessage,
        onFinish: () => context.go('/trips/${widget.tripId}/timeline'),
      ),
    );
  }

  Future<void> _confirmDelete(ItineraryItemEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('remove item?'),
        content: Text(
          'remove "${item.title}" from the itinerary?',
          style: AppTextStyles.bodySmall(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(itineraryItemsProvider(widget.tripId).notifier)
          .deleteItem(item.id);
    }
  }

  Future<void> _showEditSheet(ItineraryItemEntity item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _EditItemSheet(
        item: item,
        tripId: widget.tripId,
        onSaved: () => Navigator.pop(ctx),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Itinerary item tile with swipe-to-delete
// ---------------------------------------------------------------------------

class _ItineraryItemTile extends StatelessWidget {
  const _ItineraryItemTile({
    required this.item,
    required this.emoji,
    required this.onDelete,
    required this.onTap,
  });

  final ItineraryItemEntity item;
  final String emoji;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves in confirmDismiss callback
      },
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.coral,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.drag_handle,
                  color: AppColors.grayMid, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(7),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.startTime != null ||
                                item.description != null)
                              const SizedBox(height: 2),
                            if (item.startTime != null)
                              Text(
                                [item.startTime, item.endTime]
                                    .where((t) => t != null)
                                    .join(' – '),
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 9,
                                ),
                              ),
                            if (item.description != null &&
                                item.description!.isNotEmpty)
                              Text(
                                item.description!,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.grayMid, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet with chat + finish
// ---------------------------------------------------------------------------

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onFinish,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: AppTextStyles.uiInput().copyWith(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ask AI to refine...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sending ? null : onSend,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sending ? AppColors.grayMid : AppColors.text,
                    shape: BoxShape.circle,
                  ),
                  child: sending
                      ? const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(Icons.arrow_upward,
                          color: AppColors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onFinish,
            child: const Text("looks good — let's go"),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit item bottom sheet
// ---------------------------------------------------------------------------

class _EditItemSheet extends ConsumerStatefulWidget {
  const _EditItemSheet({
    required this.item,
    required this.tripId,
    required this.onSaved,
  });

  final ItineraryItemEntity item;
  final String tripId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<_EditItemSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _startCtrl = TextEditingController(text: widget.item.startTime ?? '');
    _endCtrl = TextEditingController(text: widget.item.endTime ?? '');
    _descCtrl = TextEditingController(text: widget.item.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        if (_startCtrl.text.trim().isNotEmpty)
          'start_time': _startCtrl.text.trim(),
        if (_endCtrl.text.trim().isNotEmpty)
          'end_time': _endCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
      };
      await ref
          .read(itineraryItemsProvider(widget.tripId).notifier)
          .updateItem(widget.item.id, body);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed to save: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottomInset),
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
          const SizedBox(height: 16),
          const Text(
            'edit item',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _SheetField(label: 'TITLE', controller: _titleCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _SheetField(
                      label: 'START TIME', controller: _startCtrl,
                      hint: 'HH:mm')),
              const SizedBox(width: 12),
              Expanded(
                  child: _SheetField(
                      label: 'END TIME', controller: _endCtrl, hint: 'HH:mm')),
            ],
          ),
          const SizedBox(height: 12),
          _SheetField(
              label: 'DESCRIPTION', controller: _descCtrl, maxLines: 3),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2),
                  )
                : const Text('save changes'),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.uiLabel(color: AppColors.textMuted).copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.uiInput(),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
