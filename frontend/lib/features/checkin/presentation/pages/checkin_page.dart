import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memories_app/core/demo/demo_flag.dart' show demoModeProvider;
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

// ---------------------------------------------------------------------------
// Page entry point
// ---------------------------------------------------------------------------

class CheckinPage extends ConsumerStatefulWidget {
  const CheckinPage({
    super.key,
    required this.tripId,
    this.itemId,
    this.kind,
    this.checkinId,
  });

  /// Trip ID — always required.
  final String tripId;

  /// Itinerary item ID — optional (null for spontaneous).
  final String? itemId;

  /// Kind: "planned" | "spontaneous". Used in create mode.
  final String? kind;

  /// If non-null we are in edit/view mode for an existing check-in.
  final String? checkinId;

  bool get isCreateMode => checkinId == null;

  @override
  ConsumerState<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends ConsumerState<CheckinPage> {
  // Tab
  int _activeTab = 0; // 0 = memory, 1 = logistics, 2 = rec

  // Media
  final List<XFile> _selectedImages = [];
  int _activeImageIndex = 0;
  final _picker = ImagePicker();

  // Time
  DateTime _capturedAt = DateTime.now();

  // Memory
  final _memoryNoteController = TextEditingController();
  String? _selectedMood; // 'love' | 'neutral' | 'sad'

  // Logistics
  final _logisticsCostController = TextEditingController();
  final _logisticsCurrencyController =
      TextEditingController(text: 'USD');
  final _logisticsNotesController = TextEditingController();

  // Recommendation
  final _recTitleController = TextEditingController();
  final _recBodyController = TextEditingController();
  final _recTagsController = TextEditingController();
  int _recRating = 0;

  bool _isSaving = false;

  @override
  void dispose() {
    _memoryNoteController.dispose();
    _logisticsCostController.dispose();
    _logisticsCurrencyController.dispose();
    _logisticsNotesController.dispose();
    _recTitleController.dispose();
    _recBodyController.dispose();
    _recTagsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itineraryItemsProvider(widget.tripId));

    ItineraryItemEntity? item;
    if (widget.itemId != null) {
      item = itemsAsync.maybeWhen(
        data: (items) {
          try {
            return items.firstWhere((i) => i.id == widget.itemId);
          } catch (_) {
            return null;
          }
        },
        orElse: () => null,
      );
    }

    final isSpont =
        widget.kind == 'spontaneous' || widget.itemId == null;
    final pageTitle =
        isSpont ? 'spontaneous moment' : (item?.title ?? 'check in');
    final subtitle = item != null
        ? 'day ${item.day}${item.locationName != null ? ' · ${item.locationName}' : ''}'
        : _formatDate(_capturedAt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaSection(),
                  const SizedBox(height: 12),
                  _buildMemoryNote(),
                  const Divider(height: 1, thickness: 0.5),
                  _buildTimeRow(),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  _buildTabSelector(),
                  const SizedBox(height: 4),
                  const Divider(height: 1, thickness: 0.5),
                  _buildTabContent(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Media section
  // ---------------------------------------------------------------------------

  Widget _buildMediaSection() {
    return Column(
      children: [
        // Full-width preview
        Container(
          height: 130,
          width: double.infinity,
          color: AppColors.grayLight,
          child: _selectedImages.isEmpty
              ? const Center(
                  child: Text(
                    '🖼',
                    style: TextStyle(fontSize: 36),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_selectedImages[_activeImageIndex].path),
                      fit: BoxFit.cover,
                    ),
                    if (_selectedImages.length > 1)
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _selectedImages.length,
                            (i) => Container(
                              width: 5,
                              height: 5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _activeImageIndex
                                    ? AppColors.white
                                    : AppColors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),

        // Thumbnail strip
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            itemCount: _selectedImages.length + 1, // +1 for add slot
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                final isActive = index == _activeImageIndex;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _activeImageIndex = index),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: isActive
                          ? Border.all(
                              color: AppColors.text, width: 2)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md - 1),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }
              // Add slot
              return GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.grayMid,
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.add,
                      size: 18, color: AppColors.textMuted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showImagePickerSheet() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.grayMid,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.text),
              title: const Text('choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final images = await _picker.pickMultiImage();
                if (images.isNotEmpty) {
                  setState(() {
                    _selectedImages.addAll(images);
                    _activeImageIndex = _selectedImages.length - 1;
                  });
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.text),
              title: const Text('take a photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _selectedImages.add(image);
                    _activeImageIndex = _selectedImages.length - 1;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Memory note
  // ---------------------------------------------------------------------------

  Widget _buildMemoryNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _memoryNoteController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: "what's the moment?",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.text,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Time row
  // ---------------------------------------------------------------------------

  Widget _buildTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.access_time_outlined,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'when did this happen?',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.grayMid, width: 0.5),
              ),
              child: Text(
                _formatTime(_capturedAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_capturedAt),
    );
    if (picked != null) {
      setState(() {
        _capturedAt = DateTime(
          _capturedAt.year,
          _capturedAt.month,
          _capturedAt.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Tab selector
  // ---------------------------------------------------------------------------

  Widget _buildTabSelector() {
    const labels = ['memory', 'logistics', 'rec.'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = _activeTab == i;
        return GestureDetector(
          onTap: () => setState(() => _activeTab = i),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color:
                        isActive ? AppColors.text : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 2,
                  width: labels[i].length * 6.5,
                  color: isActive
                      ? AppColors.text
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab content
  // ---------------------------------------------------------------------------

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildMemoryTab();
      case 1:
        return _buildLogisticsTab();
      case 2:
        return _buildRecTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMemoryTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visibility
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grayLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.group_outlined,
                    size: 14, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'visible to trip collaborators',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Vibe row
          const Text(
            'vibe',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _VibeButton(
                emoji: '😍',
                value: 'love',
                selected: _selectedMood == 'love',
                onTap: () => setState(() {
                  _selectedMood =
                      _selectedMood == 'love' ? null : 'love';
                }),
              ),
              const SizedBox(width: 16),
              _VibeButton(
                emoji: '😐',
                value: 'neutral',
                selected: _selectedMood == 'neutral',
                onTap: () => setState(() {
                  _selectedMood =
                      _selectedMood == 'neutral' ? null : 'neutral';
                }),
              ),
              const SizedBox(width: 16),
              _VibeButton(
                emoji: '😕',
                value: 'sad',
                selected: _selectedMood == 'sad',
                onTap: () => setState(() {
                  _selectedMood =
                      _selectedMood == 'sad' ? null : 'sad';
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Private header
          Row(
            children: const [
              Icon(Icons.lock_outline, size: 14, color: AppColors.coral),
              SizedBox(width: 6),
              Text(
                'private — never published or shared with AI',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.coral,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cost + currency row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _logisticsCostController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'cost',
                    prefixIcon: Icon(Icons.attach_money,
                        size: 16, color: AppColors.textMuted),
                    prefixIconConstraints:
                        BoxConstraints(minWidth: 32, minHeight: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _logisticsCurrencyController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'USD',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _logisticsNotesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'notes (e.g. entrance fee, transport…)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _recTitleController,
            decoration: const InputDecoration(
              hintText: 'what would you recommend?',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recBodyController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'tips for others...',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recTagsController,
            decoration: const InputDecoration(
              hintText: 'tags (comma-separated)',
              prefixIcon:
                  Icon(Icons.tag, size: 16, color: AppColors.textMuted),
              prefixIconConstraints:
                  BoxConstraints(minWidth: 32, minHeight: 0),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'rating',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final starNum = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _recRating = starNum),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    starNum <= _recRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: starNum <= _recRating
                        ? AppColors.amber
                        : AppColors.grayMid,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save button
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  widget.isCreateMode ? 'check in' : 'save changes',
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save logic
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    // DEMO: show success snackbar and pop without hitting the API
    if (ref.read(demoModeProvider)) {
      setState(() => _isSaving = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in saved (demo mode)'),
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    // DEMO: real save logic below
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(checkinRepositoryProvider);

      String checkinId;

      if (widget.isCreateMode) {
        // 1. Create the check-in record
        final checkin = await repo.createCheckin(
          tripId: widget.tripId,
          kind: widget.kind ?? 'planned',
          capturedAt: _capturedAt,
          itineraryItemId: widget.itemId,
        );
        checkinId = checkin.id;
      } else {
        checkinId = widget.checkinId!;
      }

      // 2. Upload media
      for (final xFile in _selectedImages) {
        final bytes = await xFile.readAsBytes();
        final mime = _mimeFromPath(xFile.path);

        final uploadInfo = await repo.getMediaUploadUrl(mime);
        final mediaId = uploadInfo['media_id']!;
        final uploadUrl = uploadInfo['upload_url']!;

        await repo.uploadMediaToR2(uploadUrl, bytes, mime);
        await repo.attachMedia(mediaId, checkinId: checkinId);
      }

      // 3. Update memory layer (if note or mood present)
      final hasMemory = _memoryNoteController.text.isNotEmpty ||
          _selectedMood != null;
      if (hasMemory) {
        await repo.updateMemory(
          checkinId,
          note: _memoryNoteController.text.isEmpty
              ? null
              : _memoryNoteController.text,
          mood: _selectedMood,
        );
      }

      // 4. Update logistics layer (if cost or notes present)
      final costText = _logisticsCostController.text.trim();
      final logisticsNotes = _logisticsNotesController.text.trim();
      final hasLogistics = costText.isNotEmpty || logisticsNotes.isNotEmpty;
      if (hasLogistics) {
        await repo.updateLogistics(
          checkinId,
          cost: costText.isNotEmpty ? double.tryParse(costText) : null,
          currency: _logisticsCurrencyController.text.trim().isEmpty
              ? null
              : _logisticsCurrencyController.text.trim(),
          notes: logisticsNotes.isEmpty ? null : logisticsNotes,
        );
      }

      // 5. Update recommendation layer (if title or body present)
      final recTitle = _recTitleController.text.trim();
      final recBody = _recBodyController.text.trim();
      final hasRec = recTitle.isNotEmpty || recBody.isNotEmpty;
      if (hasRec) {
        final tagsRaw = _recTagsController.text.trim();
        final tags = tagsRaw.isEmpty
            ? <String>[]
            : tagsRaw
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
        await repo.updateRecommendation(
          checkinId,
          title: recTitle.isEmpty ? null : recTitle,
          body: recBody.isEmpty ? null : recBody,
          tags: tags.isEmpty ? null : tags,
          rating: _recRating > 0 ? _recRating : null,
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed to save: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Vibe button widget
// ---------------------------------------------------------------------------

class _VibeButton extends StatelessWidget {
  const _VibeButton({
    required this.emoji,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: selected ? 1.0 : 0.3,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}
