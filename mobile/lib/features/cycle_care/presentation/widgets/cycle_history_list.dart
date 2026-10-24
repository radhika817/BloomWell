import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cycle_care_notifier.dart';
import '../../domain/entities/cycle_period_entry.dart';
import 'period_logging_dialog.dart';

/// Cursor-paginated history list of recorded menstrual periods.
/// Displays newest entries first with cycle length and duration metrics,
/// and allows editing or deleting recorded cycles.
class CycleHistoryList extends ConsumerWidget {
  const CycleHistoryList({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CyclePeriodEntry period,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cycleActionDeletePeriod),
        content: Text(l10n.cycleDeletePeriodConfirm),
        actions: [
          TextButton(
            key: const Key('cycle_history_delete_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cycleCancelButton),
          ),
          TextButton(
            key: const Key('cycle_history_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.cycleActionDeletePeriod,
              style: const TextStyle(color: Color(0xFFC2415E)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(cycleCareNotifierProvider.notifier)
          .deletePeriod(period.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(cycleCareNotifierProvider);
    final notifier = ref.read(cycleCareNotifierProvider.notifier);

    final cycles = state.historyCycles;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 20,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.cycleHistoryTitle,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (cycles.isNotEmpty)
                Text(
                  '${cycles.length} logged',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Empty state
          if (cycles.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              alignment: Alignment.center,
              child: Text(
                l10n.cycleHistoryEmpty,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            )
          else ...[
            // Period entries list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cycles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                return _CycleHistoryItem(
                  cycle: cycle,
                  l10n: l10n,
                  onEdit: () {
                    PeriodLoggingSheet.show(
                      context,
                      initialDate: DateTime.tryParse(cycle.periodStart),
                      existingEntry: cycle,
                    );
                  },
                  onDelete: () => _confirmDelete(context, ref, cycle, l10n),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Pagination Controls
            if (state.hasMoreHistory)
              if (state.isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                BloomButton(
                  key: const Key('cycle_history_load_more_button'),
                  label: 'Load more cycles',
                  icon: Icons.expand_more_rounded,
                  variant: BloomButtonVariant.subtle,
                  isExpanded: true,
                  onPressed: () => notifier.loadMoreHistory(),
                ),
          ],
        ],
      ),
    );
  }
}

class _CycleHistoryItem extends StatelessWidget {
  final CyclePeriodEntry cycle;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CycleHistoryItem({
    required this.cycle,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = cycle.isOngoing;
    final duration = cycle.durationDays;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dates & Ongoing Badge
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                size: 16,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isOngoing
                      ? 'Started ${cycle.periodStart}'
                      : '${cycle.periodStart} – ${cycle.periodEnd}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (isOngoing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.cycleHistoryOngoing,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Duration and Cycle Length metrics
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (duration != null)
                Text(
                  'Bleeding: ${l10n.cycleHistoryCycleLength(duration)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              if (cycle.cycleLengthDays != null)
                Text(
                  'Cycle: ${l10n.cycleHistoryCycleLength(cycle.cycleLengthDays!)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Edit and Delete Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                key: Key('cycle_history_edit_${cycle.id}'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.cycleHistoryEdit),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton.icon(
                key: Key('cycle_history_delete_${cycle.id}'),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(l10n.cycleHistoryDelete),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC2415E),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
