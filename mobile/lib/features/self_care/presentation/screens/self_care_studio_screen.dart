import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_background.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../app_lock/application/app_lock_notifier.dart';
import '../../application/self_care_notifier.dart';
import '../widgets/activity_card.dart';
import '../widgets/category_filter_chips.dart';

/// The Self-Care Studio screen with real API category and duration filtering,
/// server-confirmed favorites, infinite scroll, and quick access to routines and history.
class SelfCareStudioScreen extends ConsumerStatefulWidget {
  const SelfCareStudioScreen({super.key});

  @override
  ConsumerState<SelfCareStudioScreen> createState() =>
      _SelfCareStudioScreenState();
}

class _SelfCareStudioScreenState extends ConsumerState<SelfCareStudioScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selfCareNotifierProvider.notifier).loadActivities();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(selfCareNotifierProvider.notifier).loadMoreActivities();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;
    if (isLocked) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context);
    final studioState = ref.watch(selfCareNotifierProvider);
    final notifier = ref.read(selfCareNotifierProvider.notifier);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // Studio Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xs,
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
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.selfCareStudioTitle ?? 'Self-Care Studio',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n?.selfCareStudioSubtitle ??
                                    'Curated gentle practices for body, mind, and study breaks.',
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

                  // Quick Access Action Bar (Routines & Activity History)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: BloomButton(
                            label: l10n?.selfCareRoutinesButton ?? 'Routines',
                            icon: Icons.repeat_rounded,
                            variant: BloomButtonVariant.subtle,
                            onPressed: () =>
                                context.push('/self-care/routines'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: BloomButton(
                            label: l10n?.selfCareHistoryButton ??
                                'My activity history',
                            icon: Icons.history_rounded,
                            variant: BloomButtonVariant.subtle,
                            onPressed: () => context.push('/self-care/history'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Category & Duration Filter Chips
                  CategoryFilterChips(
                    selectedCategory: studioState.selectedCategory,
                    selectedMaxDuration: studioState.maxDuration,
                    onCategoryChanged: (cat) => notifier.setCategoryFilter(cat),
                    onDurationChanged: (dur) => notifier.setDurationFilter(dur),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Main Activities List / States
                  Expanded(
                    child: studioState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple,
                              ),
                            ),
                          )
                        : studioState.errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: GlassCard(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🌧️',
                                            style: TextStyle(fontSize: 32)),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          studioState.errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        BloomButton(
                                          label: l10n?.selfCareRetry ??
                                              'Try again',
                                          onPressed: () =>
                                              notifier.loadActivities(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : studioState.activities.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.xl),
                                      child: GlassCard(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.xl),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🍃',
                                                style: TextStyle(fontSize: 40)),
                                            const SizedBox(
                                                height: AppSpacing.md),
                                            Text(
                                              l10n?.selfCareEmptyTitle ??
                                                  'No activities match this filter',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                            Text(
                                              l10n?.selfCareEmptySubtitle ??
                                                  'Try choosing a different category or longer duration.',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.screenHorizontal,
                                      vertical: AppSpacing.sm,
                                    ),
                                    itemCount: studioState.activities.length +
                                        (studioState.isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >=
                                          studioState.activities.length) {
                                        return const Center(
                                          child: Padding(
                                            padding:
                                                EdgeInsets.all(AppSpacing.md),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }

                                      final activity =
                                          studioState.activities[index];
                                      final isFav = studioState.favorites
                                          .contains(activity.id);
                                      final isFavLoading = studioState
                                          .favoriteActionInProgress
                                          .contains(activity.id);

                                      return ActivityCard(
                                        activity: activity,
                                        isFavorite: isFav,
                                        isFavoriteLoading: isFavLoading,
                                        onTap: () {
                                          context.push(
                                              '/self-care/activity/${activity.id}');
                                        },
                                        onFavoriteToggle: () {
                                          notifier.toggleFavorite(activity.id);
                                        },
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
}
