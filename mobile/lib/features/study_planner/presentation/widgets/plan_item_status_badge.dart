import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/plan_item_status.dart';

/// Small status badge for day plan item state (Suggested, Accepted, Edited, Skipped).
class PlanItemStatusBadge extends StatelessWidget {
  const PlanItemStatusBadge({
    super.key,
    required this.status,
  });

  final PlanItemStatus status;

  String _label(AppLocalizations l10n) {
    switch (status) {
      case PlanItemStatus.suggested:
        return l10n.studyPlannerStatusSuggested;
      case PlanItemStatus.accepted:
        return l10n.studyPlannerStatusAccepted;
      case PlanItemStatus.edited:
        return l10n.studyPlannerStatusEdited;
      case PlanItemStatus.skipped:
        return l10n.studyPlannerStatusSkipped;
    }
  }

  Color get _color {
    switch (status) {
      case PlanItemStatus.accepted:
        return const Color(0xFF2E7D32);
      case PlanItemStatus.edited:
        return AppColors.deepPurple;
      case PlanItemStatus.skipped:
        return AppColors.mutedText;
      case PlanItemStatus.suggested:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n != null ? _label(l10n) : status.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
