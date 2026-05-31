import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memories_app/core/demo/demo_flag.dart';
import 'package:memories_app/core/demo/mock_data.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';
import 'package:memories_app/features/trips/presentation/widgets/trip_card.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class CreateTripPage extends ConsumerStatefulWidget {
  const CreateTripPage({super.key});

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage> {
  int _step = 0; // 0 = details, 1 = invite+choice, 2 = generating

  // Step 0 state
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedVibes = {};
  File? _coverImage;
  bool _isCreating = false;

  // Step 1 state
  final List<PublicProfileEntity> _addedUsers = [];

  // Created trip ID (set after step 0 API call)
  String? _createdTripId;

  // Validation errors
  String? _titleError;
  String? _destinationError;
  String? _startDateError;
  String? _endDateError;

  static const _vibes = [
    'Adventure',
    'Relaxed',
    'Foodie',
    'Culture',
    'Budget',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _goToStep(int step) => setState(() => _step = step);

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  bool _validateStep1() {
    String? titleErr = _titleController.text.trim().isEmpty
        ? 'Trip name is required'
        : null;
    String? destErr = _destinationController.text.trim().isEmpty
        ? 'Destination is required'
        : null;
    String? startErr = _startDate == null ? 'Required' : null;
    String? endErr = _endDate == null ? 'Required' : null;

    if (startErr == null && endErr == null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return false;
    }

    setState(() {
      _titleError = titleErr;
      _destinationError = destErr;
      _startDateError = startErr;
      _endDateError = endErr;
    });
    return titleErr == null && destErr == null && startErr == null && endErr == null;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      0 => _Step1Widget(
          titleController: _titleController,
          destinationController: _destinationController,
          startDate: _startDate,
          endDate: _endDate,
          selectedVibes: _selectedVibes,
          vibes: _vibes,
          titleError: _titleError,
          destinationError: _destinationError,
          startDateError: _startDateError,
          endDateError: _endDateError,
          coverImage: _coverImage,
          isCreating: _isCreating,
          onPickCover: _pickCoverImage,
          onStartDateChanged: (d) => setState(() => _startDate = d),
          onEndDateChanged: (d) => setState(() => _endDate = d),
          onVibeToggled: (v) => setState(() {
            if (_selectedVibes.contains(v)) {
              _selectedVibes.remove(v);
            } else {
              _selectedVibes.add(v);
            }
          }),
          onNext: _createTripNow,
        ),
      1 => _Step2Widget(
          addedUsers: _addedUsers,
          onUserAdded: (u) => setState(() => _addedUsers.add(u)),
          onUserRemoved: (u) =>
              setState(() => _addedUsers.removeWhere((x) => x.id == u.id)),
          onBuildAi: () => _buildItinerary(useAi: true),
          onBuildManual: () => _buildItinerary(useAi: false),
        ),
      2 => _Step3GeneratingWidget(
          destination: _destinationController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          tripId: _createdTripId,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // Step 0 CTA — create the trip immediately, then move to invite/itinerary step.
  Future<void> _createTripNow() async {
    if (!_validateStep1()) return;
    setState(() => _isCreating = true);

    // DEMO: skip API, use mock trip
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _createdTripId = mockTripBali.id;
        _isCreating = false;
        _step = 1;
      });
      return;
    }

    try {
      final repo = ref.read(tripsRepositoryProvider);
      final detail = await repo.createTrip(
        title: _titleController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        vibes: _selectedVibes.toList(),
      );
      ref.invalidate(tripsProvider);
      if (!mounted) return;
      setState(() {
        _createdTripId = detail.trip.id;
        _isCreating = false;
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Step 1 CTA — add members and generate (or skip) itinerary.
  Future<void> _buildItinerary({required bool useAi}) async {
    final tripId = _createdTripId;
    if (tripId == null) return;

    setState(() => _step = 2);

    // DEMO: use mock itinerary
    if (kDemoMode && useAi) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      context.pushReplacement(
        '/trips/$tripId/itinerary-review',
        extra: {'items': mockBaliItinerary, 'tripId': tripId, 'aiEnabled': true},
      );
      return;
    }
    if (kDemoMode) {
      if (!mounted) return;
      context.pushReplacement(
        '/trips/$tripId/itinerary-review',
        extra: {'items': <ItineraryItemEntity>[], 'tripId': tripId, 'aiEnabled': false},
      );
      return;
    }

    try {
      final repo = ref.read(tripsRepositoryProvider);

      // Add invited members (non-fatal)
      for (final user in _addedUsers) {
        try {
          await repo.addMember(tripId, user.id);
        } catch (_) {}
      }

      final items =
          useAi ? await repo.generateItinerary(tripId) : <ItineraryItemEntity>[];

      if (!mounted) return;
      context.pushReplacement(
        '/trips/$tripId/itinerary-review',
        extra: {'items': items, 'tripId': tripId, 'aiEnabled': useAi},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _step = 1);
    }
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Trip details
// ---------------------------------------------------------------------------

class _Step1Widget extends StatelessWidget {
  const _Step1Widget({
    required this.titleController,
    required this.destinationController,
    required this.startDate,
    required this.endDate,
    required this.selectedVibes,
    required this.vibes,
    required this.titleError,
    required this.destinationError,
    required this.startDateError,
    required this.endDateError,
    required this.coverImage,
    required this.isCreating,
    required this.onPickCover,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onVibeToggled,
    required this.onNext,
  });

  final TextEditingController titleController;
  final TextEditingController destinationController;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> selectedVibes;
  final List<String> vibes;
  final String? titleError;
  final String? destinationError;
  final String? startDateError;
  final String? endDateError;
  final File? coverImage;
  final bool isCreating;
  final VoidCallback onPickCover;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<String> onVibeToggled;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: const BackButton(),
        title: const Text('New trip'),
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 1, total: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover photo
                  GestureDetector(
                    onTap: onPickCover,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: coverImage != null
                          ? Image.file(coverImage!, fit: BoxFit.cover)
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      size: 22, color: AppColors.textMuted),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Add cover photo',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LabeledField(
                    label: 'Trip name',
                    child: TextFormField(
                      controller: titleController,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Summer escape',
                        errorText: titleError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    label: 'Destination',
                    child: _DestinationField(
                      controller: destinationController,
                      errorText: destinationError,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Start date',
                          child: _DatePickerButton(
                            value: startDate,
                            hint: 'Pick date',
                            firstDate: DateTime.now(),
                            onChanged: onStartDateChanged,
                            errorText: startDateError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LabeledField(
                          label: 'End date',
                          child: _DatePickerButton(
                            value: endDate,
                            hint: 'Pick date',
                            firstDate: startDate ?? DateTime.now(),
                            onChanged: onEndDateChanged,
                            errorText: endDateError,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    label: 'Vibes',
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: vibes
                          .map((v) => _VibePill(
                                label: v,
                                selected: selectedVibes.contains(v),
                                onTap: () => onVibeToggled(v),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: isCreating ? null : onNext,
                    child: isCreating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text("Looks good — let's go"),
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

// ---------------------------------------------------------------------------
// Step 2 — Invite people
// ---------------------------------------------------------------------------

class _Step2Widget extends ConsumerStatefulWidget {
  const _Step2Widget({
    required this.addedUsers,
    required this.onUserAdded,
    required this.onUserRemoved,
    required this.onBuildAi,
    required this.onBuildManual,
  });

  final List<PublicProfileEntity> addedUsers;
  final ValueChanged<PublicProfileEntity> onUserAdded;
  final ValueChanged<PublicProfileEntity> onUserRemoved;
  final VoidCallback onBuildAi;
  final VoidCallback onBuildManual;

  @override
  ConsumerState<_Step2Widget> createState() => _Step2WidgetState();
}

class _Step2WidgetState extends ConsumerState<_Step2Widget> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(userSearchResultsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: const BackButton(),
        title: const Text('Invite people'),
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 2, total: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Search by handle or name...',
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: AppColors.textMuted),
                      prefixIconConstraints:
                          BoxConstraints(minWidth: 40, minHeight: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.addedUsers.isNotEmpty) ...[
                    Text(
                      'Added',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...widget.addedUsers.map(
                      (u) => _UserRow(
                        user: u,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check,
                                size: 14, color: AppColors.accentGreen),
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => widget.onUserRemoved(u),
                              child: const Icon(Icons.close,
                                  size: 14, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_query.isNotEmpty) ...[
                    Text(
                      'Results',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    searchAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(
                            color: AppColors.accentGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (_, __) => Text(
                        'Search failed',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.coral),
                      ),
                      data: (users) {
                        final currentUserId =
                            ref.watch(currentUserIdProvider).valueOrNull;
                        final filtered = users
                            .where((u) =>
                                widget.addedUsers.every((a) => a.id != u.id) &&
                                u.id != currentUserId)
                            .toList();
                        if (filtered.isEmpty) {
                          return Text(
                            'No users found',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          );
                        }
                        return Column(
                          children: filtered
                              .map(
                                (u) => _UserRow(
                                  user: u,
                                  trailing: GestureDetector(
                                    onTap: () => widget.onUserAdded(u),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                        border: Border.all(
                                            color: AppColors.border,
                                            width: 0.5),
                                      ),
                                      child: Text(
                                        'Add',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'How do you want to build it?',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: widget.onBuildAi,
                    child: const Text('✨ Build with AI'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: widget.onBuildManual,
                    child: const Text('Add plans manually'),
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

// ---------------------------------------------------------------------------
// Step 3 — Generating
// ---------------------------------------------------------------------------

class _Step3GeneratingWidget extends StatefulWidget {
  const _Step3GeneratingWidget({
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.tripId,
  });

  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? tripId;

  @override
  State<_Step3GeneratingWidget> createState() => _Step3GeneratingWidgetState();
}

class _Step3GeneratingWidgetState extends State<_Step3GeneratingWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  int _statusIndex = 0;
  Timer? _statusTimer;

  static const _statuses = [
    'Finding hidden gems...',
    'Planning your days...',
    'Adding local tips...',
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0.9).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressController.forward();

    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() =>
            _statusIndex = (_statusIndex + 1) % _statuses.length);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  int get _durationDays {
    if (widget.startDate == null || widget.endDate == null) return 0;
    return widget.endDate!.difference(widget.startDate!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.amberLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '✨',
                      style: AppTextStyles.displaySmall,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Building your ${widget.destination} itinerary',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (_durationDays > 0)
                  Text(
                    '$_durationDays day${_durationDays == 1 ? '' : 's'}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) => _ProgressIndicatorBar(
                    value: _progressAnimation.value,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statuses[_statusIndex],
                    key: ValueKey(_statusIndex),
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressIndicatorBar extends StatelessWidget {
  const _ProgressIndicatorBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i < step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < total - 1 ? AppSpacing.xs : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.text : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Destination field with OSM Nominatim autocomplete
// ---------------------------------------------------------------------------

class _DestinationField extends StatefulWidget {
  const _DestinationField({
    required this.controller,
    this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  State<_DestinationField> createState() => _DestinationFieldState();
}

class _DestinationFieldState extends State<_DestinationField> {
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  OverlayEntry? _overlay;
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  final _dio = Dio();

  @override
  void dispose() {
    _debounce?.cancel();
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      _clearOverlay();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _search(value.trim()),
    );
  }

  Future<void> _search(String query) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': query, 'format': 'json', 'limit': 5},
        options: Options(headers: {'User-Agent': 'MemoriesApp/1.0 bayupabisa@gmail.com'}),
      );
      if (!mounted) return;
      final results = List<Map<String, dynamic>>.from(res.data as List);
      setState(() => _results = results);
      if (results.isNotEmpty) _showOverlay();
    } catch (e, st) {
      // ignore: avoid_print
      debugPrint('[DestinationField] search error: $e\n$st');
    }
  }

  void _showOverlay() {
    _clearOverlay();
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;
    final height = renderBox.size.height;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, height + 2),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: AppColors.white,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final raw = _results[i]['display_name'] as String? ?? '';
                // Show first 3 comma-separated parts for brevity
                final parts = raw.split(',');
                final label = parts.take(3).join(',').trim();
                return InkWell(
                  onTap: () {
                    widget.controller.text = label;
                    _clearOverlay();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            label,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _clearOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _results = []);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        style: AppTextStyles.bodyMedium,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: 'City, country',
          prefixIcon: const Icon(Icons.location_on_outlined,
              size: 16, color: AppColors.textMuted),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          errorText: widget.errorText,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date picker button
// ---------------------------------------------------------------------------

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.firstDate,
    this.errorText,
  });

  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final String? errorText;

  String get _label {
    if (value == null) return hint;
    return '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final effectiveFirst = firstDate ?? DateTime(2020);
            final initialDate =
                (value != null && !value!.isBefore(effectiveFirst))
                    ? value!
                    : effectiveFirst;
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: effectiveFirst,
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.accentGreen,
                      ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: errorText != null ? AppColors.coral : AppColors.border,
                width: errorText != null ? 1.0 : 0.5,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _label,
                style: AppTextStyles.bodyMedium
                    .copyWith(
                        color: value == null
                            ? AppColors.textMuted
                            : AppColors.text)
                    .copyWith(fontSize: 13),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(color: AppColors.coral),
          ),
        ],
      ],
    );
  }
}

class _VibePill extends StatelessWidget {
  const _VibePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: selected
              ? null
              : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.white : AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.trailing});

  final PublicProfileEntity user;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AvatarCircleWidget(label: initial, seed: user.handle, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '@${user.handle}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
