import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/activity_history_notifier.dart';
import '../../application/self_care_notifier.dart';
import '../../domain/entities/activity_entry.dart';

/// Modal dialog providing a peaceful, self-paced step-by-step guide
/// without timer pressure, followed by an optional 1-5 rating and server-confirmed completion.
class StepByStepGuideDialog extends ConsumerStatefulWidget {
  final ActivityEntry activity;

  const StepByStepGuideDialog({
    super.key,
    required this.activity,
  });

  static Future<void> show(BuildContext context, ActivityEntry activity) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StepByStepGuideDialog(activity: activity),
    );
  }

  @override
  ConsumerState<StepByStepGuideDialog> createState() =>
      _StepByStepGuideDialogState();
}

class _StepByStepGuideDialogState extends ConsumerState<StepByStepGuideDialog> {
  int _currentStepIndex = 0;
  bool _isRatingPhase = false;
  int? _selectedRating;
  bool _isSubmitting = false;
  String? _submissionError;
  bool _isCompletedSuccessfully = false;
  late final String _completionClientId;

  @override
  void initState() {
    super.initState();
    _completionClientId = generateUuidV4();
  }

  Future<void> _recordCompletion({int? rating}) async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final repo = ref.read(selfCareRepositoryProvider);
      await repo.completeActivity(
        clientId: _completionClientId,
        activityId: widget.activity.id,
        helpfulnessRating: rating,
      );

      // Refresh activity history in memory
      ref.read(activityHistoryNotifierProvider.notifier).loadInitial();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isCompletedSuccessfully = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = widget.activity.steps.isNotEmpty
        ? widget.activity.steps
        : [widget.activity.summary];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _isCompletedSuccessfully
              ? _buildSuccessView(context, l10n)
              : _isRatingPhase
                  ? _buildRatingView(context, l10n)
                  : _buildStepsView(context, l10n, steps),
        ),
      ),
    );
  }

  Widget _buildStepsView(
    BuildContext context,
    AppLocalizations? l10n,
    List<String> steps,
  ) {
    final totalSteps = steps.length;
    final isLastStep = _currentStepIndex == totalSteps - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top bar with step counter and close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.activityStepCounter(_currentStepIndex + 1, totalSteps) ??
                  'Step ${_currentStepIndex + 1} of $totalSteps',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Progress bar indicator
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStepIndex + 1) / totalSteps,
            minHeight: 6,
            backgroundColor: AppColors.lavender.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryPurple,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Current Step Text Card (gentle, unhurried)
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_currentStepIndex + 1}',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.deepPurple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    steps[_currentStepIndex],
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 18,
                      height: 1.6,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Action Navigation Row (Back / Next / Done)
        Row(
          children: [
            if (_currentStepIndex > 0)
              Expanded(
                child: BloomButton(
                  label: l10n?.activityStepBack ?? 'Back',
                  variant: BloomButtonVariant.subtle,
                  onPressed: () {
                    setState(() {
                      _currentStepIndex--;
                    });
                  },
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: BloomButton(
                label: isLastStep
                    ? (l10n?.activityStepDone ?? 'Done')
                    : (l10n?.activityStepNext ?? 'Next'),
                onPressed: () {
                  if (isLastStep) {
                    setState(() {
                      _isRatingPhase = true;
                    });
                  } else {
                    setState(() {
                      _currentStepIndex++;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingView(BuildContext context, AppLocalizations? l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Center(
          child: Text('🌸', style: TextStyle(fontSize: 42)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n?.activityRatingTitle ?? 'Did this help?',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.activityRatingSubtitle ??
              'Optional feedback to help suggest gentler activities for you.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Rating Stars (1 to 5)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected =
                _selectedRating != null && starNumber <= _selectedRating!;
            return IconButton(
              iconSize: 36,
              icon: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isSelected ? Colors.amber : AppColors.mutedText,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedRating = starNumber;
                      });
                    },
            );
          }),
        ),

        if (_submissionError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _submissionError!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall
                .copyWith(color: const Color(0xFFD32F2F)),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        if (_isSubmitting)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryPurple,
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: BloomButton(
                  label: l10n?.activityRatingSkip ?? 'Skip',
                  variant: BloomButtonVariant.subtle,
                  onPressed: () => _recordCompletion(rating: null),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: BloomButton(
                  label: l10n?.activityStepDone ?? 'Done',
                  onPressed: () => _recordCompletion(rating: _selectedRating),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, AppLocalizations? l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        const Center(
          child: Text('🌿', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n?.activitySavedConfirmed ??
              'Activity completed and logged gently.',
          textAlign: TextAlign.center,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BloomButton(
          label: l10n?.activityStepDone ?? 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
