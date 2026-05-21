import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/demo/demo_flag.dart' show demoModeProvider;
import 'package:memories_app/core/demo/mock_data.dart';
import 'package:memories_app/core/theme/app_theme.dart';
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
  int _step = 0; // 0 = details, 1 = invite, 2 = generating

  // Step 1 state
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedVibes = {};

  // Step 2 state
  final List<PublicProfileEntity> _addedUsers = [];

  // Step 3 state (after creation)
  String? _createdTripId;

  // Validation errors
  String? _titleError;
  String? _destinationError;

  static const _vibes = [
    'adventure',
    'relaxed',
    'foodie',
    'culture',
    'budget',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _goToStep(int step) => setState(() => _step = step);

  bool _validateStep1() {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty
          ? 'trip name is required'
          : null;
      _destinationError = _destinationController.text.trim().isEmpty
          ? 'destination is required'
          : null;
    });
    return _titleError == null && _destinationError == null;
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
          onStartDateChanged: (d) => setState(() => _startDate = d),
          onEndDateChanged: (d) => setState(() => _endDate = d),
          onVibeToggled: (v) => setState(() {
            if (_selectedVibes.contains(v)) {
              _selectedVibes.remove(v);
            } else {
              _selectedVibes.add(v);
            }
          }),
          onNext: () {
            if (_validateStep1()) _goToStep(1);
          },
        ),
      1 => _Step2Widget(
          addedUsers: _addedUsers,
          onUserAdded: (u) => setState(() => _addedUsers.add(u)),
          onUserRemoved: (u) =>
              setState(() => _addedUsers.removeWhere((x) => x.id == u.id)),
          onSkip: _startCreating,
          onNext: _startCreating,
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

  Future<void> _startCreating() async {
    setState(() => _step = 2);

    // DEMO: skip real API — use mock Bali itinerary to simulate AI generation
    if (ref.read(demoModeProvider)) {
      // Simulate the generating animation for a moment
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      final tripId = mockTripBali.id;
      setState(() => _createdTripId = tripId);
      context.pushReplacement(
        '/trips/$tripId/itinerary-review',
        extra: {'items': mockBaliItinerary, 'tripId': tripId},
      );
      return;
    }
    // DEMO: real trip creation below

    try {
      // Create trip
      final repo = ref.read(tripsRepositoryProvider);
      final detail = await repo.createTrip(
        title: _titleController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        vibes: _selectedVibes.toList(),
      );

      final tripId = detail.trip.id;
      setState(() => _createdTripId = tripId);

      // Add members
      for (final user in _addedUsers) {
        try {
          await repo.addMember(tripId, user.id);
        } catch (_) {
          // Non-fatal — continue
        }
      }

      // Generate itinerary
      final items = await repo.generateItinerary(tripId);

      if (!mounted) return;

      // Invalidate trips list cache
      ref.invalidate(tripsProvider);

      context.pushReplacement(
        '/trips/$tripId/itinerary-review',
        extra: {'items': items, 'tripId': tripId},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error: ${e.toString()}')),
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
        title: const Text('new trip'),
      ),
      body: Column(
        children: [
          _ProgressBar(step: 1, total: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover photo placeholder
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grayLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.grayMid,
                        width: 0.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 22, color: AppColors.textHint),
                          SizedBox(height: 4),
                          Text(
                            'add cover photo',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LabeledField(
                    label: 'TRIP NAME',
                    child: TextFormField(
                      controller: titleController,
                      style: AppTextStyles.uiInput(),
                      decoration: InputDecoration(
                        hintText: 'summer escape',
                        errorText: titleError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    label: 'DESTINATION',
                    child: TextFormField(
                      controller: destinationController,
                      style: AppTextStyles.uiInput(),
                      decoration: InputDecoration(
                        hintText: 'city, country',
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textHint),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        errorText: destinationError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'START DATE',
                          child: _DatePickerButton(
                            value: startDate,
                            hint: 'pick date',
                            onChanged: onStartDateChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LabeledField(
                          label: 'END DATE',
                          child: _DatePickerButton(
                            value: endDate,
                            hint: 'pick date',
                            onChanged: onEndDateChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    label: 'VIBES',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vibes
                          .map((v) => _VibePill(
                                label: v,
                                selected: selectedVibes.contains(v),
                                onTap: () => onVibeToggled(v),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: onNext,
                    child: const Text('next — invite people'),
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
    required this.onSkip,
    required this.onNext,
  });

  final List<PublicProfileEntity> addedUsers;
  final ValueChanged<PublicProfileEntity> onUserAdded;
  final ValueChanged<PublicProfileEntity> onUserRemoved;
  final VoidCallback onSkip;
  final VoidCallback onNext;

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
        title: const Text('invite people'),
      ),
      body: Column(
        children: [
          _ProgressBar(step: 2, total: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTextStyles.uiInput(),
                    decoration: const InputDecoration(
                      hintText: 'search by handle or name...',
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: AppColors.textHint),
                      prefixIconConstraints:
                          BoxConstraints(minWidth: 40, minHeight: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.addedUsers.isNotEmpty) ...[
                    Text(
                      'ADDED',
                      style: AppTextStyles.uiLabel(color: AppColors.textMuted)
                          .copyWith(
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.addedUsers.map(
                      (u) => _UserRow(
                        user: u,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check,
                                size: 14, color: AppColors.teal),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => widget.onUserRemoved(u),
                              child: const Icon(Icons.close,
                                  size: 14, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_query.isNotEmpty) ...[
                    Text(
                      'RESULTS',
                      style: AppTextStyles.uiLabel(color: AppColors.textMuted)
                          .copyWith(
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    searchAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: AppColors.teal,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (_, __) => const Text(
                        'search failed',
                        style: TextStyle(
                            color: AppColors.coral, fontSize: 12),
                      ),
                      data: (users) {
                        final filtered = users
                            .where((u) => widget.addedUsers
                                .every((a) => a.id != u.id))
                            .toList();
                        if (filtered.isEmpty) {
                          return const Text(
                            'no users found',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12),
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
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.grayLight,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                        border: Border.all(
                                            color: AppColors.grayMid,
                                            width: 0.5),
                                      ),
                                      child: const Text(
                                        'add',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w500),
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: widget.onNext,
                    child: const Text('next — build itinerary'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: widget.onSkip,
                    child: const Text('skip for now'),
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
    'finding hidden gems...',
    'planning your days...',
    'adding local tips...',
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'building your ${widget.destination} itinerary',
                  style: AppTextStyles.bodyMedium(color: AppColors.text)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (_durationDays > 0)
                  Text(
                    '$_durationDays day${_durationDays == 1 ? '' : 's'}',
                    style:
                        AppTextStyles.bodySmall(color: AppColors.textMuted),
                  ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) => _ProgressIndicatorBar(
                    value: _progressAnimation.value,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statuses[_statusIndex],
                    key: ValueKey(_statusIndex),
                    style: AppTextStyles.uiLabel(color: AppColors.textHint),
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
        color: AppColors.grayLight,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i < step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.text : AppColors.grayMid,
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
          style: AppTextStyles.uiLabel(color: AppColors.textMuted).copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime?> onChanged;

  String get _label {
    if (value == null) return hint;
    return '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.teal,
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
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _label,
            style: AppTextStyles.uiInput(
              color: value == null ? AppColors.textHint : AppColors.text,
            ).copyWith(fontSize: 13),
          ),
        ),
      ),
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
          color: selected ? AppColors.text : AppColors.grayLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: selected
              ? null
              : Border.all(color: AppColors.grayMid, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textMuted,
            fontSize: 12,
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
                  style: AppTextStyles.bodySmall(color: AppColors.text)
                      .copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '@${user.handle}',
                  style: AppTextStyles.uiLabel(color: AppColors.textHint),
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
