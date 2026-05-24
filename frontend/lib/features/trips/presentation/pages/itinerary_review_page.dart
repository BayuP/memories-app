import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memories_app/core/demo/demo_flag.dart' show demoModeProvider;
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

// ---------------------------------------------------------------------------
// Item categories — drive the list icon and the add-item picker.
// ---------------------------------------------------------------------------

const Map<String, String> kItemCategories = {
  'restaurant': '🍽️',
  'cafe': '☕',
  'hotel': '🏨',
  'flight': '✈️',
  'transport': '🚗',
  'sightseeing': '🏛️',
  'beach': '🏖️',
  'shopping': '🛍️',
  'activity': '🎟️',
  'nightlife': '🍸',
  'nature': '🏞️',
  'other': '⭐',
};

/// Formats a backend time string (`HH:mm:ss.ffffff`) down to `HH:mm`.
String? formatTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

class ItineraryReviewPage extends ConsumerStatefulWidget {
  const ItineraryReviewPage({
    super.key,
    required this.tripId,
    required this.initialItems,
    this.aiEnabled = true,
  });

  final String tripId;
  final List<ItineraryItemEntity> initialItems;

  /// When false, AI refine is hidden and the page is a manual itinerary builder.
  final bool aiEnabled;

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
    // Re-arrange each day by start time so a newly added earlier activity
    // slots into the right place. Items without a time sink to the bottom.
    for (final dayItems in map.values) {
      dayItems.sort((a, b) {
        final ta = formatTime(a.startTime);
        final tb = formatTime(b.startTime);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb);
      });
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
    // Prefer the explicit category when set.
    final cat = item.category?.toLowerCase();
    if (cat != null && kItemCategories.containsKey(cat)) {
      return kItemCategories[cat]!;
    }
    final t = item.title.toLowerCase();
    final desc = (item.description ?? '').toLowerCase();
    final combined = '$t $desc';

