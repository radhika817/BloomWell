import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_background.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import '../../self_care/domain/entities/activity_suggestion.dart';
import '../application/comfort_notifier.dart';
import '../domain/entities/comfort_need.dart';
import 'widgets/comfort_plan_list.dart';

/// Low-stimulation Comfort Mode screen.
/// Offers peaceful, non-judgmental comfort suggestions by need and personal comfort plan.
class ComfortScreen extends ConsumerStatefulWidget {
  const ComfortScreen({super.key});

  @override
  ConsumerState<ComfortScreen> createState() => _ComfortScreenState();
}

class _ComfortScreenState extends ConsumerState<ComfortScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(comfortNotifierProvider.notifier).loadInitial();
    });
  }

  String _needLabel(ComfortNeed need, AppLocalizations? l10n) {
    switch (need) {
      case ComfortNeed.calmDown:
        return l10n?.comfortNeedCalmDown ?? 'Calm down';
      case ComfortNeed.quickBreak:
        return l10n?.comfortNeedQuickBreak ?? 'A quick break';
      case ComfortNeed.bodyComfort:
        return l10n?.comfortNeedBodyComfort ?? 'Body comfort';
      case ComfortNeed.focus:
        return l10n?.comfortNeedFocus ?? 'Focus';
    }
  }

  String _reasonLabel(ActivitySuggestion suggestion, AppLocalizations? l10n) {
    switch (suggestion.reason) {
      case ActivitySuggestionReason.favorite:
        return l10n?.comfortReasonFavorite ?? 'One of your favorites';
      case ActivitySuggestionReason.newForYou:
        return l10n?.comfortReasonNewForYou ?? 'Something new to try';
      case ActivitySuggestionReason.quick:
        return l10n?.comfortReasonQuick ?? 'Gentle and quick';
      case ActivitySuggestionReason.other:
        return l10n?.comfortReasonOther ?? 'Suggested for you';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;
    if (isLocked) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context);
    final comfortState = ref.watch(comfortNotifierProvider);
    final notifier = ref.read(comfortNotifierProvider.notifier);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
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
                                l10n?.comfortModeTitle ?? 'A gentle moment',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n?.comfortModeSubtitle ??
                                    'No pressure. Pick what feels okay right now.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Need Selection Question & Chips
                    Text(
                      l10n?.comfortNeedQuestion ?? 'What do you need?',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ComfortNeed.values.map((need) {
                          final isSelected = comfortState.selectedNeed == need;
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: PillChip(
                              label: _needLabel(need, l10n),
                              isSelected: isSelected,
                              onTap: () => notifier.selectNeed(need),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Suggestions for Current Need
                    if (comfortState.isLoadingSuggestions)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      )
                    else if (comfortState.suggestions.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            const Text('🌱', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n?.comfortShowSomethingElse ??
                                  'No suggestions found for this duration.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            BloomButton(
                              label: l10n?.comfortShowSomethingElse ??
                                  'Show me something else',
                              variant: BloomButtonVariant.subtle,
                              onPressed: () => notifier.showSomethingElse(),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      ...comfortState.suggestions.map((suggestion) {
                        final act = suggestion.activity;
                        final isAlreadyInPlan = comfortState.comfortPlan.any(
                            (p) => (p.activity?.id ?? p.activityId) == act.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: GlassCard(
                            onTap: () {
                              context.push('/self-care/activity/${act.id}');
                            },
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    DecorativeBadge(
                                      label: _reasonLabel(suggestion, l10n),
                                      backgroundColor:
                                          AppColors.mint.withValues(alpha: 0.7),
                                      textColor: AppColors.deepPurple,
                                    ),
                                    const Spacer(),
                                    DecorativeBadge(
                                      label: l10n?.selfCareDurationMinutes(
                                              act.durationMinutes) ??
                                          '${act.durationMinutes} min',
                                      backgroundColor: AppColors.lavender
                                          .withValues(alpha: 0.6),
                                      textColor: AppColors.deepPurple,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  act.title,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  act.summary,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondaryText,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isAlreadyInPlan)
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.bookmark_add_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          l10n?.comfortAddToPlan ??
                                              'Add to comfort plan',
                                          style: AppTypography.labelSmall,
                                        ),
                                        onPressed: () {
                                          notifier.addToPlan(act.id);
                                        },
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Text(
                                          '✓ Saved in plan',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: AppColors.primaryPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            l10n?.comfortShowSomethingElse ??
                                'Show me something else',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => notifier.showSomethingElse(),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Comfort Plan Section
                    const ComfortPlanList(),

                    const SizedBox(height: AppSpacing.xl),

                    // Find Support & Non-Medical Notice
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_outline_rounded,
                                  color: AppColors.deepPurple, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n?.comfortFindSupport ?? 'Find support',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n?.comfortNonMedicalNotice ??
                                'BloomWell is not a medical or emergency service. If you are going through a difficult time, reaching out to a trusted person or health professional can help.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BloomButton(
                            label: l10n?.comfortFindSupport ?? 'Find support',
                            icon: Icons.support_agent_rounded,
                            variant: BloomButtonVariant.subtle,
                            onPressed: () => context.push('/help'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
