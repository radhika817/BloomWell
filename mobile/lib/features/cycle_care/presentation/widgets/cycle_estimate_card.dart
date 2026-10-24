import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/cycle_estimate.dart';

/// Card presenting educational cycle observations and estimates.
/// Supports 3 server states:
/// 1. not_enough_data: prompts to log more cycles without diagnostic language
/// 2. too_variable: neutral note that cycle lengths vary naturally
/// 3. estimate: educational approximate date range with typical cycle metrics
///
/// Strictly non-diagnostic: displays prominent disclaimer that estimates can be wrong
/// and never constitutes clinical advice.
class CycleEstimateCard extends StatelessWidget {
  final CycleEstimate? estimate;

  const CycleEstimateCard({
    super.key,
    required this.estimate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & "Estimate" Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_graph_rounded,
                      size: 20,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.cycleEstimateTitle,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  l10n.cycleEstimateBadge,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Status-specific content
          _buildStatusContent(context, l10n),
          const SizedBox(height: AppSpacing.md),

          // Non-diagnostic Educational Disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.blushPink.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softRose.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.deepPurple,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.cycleEstimateDisclaimer,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      height: 1.35,
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

  Widget _buildStatusContent(BuildContext context, AppLocalizations l10n) {
    if (estimate == null ||
        estimate!.status == CycleEstimateStatus.notEnoughData) {
      final needed = estimate?.neededCycles ?? 3;
      return Text(
        l10n.cycleEstimateNotEnoughData(needed),
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryText,
          height: 1.4,
        ),
      );
    }

    if (estimate!.status == CycleEstimateStatus.tooVariable) {
      return Text(
        l10n.cycleEstimateTooVariable,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryText,
          height: 1.4,
        ),
      );
    }

    // Status is estimate
    final rangeStart = estimate!.estimatedRangeStart ?? '';
    final rangeEnd = estimate!.estimatedRangeEnd ?? '';
    final typicalDays = estimate!.typicalCycleLengthDays ?? 28;
    final count = estimate!.cyclesCounted ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.cycleEstimateRange(rangeStart, rangeEnd),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.cycleEstimateDetails(typicalDays, count),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
