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
import '../../domain/entities/cycle_symptom_entry.dart';
import 'period_logging_dialog.dart';

/// Helper to get localized symptom type name.
String getLocalizedSymptomName(CycleSymptomType type, AppLocalizations l10n) {
  switch (type) {
    case CycleSymptomType.cramps:
      return l10n.cycleSymptomCramps;
    case CycleSymptomType.bloating:
      return l10n.cycleSymptomBloating;
    case CycleSymptomType.fatigue:
      return l10n.cycleSymptomFatigue;
    case CycleSymptomType.headache:
      return l10n.cycleSymptomHeadache;
    case CycleSymptomType.backPain:
      return l10n.cycleSymptomBackPain;
    case CycleSymptomType.breastTenderness:
      return l10n.cycleSymptomBreastTenderness;
    case CycleSymptomType.nausea:
      return l10n.cycleSymptomNausea;
    case CycleSymptomType.moodChanges:
      return l10n.cycleSymptomMoodChanges;
    case CycleSymptomType.acne:
      return l10n.cycleSymptomAcne;
    case CycleSymptomType.cravings:
      return l10n.cycleSymptomCravings;
    case CycleSymptomType.sleepTrouble:
      return l10n.cycleSymptomSleepTrouble;
    case CycleSymptomType.other:
      return l10n.cycleSymptomOther;
  }
}

/// Bottom sheet presenting details, logged period, and symptoms for a selected calendar day.
/// Includes quick actions ("Period started today", "Period ended today"), period editing/deleting,
/// and opens the symptom logging flow.
class CycleDaySheet extends ConsumerWidget {
  final DateTime date;
  final VoidCallback onLogSymptom;

  const CycleDaySheet({
    super.key,
    required this.date,
    required this.onLogSymptom,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required VoidCallback onLogSymptom,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CycleDaySheet(
        date: date,
        onLogSymptom: onLogSymptom,
      ),
    );
  }

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  CyclePeriodEntry? _getPeriodForDay(
    List<CyclePeriodEntry> periods,
    DateTime target,
  ) {
    final normTarget = DateTime(target.year, target.month, target.day);
    for (final period in periods) {
      final start = DateTime.tryParse(period.periodStart);
      if (start == null) continue;
      final normStart = DateTime(start.year, start.month, start.day);

      DateTime normEnd;
      if (period.periodEnd != null) {
        final end = DateTime.tryParse(period.periodEnd!);
        if (end == null) continue;
        normEnd = DateTime(end.year, end.month, end.day);
      } else {
        final now = DateTime.now();
        normEnd = DateTime(now.year, now.month, now.day);
      }

      if (!normTarget.isBefore(normStart) && !normTarget.isAfter(normEnd)) {
        return period;
      }
    }
    return null;
  }

  CyclePeriodEntry? _getOngoingPeriod(List<CyclePeriodEntry> periods) {
    for (final period in periods) {
      if (period.isOngoing) return period;
    }
    return null;
  }

