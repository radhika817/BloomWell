import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../l10n/app_localizations.dart';
import '../application/cycle_care_notifier.dart';
import 'cycle_care_opt_in_screen.dart';
import 'widgets/cycle_day_sheet.dart';
import 'widgets/cycle_estimate_card.dart';
import 'widgets/cycle_history_list.dart';
import 'widgets/cycle_month_calendar.dart';
import 'widgets/period_logging_dialog.dart';
import 'widgets/symptom_logging_sheet.dart';

/// Main screen for CycleCare:
/// - Handles opt-in state (shows opt-in consent if not enabled)
/// - Shows month calendar grid with accessible list toggle
/// - Displays educational estimate card (with non-diagnostic disclaimer)
/// - Displays paginated cycle history
/// - Provides quick actions to log period and symptoms
/// - Offers settings to disable tracking with keep or permanent deletion options
class CycleCareScreen extends ConsumerStatefulWidget {
  const CycleCareScreen({super.key});

  @override
  ConsumerState<CycleCareScreen> createState() => _CycleCareScreenState();
}

class _CycleCareScreenState extends ConsumerState<CycleCareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(cycleCareNotifierProvider).trackingStatus == null) {
        ref.read(cycleCareNotifierProvider.notifier).loadInitial();
      }
    });
  }

  void _showSettingsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.softCardBorder),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.cycleSettingsTitle,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.cycleTurnOffDialogBody,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Option 1: Turn off and keep data
              BloomButton(
                key: const Key('cycle_settings_keep_data_button'),
                label: l10n.cycleKeepDataOption,
                variant: BloomButtonVariant.secondary,
                isExpanded: true,
                onPressed: () async {
                  Navigator.of(bottomSheetContext).pop();
                  final success = await ref
                      .read(cycleCareNotifierProvider.notifier)
                      .disableTracking(deleteData: false);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.cycleTrackingDisabledFeedback),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              // Option 2: Turn off and permanently delete data
              BloomButton(
                key: const Key('cycle_settings_delete_data_button'),
                label: l10n.cycleDeleteDataOption,
                variant: BloomButtonVariant.subtle,
                isExpanded: true,
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: bottomSheetContext,
                    builder: (dialogCtx) => AlertDialog(
                      title: Text(l10n.cycleDeleteConfirmTitle),
                      content: Text(l10n.cycleDeleteConfirmBody),
                      actions: [
                        TextButton(
                          key: const Key('cycle_settings_cancel_delete_button'),
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          child: Text(l10n.cycleCancelButton),
                        ),
                        TextButton(
                          key: const Key('cycle_confirm_delete_button'),
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          child: Text(
                            l10n.cycleConfirmDeleteButton,
                            style: const TextStyle(color: Color(0xFFC2415E)),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    if (bottomSheetContext.mounted) {
                      Navigator.of(bottomSheetContext).pop();
                    }
                    final success = await ref
                        .read(cycleCareNotifierProvider.notifier)
                        .disableTracking(deleteData: true);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.cycleTrackingDeletedFeedback),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDaySheet(BuildContext context, DateTime date) {
    ref.read(cycleCareNotifierProvider.notifier).selectDate(date);
    CycleDaySheet.show(
      context,
      date: date,
      onLogSymptom: () {
        SymptomLoggingSheet.show(context, initialDate: date);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleCareNotifierProvider);
    final notifier = ref.read(cycleCareNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    if (state.trackingStatus == null && state.isLoading) {
      return const Scaffold(
        body: BloomBackground(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (!state.isTrackingEnabled) {
      return CycleCareOptInScreen(
        onNotNow: () => context.go('/'),
      );
    }

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar: Title, Subtitle & Settings Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cycleCareTitle,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.cycleCareSubtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('cycle_care_settings_button'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primaryText,
                        size: 24,
                      ),
                      tooltip: l10n.cycleSettingsTitle,
                      onPressed: () => _showSettingsSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Error Banner if present
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2415E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC2415E).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFC2415E),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFFC2415E),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          color: const Color(0xFFC2415E),
                          onPressed: () => notifier.loadInitial(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: BloomButton(
                        key: const Key('cycle_quick_log_period_button'),
                        label: l10n.cycleActionLogPeriod,
                        icon: Icons.water_drop,
                        variant: BloomButtonVariant.primary,
                        height: 44,
                        onPressed: () {
                          PeriodLoggingSheet.show(
                            context,
                            initialDate: DateTime.now(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: BloomButton(
                        key: const Key('cycle_quick_log_symptom_button'),
                        label: l10n.cycleActionLogSymptom,
                        icon: Icons.add_circle_outline,
                        variant: BloomButtonVariant.secondary,
                        height: 44,
                        onPressed: () {
                          SymptomLoggingSheet.show(
                            context,
                            initialDate: DateTime.now(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Month Calendar (Grid / Accessible List)
                CycleMonthCalendar(
                  selectedMonth: state.selectedMonth,
                  selectedDate: state.selectedDate,
                  viewMode: state.calendarViewMode,
                  monthCycles: state.monthCycles,
                  monthSymptoms: state.monthSymptoms,
                  estimate: state.estimate,
                  onDaySelected: (date) => _openDaySheet(context, date),
                  onPreviousMonth: () {
                    notifier.changeMonth(
                      DateTime(
                        state.selectedMonth.year,
                        state.selectedMonth.month - 1,
                        1,
                      ),
                    );
                  },
                  onNextMonth: () {
                    notifier.changeMonth(
                      DateTime(
                        state.selectedMonth.year,
                        state.selectedMonth.month + 1,
                        1,
                      ),
                    );
                  },
                  onToggleViewMode: () => notifier.toggleViewMode(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Educational Cycle Estimate Observation Card
                CycleEstimateCard(estimate: state.estimate),
                const SizedBox(height: AppSpacing.lg),

                // Recorded Cycle History with cursor pagination
                const CycleHistoryList(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
