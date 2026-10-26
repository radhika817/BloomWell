import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_lock/application/app_lock_notifier.dart';
import '../application/insights_notifier.dart';
import '../domain/entities/exam_context_insights.dart';
import '../domain/entities/weekly_insights.dart';

/// Personal Observations screen presenting non-diagnostic observations from check-ins and exams.
/// Contains zero scores, zero percentages, zero rankings, and zero causal claims.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(insightsNotifierProvider.notifier).loadAllInsights();
    });
  }

  String _mapWeeklyObservation(
      String metric, String code, AppLocalizations l10n) {
    final c = code.trim().toUpperCase();
    switch (metric.toLowerCase()) {
      case 'mood':
        if (c == 'HIGHER_THAN_USUAL') return l10n.insightsMoodHigher;
        if (c == 'LOWER_THAN_USUAL') return l10n.insightsMoodLower;
        return l10n.insightsMoodSimilar;
      case 'stress':
        if (c == 'HIGHER_THAN_USUAL') return l10n.insightsStressHigher;
        if (c == 'LOWER_THAN_USUAL') return l10n.insightsStressLower;
        return l10n.insightsStressSimilar;
      case 'energy':
        if (c == 'HIGHER_THAN_USUAL') return l10n.insightsEnergyHigher;
        if (c == 'LOWER_THAN_USUAL') return l10n.insightsEnergyLower;
        return l10n.insightsEnergySimilar;
      case 'sleep':
        if (c == 'HIGHER_THAN_USUAL') return l10n.insightsSleepHigher;
        if (c == 'LOWER_THAN_USUAL') return l10n.insightsSleepLower;
        return l10n.insightsSleepSimilar;
      default:
        return 'Observation for $metric.';
    }
  }

  String _mapExamStress(String code, AppLocalizations l10n) {
    final c = code.trim().toUpperCase();
    if (c == 'STRESS_HIGHER_BEFORE_EVENTS') {
      return l10n.insightsExamStressHigher;
    }
    if (c == 'STRESS_LOWER_BEFORE_EVENTS') {
      return l10n.insightsExamStressLower;
    }
    return l10n.insightsExamStressSimilar;
  }

  String _mapExamEnergy(String code, AppLocalizations l10n) {
    final c = code.trim().toUpperCase();
    if (c == 'ENERGY_HIGHER_BEFORE_EVENTS') {
      return l10n.insightsExamEnergyHigher;
    }
    if (c == 'ENERGY_LOWER_BEFORE_EVENTS') {
      return l10n.insightsExamEnergyLower;
    }
    return l10n.insightsExamEnergySimilar;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;

    if (isLocked) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(insightsNotifierProvider);
    final notifier = ref.read(insightsNotifierProvider.notifier);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                children: [
                  // App Bar
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
                                l10n?.insightsTitle ?? 'Personal Observations',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n?.insightsSubtitle ??
                                    'Gentle patterns based on what you share',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.errorMessage != null &&
                            state.weeklyInsights == null &&
                            state.examInsights == null) {
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
                                        notifier.loadAllInsights(refresh: true),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Disclaimer Card
                              GlassCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: AppColors.deepPurple,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        l10n?.insightsDisclaimer ??
                                            'This is an observation, not a cause.',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Section 1: Weekly Observations
                              Text(
                                l10n?.insightsWeeklyHeading ??
                                    'This Week\'s Observations',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildWeeklySection(
                                  context, l10n, state.weeklyInsights),
                              const SizedBox(height: AppSpacing.xl),

                              // Section 2: Exam Context Observations
                              Text(
                                l10n?.insightsExamHeading ??
                                    'Before Academic Events',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildExamSection(
                                  context, l10n, state.examInsights),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        );
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

  Widget _buildWeeklySection(
    BuildContext context,
    AppLocalizations? l10n,
    WeeklyInsights? weekly,
  ) {
    if (weekly == null || !weekly.hasSufficientData) {
      final neededWeek = weekly?.daysNeeded?.week ?? 1;
      final neededBaseline = weekly?.daysNeeded?.baseline ?? 0;
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 20,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.insightsWeeklyNotEnoughData(neededWeek, neededBaseline) ??
                    'We need check-ins on at least $neededWeek more days this week and $neededBaseline more baseline days to share weekly observations.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final metrics = weekly.metrics ?? {};
    final sampleSizes = weekly.sampleSizes;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final metricKey in ['stress', 'energy', 'mood', 'sleep']) ...[
            if (metrics.containsKey(metricKey)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _mapWeeklyObservation(
                          metricKey,
                          metrics[metricKey]!.code,
                          l10n ?? AppLocalizations.of(context)!,
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (sampleSizes != null) ...[
            const Divider(height: 24),
            Text(
              l10n?.insightsWeeklySampleSizes(
                    sampleSizes.weekDistinctDays,
                    sampleSizes.baselineDistinctDays,
                  ) ??
                  'Based on ${sampleSizes.weekDistinctDays} check-in days this week and ${sampleSizes.baselineDistinctDays} baseline days.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamSection(
    BuildContext context,
    AppLocalizations? l10n,
    ExamContextInsights? exam,
  ) {
    if (exam == null || !exam.hasSufficientData) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 20,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.insightsExamNotEnoughData ??
                    'We need at least 2 events with 3 check-in days each in their preparation window to share exam observations.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final localizations = l10n ?? AppLocalizations.of(context)!;
    final sampleSizes = exam.sampleSizes;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exam.stress != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mapExamStress(exam.stress!.code, localizations),
                      style: AppTypography.bodyMedium.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (exam.energy != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mapExamEnergy(exam.energy!.code, localizations),
                      style: AppTypography.bodyMedium.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (sampleSizes != null) ...[
            const Divider(height: 24),
            Text(
              localizations.insightsExamSampleSizes(
                sampleSizes.qualifyingEvents,
                sampleSizes.preEventDistinctDays,
                sampleSizes.baselineDistinctDays,
              ),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