    if (t.contains('flight') || t.contains('depart') ||
        t.contains('arrive') || t.contains('airport') || t.contains('→')) {
      return '✈️';
    }
    if (t.contains('hotel') || t.contains('hostel') || t.contains('resort') ||
        t.contains('check-in') || t.contains('check in') ||
        t.contains('accommodation') || t.contains('stay')) {
      return '🏨';
    }
    if (t.contains('café') || t.contains('cafe') || t.contains('coffee')) {
      return '☕';
    }
    if (t.contains('dinner') || t.contains('lunch') || t.contains('breakfast') ||
        t.contains('restaurant') || t.contains('seafood') || t.contains('food') ||
        t.contains('eat') || combined.contains('nasi') || combined.contains('duck')) {
      return '🍽️';
    }
    if (t.contains('bar') || t.contains('nightlife') || t.contains('club') ||
        t.contains('cocktail')) {
      return '🍸';
    }
    if (t.contains('beach') || t.contains('surf') || t.contains('bay')) {
      return '🏖️';
    }
    if (t.contains('waterfall') || t.contains('rice terrace') ||
        t.contains('rice field') || t.contains('jungle') || t.contains('forest') ||
        t.contains('nature') || t.contains('hike') || t.contains('trek')) {
      return '🏞️';
    }
    if (t.contains('temple') || t.contains('museum') || t.contains('palace') ||
        t.contains('monument') || t.contains('sacred') || t.contains('pura')) {
      return '🏛️';
    }
    if (t.contains('market') || t.contains('shopping') || t.contains('mall')) {
      return '🛍️';
    }
    if (t.contains('atv') || t.contains('scooter') || t.contains('motorbike') ||
        t.contains('ride') || t.contains('bike') || t.contains('motor')) {
      return '🏍️';
    }
    if (t.contains('spa') || t.contains('massage') || t.contains('wellness')) {
      return '💆';
    }
    return '⭐';
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
          TextButton.icon(
            onPressed: () => _showAddSheet(detail),
            icon: const Icon(Icons.add, size: 18, color: AppColors.text),
            label: const Text('add',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
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
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        detail.trip.destination,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                      if (detail.trip.startDate != null &&
                          detail.trip.endDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('MMM d').format(detail.trip.startDate!)} – ${DateFormat('MMM d').format(detail.trip.endDate!)}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
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
                                color: AppColors.surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                v,
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
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
                        color: AppColors.accentGreen, strokeWidth: 2),
                  )
                : items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_note_outlined,
                                  size: 32, color: AppColors.textMuted),
                              const SizedBox(height: 10),
                              Text(
                                'no plans yet — tap + to add',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
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
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
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
      // AI refine + CTA when AI is enabled; manual trips get a finish-only bar.
      bottomSheet: widget.aiEnabled
          ? _BottomSheet(
              controller: _chatController,
              sending: _sendingMessage,
              onSend: _sendMessage,
              onFinish: () => context.go('/trips/${widget.tripId}/timeline'),
            )
          : _FinishBar(
              onFinish: () => context.go('/trips/${widget.tripId}/timeline'),
            ),
    );
  }

  Future<void> _showAddSheet(TripDetailEntity? detail) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddItemSheet(
        tripId: widget.tripId,
        tripStart: detail?.trip.startDate,
        tripEnd: detail?.trip.endDate,
        onSaved: () => Navigator.pop(ctx),
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
          style: AppTextStyles.bodySmall,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.drag_handle,
                  color: AppColors.border, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon box
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.startTime != null ||
                                item.description != null)
                              const SizedBox(height: 2),
                            if (item.startTime != null)
                              Text(
                                '${[formatTime(item.startTime), formatTime(item.endTime)].where((t) => t != null).join(' → ')} · tap to edit',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              )
                            else
                              const Text(
                                'tap to edit',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            if (item.description != null &&
                                item.description!.isNotEmpty)
                              Text(
                                item.description!,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.border, size: 14),
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
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
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
                    color: sending ? AppColors.border : AppColors.text,
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
  late final TextEditingController _locationCtrl;
  late final TextEditingController _descCtrl;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item.title);
    _locationCtrl = TextEditingController(text: item.locationName ?? '');
    _descCtrl = TextEditingController(text: item.description ?? '');
    _category = item.category;
    _startTime = _parseTime(item.startTime);
    _endTime = _parseTime(item.endTime);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _displayTime(TimeOfDay t) => t.format(context);

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.accentGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'title': title,
        if (_startTime != null) 'start_time': _fmtTime(_startTime!),
        if (_endTime != null) 'end_time': _fmtTime(_endTime!),
        if (_category != null) 'category': _category,
        if (_locationCtrl.text.trim().isNotEmpty)
          'location_name': _locationCtrl.text.trim(),
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
      child: SingleChildScrollView(
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
                  child: _SheetPickerButton(
                    label: 'START TIME',
                    value: _startTime != null ? _displayTime(_startTime!) : null,
                    hint: 'pick time',
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetPickerButton(
                    label: 'END TIME',
                    value: _endTime != null ? _displayTime(_endTime!) : null,
                    hint: 'pick time',
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'CATEGORY',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted)
                  .copyWith(fontSize: 10, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kItemCategories.entries.map((e) {
                final selected = _category == e.key;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _category = selected ? null : e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.text
                          : AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      border: selected
                          ? null
                          : Border.all(
                              color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      '${e.value} ${e.key}',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? AppColors.white
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: 'LOCATION',
              controller: _locationCtrl,
              hint: 'place name',
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: 'DESCRIPTION',
              controller: _descCtrl,
              maxLines: 3,
            ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Finish-only bar (manual trips, no AI refine)
// ---------------------------------------------------------------------------

class _FinishBar extends StatelessWidget {
  const _FinishBar({required this.onFinish});

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
      child: ElevatedButton(
        onPressed: onFinish,
        child: const Text("looks good — let's go"),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add item bottom sheet (manual entry)
// ---------------------------------------------------------------------------

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({
    required this.tripId,
    required this.onSaved,
    this.tripStart,
    this.tripEnd,
  });

  final String tripId;
  final VoidCallback onSaved;
  final DateTime? tripStart;
  final DateTime? tripEnd;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  // Fallback day stepper, used only when the trip has no start date.
  final _dayCtrl = TextEditingController(text: '1');

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.tripStart;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final start = widget.tripStart ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? start,
      firstDate: widget.tripStart ?? DateTime(2020),
      lastDate: widget.tripEnd ?? DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'title is required');
      return;
    }

    // Map the chosen date back to the trip's day index; fall back to the
    // manual day stepper when the trip has no start date.
    int day;
    if (widget.tripStart != null) {
      if (_date == null) {
        setState(() => _error = 'pick a date');
        return;
      }
      final start = DateUtils.dateOnly(widget.tripStart!);
      day = DateUtils.dateOnly(_date!).difference(start).inDays + 1;
      if (day < 1) {
        setState(() => _error = 'date is before the trip starts');
        return;
      }
    } else {
      final parsed = int.tryParse(_dayCtrl.text.trim());
      if (parsed == null || parsed < 1) {
        setState(() => _error = 'day must be 1 or more');
        return;
      }
      day = parsed;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'day': day,
        'title': title,
        if (_startTime != null) 'start_time': _fmt(_startTime!),
        if (_endTime != null) 'end_time': _fmt(_endTime!),
        if (_category != null) 'category': _category,
        if (_locationCtrl.text.trim().isNotEmpty)
          'location_name': _locationCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
      };
      await ref
          .read(itineraryItemsProvider(widget.tripId).notifier)
          .createItem(body);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'failed to add: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottomInset),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            const Text(
              'add item',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _SheetField(label: 'TITLE', controller: _titleCtrl),
            const SizedBox(height: 12),
            // Date (or fallback day) picker
            if (widget.tripStart != null)
              _SheetPickerButton(
                label: 'DATE',
                value: _date != null
                    ? DateFormat('EEE, MMM d').format(_date!)
                    : null,
                hint: 'pick a date',
                onTap: _pickDate,
              )
            else
              SizedBox(
                width: 90,
                child: _SheetField(label: 'DAY', controller: _dayCtrl),
              ),
            const SizedBox(height: 12),
            // Time pickers
            Row(
              children: [
                Expanded(
                  child: _SheetPickerButton(
                    label: 'START TIME',
                    value: _startTime != null ? _fmt(_startTime!) : null,
                    hint: 'pick time',
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetPickerButton(
                    label: 'END TIME',
                    value: _endTime != null ? _fmt(_endTime!) : null,
                    hint: 'pick time',
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Category chips
            Text(
              'CATEGORY',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted)
                  .copyWith(fontSize: 10, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kItemCategories.entries.map((e) {
                final selected = _category == e.key;
                return GestureDetector(
                  onTap: () => setState(
                      () => _category = selected ? null : e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.text
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      '${e.value} ${e.key}',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? AppColors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _SheetField(label: 'LOCATION', controller: _locationCtrl),
            const SizedBox(height: 12),
            _SheetField(
                label: 'DESCRIPTION', controller: _descCtrl, maxLines: 3),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.coral, fontSize: 12),
              ),
            ],
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
                  : const Text('add to itinerary'),
            ),
          ],
        ),
      ),
    );
  }
}

// A labeled tappable field that mimics _SheetField but opens a picker.
class _SheetPickerButton extends StatelessWidget {
  const _SheetPickerButton({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textMuted)
              .copyWith(fontSize: 10, letterSpacing: 0.8),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? hint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: value == null ? AppColors.textMuted : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ],
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
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted).copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
