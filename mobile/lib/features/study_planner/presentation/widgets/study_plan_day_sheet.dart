import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/study_planner_notifier.dart';
import '../../domain/entities/plan_item_status.dart';
import '../../domain/entities/study_plan_item.dart';
import '../../domain/entities/suggested_load.dart';
import 'load_chip.dart';
import 'reason_code_formatter.dart';

/// Modal bottom sheet displaying "Why this suggestion?" and actions (Accept, Change, Skip).
/// All load options are always permitted during Change. Actions only confirm after server response.
class StudyPlanDaySheet extends ConsumerStatefulWidget {
  const StudyPlanDaySheet({
    super.key,
    required this.item,
  });

  final StudyPlanItem item;

  static Future<void> show(BuildContext context, StudyPlanItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudyPlanDaySheet(item: item),
    );
  }

  @override
  ConsumerState<StudyPlanDaySheet> createState() => _StudyPlanDaySheetState();
}

class _StudyPlanDaySheetState extends ConsumerState<StudyPlanDaySheet> {
  bool _isChangingLoad = false;
  SuggestedLoad? _selectedLoad;

  Future<void> _handleAccept() async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(studyPlannerNotifierProvider.notifier);
    final result = await notifier.patchItem(
      itemId: widget.item.id,
      status: PlanItemStatus.accepted,
    );

    if (mounted && result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.studyPlannerDayAccepted ?? 'Day accepted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSkip() async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(studyPlannerNotifierProvider.notifier);
    final result = await notifier.patchItem(
      itemId: widget.item.id,
      status: PlanItemStatus.skipped,
    );

    if (mounted && result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.studyPlannerDaySkipped ?? 'Day skipped'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleConfirmChange(SuggestedLoad newLoad) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(studyPlannerNotifierProvider.notifier);
    final result = await notifier.patchItem(
      itemId: widget.item.id,
      status: PlanItemStatus.edited,
      suggestedLoad: newLoad,
    );

    if (mounted && result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.studyPlannerDayUpdated ?? 'Day updated'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActionLoading =
        ref.watch(studyPlannerNotifierProvider).isActionLoading;

    final dateFormatter = DateFormat('EEEE, MMMM d');
    final formattedDate = dateFormatter.format(widget.item.planDate);

    final reasons = ReasonCodeFormatter.formatReasonCodes(
      widget.item.reasonCodes,
      l10n ?? AppLocalizations.of(context)!,
      eventTitle: widget.item.academicEventTitle,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date and Header
          Text(
            formattedDate,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            l10n?.studyPlannerSheetTitle ?? 'Why this suggestion?',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Current Load
          Row(
            children: [
              Text(
                l10n?.studyPlannerSuggestedLoadLabel(
                      widget.item.suggestedLoad.name,
                    ) ??
                    'Suggested load: ',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              LoadChip(load: widget.item.suggestedLoad),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Reasons List
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final reason in reasons) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16.0,
                          color: AppColors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          reason,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reason != reasons.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Load Changing Selector View
          if (_isChangingLoad) ...[
            Text(
              l10n?.studyPlannerChangeDialogPrompt ??
                  'Choose any pace that fits your day:',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final load in SuggestedLoad.values) ...[
                  LoadChip(
                    load: load,
                    isSelected: _selectedLoad == load ||
                        (_selectedLoad == null &&
                            widget.item.suggestedLoad == load),
                    onTap: isActionLoading
                        ? null
                        : () {
                            setState(() => _selectedLoad = load);
                            _handleConfirmChange(load);
                          },
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: isActionLoading
                    ? null
                    : () => setState(() => _isChangingLoad = false),
                child: Text(
                  l10n?.activityStepBack ?? 'Cancel',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ),
            ),
          ] else ...[
            // Main Action Buttons
            Row(
              children: [
                Expanded(
                  child: BloomButton(
                    label: l10n?.studyPlannerAcceptButton ?? 'Accept',
                    icon: Icons.check_rounded,
                    onPressed: isActionLoading ? null : _handleAccept,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    onPressed: isActionLoading
                        ? null
                        : () => setState(() => _isChangingLoad = true),
                    child: Text(
                      l10n?.studyPlannerChangeButton ?? 'Change',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(120.0, 48.0),
                ),
                onPressed: isActionLoading ? null : _handleSkip,
                child: Text(
                  l10n?.studyPlannerSkipButton ?? 'Skip',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
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
