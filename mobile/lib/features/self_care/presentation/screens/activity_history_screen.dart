import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_background.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/activity_history_notifier.dart';

/// Screen displaying a peaceful, newest-first record of completed self-care activities.
/// Strictly excludes counts, streaks, charts, or totals.
class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() =>
      _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activityHistoryNotifierProvider.notifier).loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(activityHistoryNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final historyState = ref.watch(activityHistoryNotifierProvider);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: l10n?.activityStepBack ?? 'Back',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.activityHistoryTitle ?? 'My Activity History',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n?.activityHistorySubtitle ??
                                'A quiet record of your gentle moments.',
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

              // Content Area
              Expanded(
                child: historyState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        ),
                      )
                    : historyState.errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: GlassCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🌧️',
                                        style: TextStyle(fontSize: 32)),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      historyState.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    BloomButton(
                                      label: l10n?.selfCareRetry ?? 'Try again',
                                      onPressed: () => ref
                                          .read(activityHistoryNotifierProvider
                                              .notifier)
                                          .loadInitial(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : historyState.history.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: GlassCard(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.xl),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🌸',
                                            style: TextStyle(fontSize: 40)),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          l10n?.activityHistoryEmpty ??
                                              'No completed activities yet. Take your time.',
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
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
                                  vertical: AppSpacing.md,
                                ),
                                itemCount: historyState.history.length +
                                    (historyState.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= historyState.history.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(AppSpacing.md),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  final log = historyState.history[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: GlassCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.mint
                                                  .withValues(alpha: 0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 20,
                                              color: AppColors.deepPurple,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  log.activityTitle,
                                                  style: AppTypography
                                                      .titleSmall
                                                      .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatDate(log.completedAt),
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                    color: AppColors.mutedText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (log.helpfulnessRating !=
                                              null) ...[
                                            DecorativeBadge(
                                              label:
                                                  '★ ${log.helpfulnessRating}',
                                              backgroundColor:
                                                  AppColors.lavender,
                                              textColor: AppColors.deepPurple,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
