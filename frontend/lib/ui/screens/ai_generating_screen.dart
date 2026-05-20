import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'ai_itinerary_review_screen.dart';

class AiGeneratingScreen extends StatefulWidget {
  const AiGeneratingScreen({super.key});

  @override
  State<AiGeneratingScreen> createState() => _AiGeneratingScreenState();
}

class _AiGeneratingScreenState extends State<AiGeneratingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final AnimationController _progressController;
  late final Animation<double> _sparkleRotation;

  int _statusIndex = 0;
  static const _statuses = [
    'Thinking about your trip...',
    'Finding gems in Seminyak...',
    'Checking local favourites...',
    'Mapping out your days...',
    'Adding a few surprises...',
    'Almost ready!',
  ];

  @override
  void initState() {
    super.initState();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _sparkleRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();

    // Cycle status texts
    _cycleStatus();

    // Navigate when done
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const AiItineraryReviewScreen()),
        );
      }
    });
  }

  void _cycleStatus() async {
    for (int i = 0; i < _statuses.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _statusIndex = i);
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated sparkle icon
              RotationTransition(
                turns: _sparkleRotation,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Building your itinerary',
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Animated status text
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: Text(
                  _statuses[_statusIndex],
                  key: ValueKey(_statusIndex),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Progress bar
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${(_progressController.value * 100).round()}%',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              // Bottom hint
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'You can edit, reorder, and refine every suggestion after generation',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