  Future<void> _confirmDeletePeriod(
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
            key: const Key('cycle_delete_period_cancel_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cycleCancelButton),
          ),
          TextButton(
            key: const Key('cycle_delete_period_confirm_button'),
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

    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final dayPeriod = _getPeriodForDay(state.monthCycles, date);
    final ongoingPeriod = _getOngoingPeriod(state.monthCycles);

    final dateStr = _formatDate(date);
    final symptoms =
        state.monthSymptoms.where((s) => s.date == dateStr).toList();

    final dateHeading =
        '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header with close button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.cycleDaySheetTitle,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateHeading,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('cycle_day_sheet_close_button'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quick Action Buttons (Period started today / Period ended today)
                  if (isToday) ...[
                    if (dayPeriod == null && ongoingPeriod == null)
                      BloomButton(
                        key: const Key('cycle_quick_started_today_button'),
                        label: l10n.cycleQuickStartedToday,
                        icon: Icons.play_arrow_rounded,
                        variant: BloomButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () async {
                          await notifier.logPeriod(
                            clientId: generateCycleClientId(),
                            startDate: date,
                          );
                        },
                      ),
                    if (ongoingPeriod != null) ...[
                      BloomButton(
                        key: const Key('cycle_quick_ended_today_button'),
                        label: l10n.cycleQuickEndedToday,
                        icon: Icons.check_circle_outline_rounded,
                        variant: BloomButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () async {
                          await notifier.updatePeriod(
                            id: ongoingPeriod.id,
                            startDate:
                                DateTime.tryParse(ongoingPeriod.periodStart),
                            endDate: date,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Period Status Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: dayPeriod != null
                          ? AppColors.blushPink.withValues(alpha: 0.6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dayPeriod != null
                            ? AppColors.softRose.withValues(alpha: 0.8)
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: dayPeriod != null
                                  ? AppColors.primaryPurple
                                  : AppColors.mutedText,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              dayPeriod != null
                                  ? l10n.cycleDayPeriodLogged
                                  : 'No period logged',
                              style: AppTypography.titleSmall.copyWith(
                                color: dayPeriod != null
                                    ? AppColors.primaryText
                                    : AppColors.mutedText,
                              ),
                            ),
                            const Spacer(),
                            if (dayPeriod != null) ...[
                              IconButton(
                                key: const Key('cycle_day_edit_period_button'),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: AppColors.primaryPurple,
                                tooltip: l10n.cycleActionEditPeriod,
                                onPressed: () {
                                  PeriodLoggingSheet.show(
                                    context,
                                    initialDate: date,
                                    existingEntry: dayPeriod,
                                  );
                                },
                              ),
                              IconButton(
                                key:
                                    const Key('cycle_day_delete_period_button'),
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                color: const Color(0xFFC2415E),
                                tooltip: l10n.cycleActionDeletePeriod,
                                onPressed: () => _confirmDeletePeriod(
                                  context,
                                  ref,
                                  dayPeriod,
                                  l10n,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (dayPeriod != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            dayPeriod.isOngoing
                                ? 'Started ${dayPeriod.periodStart} · ${l10n.cycleHistoryOngoing}'
                                : '${dayPeriod.periodStart} to ${dayPeriod.periodEnd} (${l10n.cycleHistoryCycleLength(dayPeriod.durationDays ?? 1)})',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.sm),
                          BloomButton(
                            key: const Key('cycle_day_log_period_button'),
                            label: l10n.cycleActionLogPeriod,
                            icon: Icons.add_rounded,
                            variant: BloomButtonVariant.subtle,
                            isExpanded: true,
                            onPressed: () {
                              PeriodLoggingSheet.show(
                                context,
                                initialDate: date,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Symptoms Section Header & Log Symptom Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.cycleLegendSymptoms,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.deepPurple,
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('cycle_day_log_symptom_button'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.cycleActionLogSymptom),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                        ),
                        onPressed: onLogSymptom,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Logged symptoms list
                  if (symptoms.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.cycleDayNoLogs,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    )
                  else
                    ...symptoms.map(
                      (symptom) => _SymptomListItem(
                        symptom: symptom,
                        l10n: l10n,
                        onDelete: () async {
                          await notifier.deleteSymptom(symptom.id);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SymptomListItem extends StatelessWidget {
  final CycleSymptomEntry symptom;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  const _SymptomListItem({
    required this.symptom,
    required this.l10n,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = symptom.customLabel != null && symptom.customLabel!.isNotEmpty
        ? symptom.customLabel!
        : getLocalizedSymptomName(symptom.symptomType, l10n);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.circle,
              size: 8,
              color: AppColors.deepPurple,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Severity ${symptom.severity}/5'
                  '${symptom.notes != null && symptom.notes!.isNotEmpty ? " · ${symptom.notes}" : ""}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('cycle_delete_symptom_${symptom.id}'),
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.mutedText,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
