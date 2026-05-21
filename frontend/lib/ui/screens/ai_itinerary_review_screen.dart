import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'trip_view_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

class _ItineraryItem {
  _ItineraryItem({
    required this.id,
    required this.time,
    required this.name,
    required this.location,
    this.notes = '',
    this.isAiSuggested = true,
  });

  final String id;
  String time;
  String name;
  String location;
  String notes;
  final bool isAiSuggested;
}

class _ItineraryDay {
  const _ItineraryDay({required this.label, required this.items});

  final String label;
  final List<_ItineraryItem> items;
}

List<_ItineraryDay> _buildMockDays() => [
      _ItineraryDay(
        label: 'Day 0 — Departure',
        items: [
          _ItineraryItem(
            id: 'd0-1',
            time: '06:00',
            name: 'Depart from Jakarta (CGK)',
            location: 'Soekarno-Hatta International Airport',
            notes: 'Terminal 3. Check in 2 hrs early.',
            isAiSuggested: false,
          ),
          _ItineraryItem(
            id: 'd0-2',
            time: '08:30',
            name: 'Arrive Bali (DPS)',
            location: 'Ngurah Rai International Airport',
          ),
        ],
      ),
      _ItineraryDay(
        label: 'Day 1 — Seminyak',
        items: [
          _ItineraryItem(
            id: 'd1-1',
            time: '10:00',
            name: 'Check in to villa',
            location: 'The Layar, Seminyak',
          ),
          _ItineraryItem(
            id: 'd1-2',
            time: '12:30',
            name: 'Lunch at Sate Bali',
            location: 'Jl. Laksmana, Seminyak',
            notes: 'Try the mixed satay platter',
          ),
          _ItineraryItem(
            id: 'd1-3',
            time: '15:00',
            name: 'Seminyak Square shopping',
            location: 'Seminyak Square',
          ),
          _ItineraryItem(
            id: 'd1-4',
            time: '18:30',
            name: 'Sunset at Ku De Ta',
            location: 'Jl. Kayu Aya, Seminyak',
            notes: 'Book a table — gets crowded',
          ),
        ],
      ),
      _ItineraryDay(
        label: 'Day 2 — Ubud',
        items: [
          _ItineraryItem(
            id: 'd2-1',
            time: '08:00',
            name: 'Tegallalang Rice Terrace',
            location: 'Tegallalang, Ubud',
          ),
          _ItineraryItem(
            id: 'd2-2',
            time: '11:00',
            name: 'Ubud Monkey Forest',
            location: 'Mandala Wisata Wenara Wana',
          ),
          _ItineraryItem(
            id: 'd2-3',
            time: '14:00',
            name: 'Lunch at Locavore',
            location: 'Jl. Dewi Sita, Ubud',
            notes: 'Reservation required!',
          ),
        ],
      ),
      _ItineraryDay(
        label: 'Day 3 — Return',
        items: [
          _ItineraryItem(
            id: 'd3-1',
            time: '09:00',
            name: 'Check out',
            location: 'The Layar, Seminyak',
            isAiSuggested: false,
          ),
          _ItineraryItem(
            id: 'd3-2',
            time: '14:00',
            name: 'Depart from Bali (DPS)',
            location: 'Ngurah Rai International Airport',
            isAiSuggested: false,
          ),
        ],
      ),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AiItineraryReviewScreen extends StatefulWidget {
  const AiItineraryReviewScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  final String tripId;
  final String? tripTitle;

  @override
  State<AiItineraryReviewScreen> createState() =>
      _AiItineraryReviewScreenState();
}

class _AiItineraryReviewScreenState extends State<AiItineraryReviewScreen> {
  late List<_ItineraryDay> _days;
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _days = _buildMockDays();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _removeItem(int dayIndex, int itemIndex) {
    setState(() {
      _days[dayIndex].items.removeAt(itemIndex);
    });
  }

  void _addItem(int dayIndex) {
    setState(() {
      _days[dayIndex].items.add(_ItineraryItem(
        id: 'new-${DateTime.now().millisecondsSinceEpoch}',
        time: '12:00',
        name: 'New item',
        location: '',
        isAiSuggested: false,
      ));
    });
  }

  void _editItem(int dayIndex, int itemIndex) {
    final item = _days[dayIndex].items[itemIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(
        item: item,
        onSave: (name, time, notes) {
          setState(() {
            item.name = name;
            item.time = time;
            item.notes = notes;
          });
        },
        onDelete: () {
          _removeItem(dayIndex, itemIndex);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review itinerary'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                    builder: (_) => TripViewScreen(
                      tripId: widget.tripId,
                      tripTitle: widget.tripTitle,
                    )),
            ),
            child: Text(
              'Looks good',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hint bar
          _HintBar(),
          // Itinerary list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.xxl),
              itemCount: _days.length,
              itemBuilder: (context, dayIndex) {
                final day = _days[dayIndex];
                return _DaySection(
                  day: day,
                  dayIndex: dayIndex,
                  onEdit: (itemIndex) => _editItem(dayIndex, itemIndex),
                  onDelete: (itemIndex) => _removeItem(dayIndex, itemIndex),
                  onAdd: () => _addItem(dayIndex),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = day.items.removeAt(oldIndex);
                      day.items.insert(newIndex, item);
                    });
                  },
                );
              },
            ),
          ),
          // AI chat input
          _AiChatBar(
            controller: _chatController,
            onSend: () {
              setState(() {});
              _chatController.clear();
            },
          ),
        ],
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      color: AppColors.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'drag to reorder  ·  swipe left to remove  ·  tap to edit',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.dayIndex,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    required this.onReorder,
  });

  final _ItineraryDay day;
  final int dayIndex;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final VoidCallback onAdd;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Text(
            day.label,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: day.items.length,
          onReorder: onReorder,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: child,
          ),
          itemBuilder: (context, index) {
            final item = day.items[index];
            return _ItineraryRow(
              key: ValueKey(item.id),
              item: item,
              onTap: () => onEdit(index),
              onDismiss: () => onDelete(index),
            );
          },
        ),
        // Add item button
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: GestureDetector(
            onTap: onAdd,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary, width: 1.5),
                    color: Colors.transparent,
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Add item',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ItineraryRow extends StatelessWidget {
  const _ItineraryRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  final _ItineraryItem item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 1),
          child: Row(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                child: ReorderableDragStartListener(
                  index: 0,
                  child: const Icon(
                    Icons.drag_handle_rounded,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
              // Time
              SizedBox(
                width: 44,
                child: Text(
                  item.time,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                          if (item.isAiSuggested)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.badgeUpcoming,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded,
                                      size: 9, color: AppColors.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    'AI',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (item.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.location,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.notes,
                          style: AppTextStyles.caption.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiChatBar extends StatelessWidget {
  const _AiChatBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Ask AI to refine... (e.g. add more food stops)',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.send_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit item bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({
    required this.item,
    required this.onSave,
    required this.onDelete,
  });

  final _ItineraryItem item;
  final void Function(String name, String time, String notes) onSave;
  final VoidCallback onDelete;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _timeCtrl = TextEditingController(text: widget.item.time);
    _notesCtrl = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Edit item', style: AppTextStyles.headlineSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
                label: Text(
                  'Delete',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _timeCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration:
                      const InputDecoration(labelText: 'Start time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notesCtrl,
            style: AppTextStyles.bodyMedium,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Any tips or reminders...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _nameCtrl.text,
                  _timeCtrl.text,
                  _notesCtrl.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
