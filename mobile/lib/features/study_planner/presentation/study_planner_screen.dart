import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/decorative_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_lock/application/app_lock_notifier.dart';
import '../application/study_planner_notifier.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_mode.dart';
import '../domain/planner_date_utils.dart';
import 'widgets/study_plan_day_card.dart';
import 'widgets/study_plan_day_sheet.dart';

/// Main Study Planner screen displaying the weekly schedule, honest personalization banner,
/// accessible 7-day cards, and week navigation.
class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlannerNotifierProvider.notifier).loadPlan();
    });
  }

  void _showConflictDialog(BuildContext context, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.studyPlannerReplaceDialogTitle ?? 'Replace Plan',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.studyPlannerPlanExistsMessage ??
              'A plan already exists for this week. Would you like to replace it?',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              l10n?.activityStepBack ?? 'Cancel',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          BloomButton(
            label: l10n?.studyPlannerReplaceConfirm ?? 'Replace plan',
            height: 38.0,
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(studyPlannerNotifierProvider.notifier)
                  .generatePlan(replace: true);
            },
          ),
        ],
      ),
    );
  }

  void _showCycleTrackingRequiredDialog(
      BuildContext context, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.cycleCareTitle ?? 'CycleCare',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.studyPlannerCycleTrackingRequired ??
              'Cycle tracking is needed to use cycle records in study planning. You can turn on CycleCare anytime.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              l10n?.activityStepBack ?? 'Not now',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          BloomButton(
            label: l10n?.studyPlannerOpenCycleCare ?? 'Open CycleCare',
            height: 38.0,
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push('/cycle-care');
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, AppLocalizations? l10n, String planId) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.studyPlannerDeleteDialogTitle ?? 'Delete Plan',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.studyPlannerDeleteDialogBody ??
              'Are you sure you want to delete this week\'s plan? You can create a new one anytime.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              l10n?.activityStepBack ?? 'Cancel',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(studyPlannerNotifierProvider.notifier)
                  .deletePlan(planId);
            },
            child: Text(
              l10n?.studyPlannerDeleteConfirm ?? 'Delete plan',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;

    // Privacy boundary: if app is locked, render nothing
    if (isLocked) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(studyPlannerNotifierProvider);
    final notifier = ref.read(studyPlannerNotifierProvider.notifier);

    // Conflict listener hooks
    if (state.conflictPlanExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConflictDialog(context, l10n);
      });
    }

    if (state.cycleTrackingRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCycleTrackingRequiredDialog(context, l10n);
      });
    }

    final startFormatter = DateFormat('MMM d');
    final endFormatter = DateFormat('MMM d, yyyy');
    final weekStartStr = startFormatter.format(state.selectedWeekStart);
    final weekEnd = state.selectedWeekStart.add(const Duration(days: 6));
    final weekEndStr = endFormatter.format(weekEnd);
    final weekRangeTitle = '$weekStartStr – $weekEndStr';

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Screen App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: l10n?.activityStepBack ?? 'Back',
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.studyPlannerTitle ?? 'Study Planner',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n?.studyPlannerSubtitle ??
                                'Gentle, balanced study rhythms',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: 'Planner options',
                      onSelected: (val) {
                        switch (val) {
                          case 'replace':
                            if (state.currentPlan != null) {
                              _showConflictDialog(context, l10n);
                            } else {
                              notifier.generatePlan();
                            }
                            break;
                          case 'delete':
                            if (state.currentPlan != null) {
                              _showDeleteDialog(
                                  context, l10n, state.currentPlan!.id);
                            }
                            break;
                          case 'settings':
                            context.push('/study-planner/settings');
                            break;
                          case 'insights':
                            context.push('/insights');
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (state.hasPlan) ...[
                          PopupMenuItem(
                            value: 'replace',
                            child: Row(
                              children: [
                                const Icon(Icons.refresh_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n?.studyPlannerMenuReplace ??
                                    'Replace this week\'s plan'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  l10n?.studyPlannerMenuDelete ??
                                      'Delete this plan',
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.settings_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n?.studyPlannerMenuSettings ??
                                  'Planner settings'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'insights',
                          child: Row(
                            children: [
                              const Icon(Icons.insights_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n?.insightsTitle ??
                                  'Personal Observations'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Week Selector Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.xs,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Previous week',
                        onPressed: () {
                          final prev = state.selectedWeekStart
                              .subtract(const Duration(days: 7));
                          notifier.loadPlan(weekStart: prev);
                        },
                      ),
                      Expanded(
                        child: Text(
                          weekRangeTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Next week',
                        onPressed: () {
                          final next = state.selectedWeekStart
                              .add(const Duration(days: 7));
                          notifier.loadPlan(weekStart: next);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Body Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state.errorMessage != null && !state.hasPlan) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.errorMessage!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              BloomButton(
                                label: 'Retry',
                                icon: Icons.refresh_rounded,
                                onPressed: () =>
                                    notifier.loadPlan(refresh: true),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!state.hasPlan) {
                      return _buildEmptyState(context, l10n, notifier, state);
                    }

                    return _buildPlanView(
                        context, l10n, state.currentPlan!, notifier);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations? l10n,
    StudyPlannerNotifier notifier,
    StudyPlannerState state,
  ) {
    final nowMonday = PlannerDateUtils.getMondayOfWeek(DateTime.now());
    final isCurrentWeek = state.selectedWeekStart.isAtSameMomentAs(nowMonday);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('📚', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n?.studyPlannerTitle ?? 'Study Planner',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n?.studyPlannerIntroText ??
                'Suggestions based only on what you tell us. You can change any of it.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n?.studyPlannerNoCycleNote ??
                  'The planner works fully without period data using your check-ins alone.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryText,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          BloomButton(
            label: isCurrentWeek
                ? (l10n?.studyPlannerMakeMyWeek ?? 'Make my week')
                : 'Create plan for this week',
            icon: Icons.calendar_today_rounded,
            onPressed: state.isActionLoading
                ? null
                : () =>
                    notifier.generatePlan(weekStart: state.selectedWeekStart),
          ),
          if (isCurrentWeek) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: state.isActionLoading
                  ? null
                  : () {
                      final nextMonday = nowMonday.add(const Duration(days: 7));
                      notifier.loadPlan(weekStart: nextMonday);
                    },
              child: Text(
                l10n?.studyPlannerNextWeek ?? 'Plan next week',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.deepPurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanView(
    BuildContext context,
    AppLocalizations? l10n,
    StudyPlan plan,
    StudyPlannerNotifier notifier,
  ) {
    final isDefault = plan.mode == StudyPlanMode.defaultMode;
    final bannerText = isDefault
        ? (l10n?.studyPlannerDefaultBanner(
                plan.personalization.checkinDaysUsed) ??
            'This week\'s plan is a simple starting point. Personalized suggestions appear after about 14 days of check-ins.')
        : (l10n?.studyPlannerPersonalizedBanner(
                plan.personalization.checkinDaysUsed) ??
            'Based on ${plan.personalization.checkinDaysUsed} days of your check-ins.');

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      children: [
        // Personalization Banner
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isDefault
                        ? Icons.info_outline_rounded
                        : Icons.auto_awesome_rounded,
                    size: 20,
                    color: isDefault
                        ? AppColors.secondaryText
                        : AppColors.deepPurple,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryText,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (plan.usesCycleData) ...[
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => context.push('/study-planner/settings'),
                  borderRadius: BorderRadius.circular(12.0),
                  child: DecorativeBadge(
                    label: l10n?.studyPlannerUsesPeriodLogs ??
                        'Uses your period logs',
                    backgroundColor: AppColors.lavender.withValues(alpha: 0.6),
                    textColor: AppColors.deepPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 7-Day Cards
        for (final item in plan.items) ...[
          StudyPlanDayCard(
            item: item,
            onTap: () => StudyPlanDaySheet.show(context, item),
            onActivityTap: (activityId) =>
                context.push('/self-care/activity/$activityId'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
