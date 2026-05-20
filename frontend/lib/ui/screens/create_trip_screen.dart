import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import '../widgets/vibe_chip.dart';
import 'ai_generating_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  int _step = 0; // 0, 1, 2

  // Step 1 fields
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedVibes = {};

  // Step 2 fields
  final _inviteController = TextEditingController();
  final List<String> _invited = [];

  bool get _step1Valid =>
      _nameController.text.isNotEmpty &&
      _destinationController.text.isNotEmpty &&
      _startDate != null &&
      _endDate != null;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AiGeneratingScreen()),
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
        title: Text(
          ['Trip details', 'Invite people', 'Review'][_step],
        ),
        actions: [
          if (_step == 1)
            TextButton(
              onPressed: _next,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _step, totalSteps: 3),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              child: switch (_step) {
                0 => _Step1(
                    key: const ValueKey(0),
                    nameController: _nameController,
                    destinationController: _destinationController,
                    startDate: _startDate,
                    endDate: _endDate,
                    selectedVibes: _selectedVibes,
                    onPickStart: () => _pickDate(isStart: true),
                    onPickEnd: () => _pickDate(isStart: false),
                    onVibeToggle: (v) => setState(
                        () => _selectedVibes.contains(v)
                            ? _selectedVibes.remove(v)
                            : _selectedVibes.add(v)),
                  ),
                1 => _Step2(
                    key: const ValueKey(1),
                    inviteController: _inviteController,
                    invited: _invited,
                    onAdd: (name) => setState(() => _invited.add(name)),
                    onRemove: (name) => setState(() => _invited.remove(name)),
                  ),
                _ => _Step3(
                    key: const ValueKey(2),
                    tripName: _nameController.text.isNotEmpty
                        ? _nameController.text
                        : 'My trip',
                    destination: _destinationController.text.isNotEmpty
                        ? _destinationController.text
                        : 'Destination',
                    startDate: _startDate,
                    endDate: _endDate,
                    vibes: _selectedVibes.toList(),
                    collaborators: _invited,
                  ),
              },
            ),
          ),
          _BottomBar(
            step: _step,
            canProceed: _step == 0 ? _step1Valid : true,
            onNext: _next,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final done = index < currentStep;
          final active = index == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    height: 3,
                    decoration: BoxDecoration(
                      color: done || active
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < totalSteps - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Trip details
// ─────────────────────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({
    super.key,
    required this.nameController,
    required this.destinationController,
    required this.startDate,
    required this.endDate,
    required this.selectedVibes,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onVibeToggle,
  });

  final TextEditingController nameController;
  final TextEditingController destinationController;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> selectedVibes;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onVibeToggle;

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about your trip',
              style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Give it a name and set your dates',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Trip name
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Trip name  (e.g. Bali with the crew)',
              prefixIcon: Icon(Icons.edit_outlined, size: 18,
                  color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Destination
          TextField(
            controller: destinationController,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Destination',
              prefixIcon: Icon(Icons.search_rounded, size: 18,
                  color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Dates
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start date',
                  value: _fmtDate(startDate),
                  onTap: onPickStart,
                  hasValue: startDate != null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DateField(
                  label: 'End date',
                  value: _fmtDate(endDate),
                  onTap: onPickEnd,
                  hasValue: endDate != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cover photo upload
          _CoverPhotoUpload(),
          const SizedBox(height: AppSpacing.lg),

          // Vibe tags
          Text('Trip vibe', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text('Pick what fits (optional)', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: VibeOptions.all.map((v) {
              return VibeChip(
                emoji: v.emoji,
                label: v.label,
                selected: selectedVibes.contains(v.label),
                onTap: () => onVibeToggle(v.label),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.hasValue,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool hasValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasValue ? AppColors.primary : AppColors.border,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: hasValue ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPhotoUpload extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text('Add cover photo', style: AppTextStyles.labelMedium),
            const SizedBox(height: 2),
            Text('Optional — you can add later',
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Invite collaborators
// ─────────────────────────────────────────────────────────────────────────────

const _suggestedContacts = [
  ('A', 'Ayu Rahma', '@ayurahma'),
  ('C', 'Citra Dewi', '@citdewi'),
  ('E', 'Eko Santoso', '@ekosan'),
  ('F', 'Farah Nadia', '@farahnadia'),
];

class _Step2 extends StatelessWidget {
  const _Step2({
    super.key,
    required this.inviteController,
    required this.invited,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController inviteController;
  final List<String> invited;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who\'s coming?', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text('Search by name or @handle',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),

          // Search
          TextField(
            controller: inviteController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Search or enter @handle',
              prefixIcon: Icon(Icons.person_search_outlined,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Added list
          if (invited.isNotEmpty) ...[
            Text('Added', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            ...invited.map((name) => _InviteRow(
                  label: name[0].toUpperCase(),
                  name: name,
                  handle: '@${name.toLowerCase().replaceAll(' ', '')}',
                  isAdded: true,
                  onToggle: () => onRemove(name),
                )),
            const SizedBox(height: AppSpacing.md),
          ],

          // Suggested
          Text('Suggested', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          ..._suggestedContacts.map((c) => _InviteRow(
                label: c.$1,
                name: c.$2,
                handle: c.$3,
                isAdded: invited.contains(c.$2),
                onToggle: () => invited.contains(c.$2)
                    ? onRemove(c.$2)
                    : onAdd(c.$2),
              )),
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({
    required this.label,
    required this.name,
    required this.handle,
    required this.isAdded,
    required this.onToggle,
  });

  final String label;
  final String name;
  final String handle;
  final bool isAdded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                Text(handle, style: AppTextStyles.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAdded
                    ? AppColors.accentGreen
                    : AppColors.surface,
                border: Border.all(
                  color: isAdded ? AppColors.accentGreen : AppColors.border,
                ),
              ),
              child: Icon(
                isAdded ? Icons.check_rounded : Icons.add_rounded,
                size: 16,
                color: isAdded ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Review
// ─────────────────────────────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  const _Step3({
    super.key,
    required this.tripName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.vibes,
    required this.collaborators,
  });

  final String tripName;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> vibes;
  final List<String> collaborators;

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Looks good?', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text('Review before we generate your itinerary',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),

          // Cover placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Center(
              child: Icon(
                Icons.photo_camera_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Details card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _ReviewRow(label: 'Trip name', value: tripName),
                const Divider(height: AppSpacing.lg),
                _ReviewRow(label: 'Destination', value: destination),
                const Divider(height: AppSpacing.lg),
                _ReviewRow(
                  label: 'Dates',
                  value:
                      '${_fmtDate(startDate)} → ${_fmtDate(endDate)}',
                ),
                if (vibes.isNotEmpty) ...[
                  const Divider(height: AppSpacing.lg),
                  _ReviewRow(label: 'Vibes', value: vibes.join(', ')),
                ],
                if (collaborators.isNotEmpty) ...[
                  const Divider(height: AppSpacing.lg),
                  _ReviewRow(
                    label: 'People',
                    value: collaborators.join(', '),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // AI notice
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.badgeUpcoming,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'We\'ll generate a day-by-day itinerary you can edit',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.canProceed,
    required this.onNext,
  });

  final int step;
  final bool canProceed;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: ElevatedButton(
        onPressed: canProceed ? onNext : null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
        ),
        child: Text(
          step == 2 ? 'Generate itinerary' : 'Continue',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
