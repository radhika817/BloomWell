import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/plan_item_status.dart';
import '../../domain/entities/study_plan_item.dart';
import '../../domain/entities/suggested_load.dart';
import 'load_chip.dart';
import 'plan_item_status_badge.dart';

/// Interactive day card in the weekly study plan.
/// Adheres strictly to accessibility rules: semantics label, 48x48 min tap target, 200% text scaling.
class StudyPlanDayCard extends StatelessWidget {
  const StudyPlanDayCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onActivityTap,
  });

  final StudyPlanItem item;
  final VoidCallback onTap;
  final ValueChanged<String>? onActivityTap;

  String _buildSemanticLabel(BuildContext context, AppLocalizations? l10n,
      String weekday, String dateStr) {
    final loadName = item.suggestedLoad == SuggestedLoad.light
        ? (l10n?.studyPlannerLoadLight ?? 'Light')
        : item.suggestedLoad == SuggestedLoad.focus
            ? (l10n?.studyPlannerLoadFocus ?? 'Focus')
            : (l10n?.studyPlannerLoadNormal ?? 'Normal');

    final statusName = item.status == PlanItemStatus.accepted
        ? (l10n?.studyPlannerStatusAccepted ?? 'Accepted')
        : item.status == PlanItemStatus.edited
            ? (l10n?.studyPlannerStatusEdited ?? 'Edited')
            : item.status == PlanItemStatus.skipped
                ? (l10n?.studyPlannerStatusSkipped ?? 'Skipped')
                : (l10n?.studyPlannerStatusSuggested ?? 'Suggested');

    if (item.academicEventTitle != null &&
        item.academicEventTitle!.trim().isNotEmpty) {
      if (l10n != null) {
        return l10n.studyPlannerDaySemantic(
          weekday,
          dateStr,
          loadName,
          item.academicEventTitle!.trim(),
          statusName,
        );
      }
      return '$weekday $dateStr, $loadName day, event: ${item.academicEventTitle}, status: $statusName';
    } else {
      if (l10n != null) {
        return l10n.studyPlannerDaySemanticNoEvent(
          weekday,
          dateStr,
          loadName,
          statusName,
        );
      }
      return '$weekday $dateStr, $loadName day, status: $statusName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekdayFormatter = DateFormat('EEEE');
    final dateFormatter = DateFormat('MMM d');
    final weekdayStr = weekdayFormatter.format(item.planDate);
    final dateStr = dateFormatter.format(item.planDate);

    final semanticLabel =
        _buildSemanticLabel(context, l10n, weekdayStr, dateStr);

    final isSkipped = item.status == PlanItemStatus.skipped;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64.0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          onTap: onTap,
          child: Opacity(
            opacity: isSkipped ? 0.6 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Date block
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weekdayStr,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSkipped
                                  ? AppColors.mutedText
                                  : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Load chip (icon + text)
                    LoadChip(load: item.suggestedLoad),

                    const Spacer(),

                    // Status Badge
                    PlanItemStatusBadge(status: item.status),

                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),

                // Event Badge (if event exists on this day)
                if (item.academicEventTitle != null &&
                    item.academicEventTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: AppColors.deepPurple,
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            item.academicEventTitle!.trim(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Break Activity Row (if suggested)
                if (item.activityId != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: onActivityTap != null
                        ? () => onActivityTap!(item.activityId!)
                        : null,
                    borderRadius: BorderRadius.circular(6.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.self_improvement_rounded,
                            size: 14,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n?.studyPlannerBreakActivity ?? 'Break activity',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
