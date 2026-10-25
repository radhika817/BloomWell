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
import '../../../../l10n/app_localizations.dart';
import '../../../app_lock/application/app_lock_notifier.dart';
import '../../application/self_care_notifier.dart';
import '../../domain/entities/activity_entry.dart';
import '../widgets/step_by_step_guide_dialog.dart';

/// Screen displaying the complete details of an activity,
/// mandatory medical disclaimer for comfort category, steps, and practice launcher.
class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String activityId;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
  });

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  ActivityEntry? _activity;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivityDetail();
  }

  Future<void> _loadActivityDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(selfCareRepositoryProvider);
      final entry = await repo.getActivityDetail(widget.activityId);
      if (mounted) {
        setState(() {
          _activity = entry;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;
    if (isLocked) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context);
    final studioState = ref.watch(selfCareNotifierProvider);
    final isFavorite = studioState.favorites.contains(widget.activityId);
    final isFavLoading =
        studioState.favoriteActionInProgress.contains(widget.activityId);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: l10n?.activityStepBack ?? 'Back',
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/self-care');
                        }
                      },
                    ),
                    Text(
                      l10n?.activityDetailTitle ?? 'Activity Details',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Favorite Toggle Heart
                    IconButton(
                      icon: isFavLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryPurple,
                                ),
                              ),
                            )
                          : Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? AppColors.primaryPurple
                                  : AppColors.mutedText,
                            ),
                      onPressed: isFavLoading
                          ? null
                          : () {
                              ref
                                  .read(selfCareNotifierProvider.notifier)
                                  .toggleFavorite(widget.activityId);
                            },
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        ),
                      )
                    : _errorMessage != null
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
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    BloomButton(
                                      label: l10n?.selfCareRetry ?? 'Try again',
                                      onPressed: _loadActivityDetail,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : _activity == null
                            ? const SizedBox.shrink()
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenHorizontal,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Title & Badge Card
                                    GlassCard(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.lg),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              DecorativeBadge(
                                                label: l10n?.selfCareDurationMinutes(
                                                        _activity!
                                                            .durationMinutes) ??
                                                    '${_activity!.durationMinutes} min',
                                                backgroundColor: AppColors.mint
                                                    .withValues(alpha: 0.6),
                                                textColor: AppColors.deepPurple,
                                              ),
                                              const SizedBox(width: 8),
                                              DecorativeBadge(
                                                label: _activity!.category.name,
                                                backgroundColor: AppColors
                                                    .lavender
                                                    .withValues(alpha: 0.6),
                                                textColor: AppColors.deepPurple,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            _activity!.title,
                                            style: AppTypography.titleLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            _activity!.summary,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                              color: AppColors.secondaryText,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Mandatory Non-Diagnostic Clinical/Nurse Notice for Comfort Activities
                                    if (_activity!.isComfortCategory) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      Container(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFFFD8A8),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('🩺',
                                                style: TextStyle(fontSize: 22)),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                l10n?.activityComfortDoctorNote ??
                                                    'If symptoms feel severe, unusual or last a long time, talking to a doctor or nurse can help.',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color:
                                                      const Color(0xFF9A3412),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: AppSpacing.lg),

                                    // Guided Steps List
                                    Text(
                                      l10n?.activityStepsTitle ??
                                          'Guided Steps',
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),

                                    ...List.generate(
                                      _activity!.steps.length,
                                      (index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.sm,
                                          ),
                                          child: GlassCard(
                                            padding: const EdgeInsets.all(
                                              AppSpacing.md,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.lavender,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: AppTypography
                                                        .labelSmall
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.deepPurple,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.sm,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    _activity!.steps[index],
                                                    style: AppTypography
                                                        .bodyMedium
                                                        .copyWith(height: 1.4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: AppSpacing.md),

                                    // Source Attribution
                                    Text(
                                      '${l10n?.activitySourceLabel ?? 'Source'}: ${_activity!.source}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.mutedText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),

                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                ),
                              ),
              ),

              // Bottom Action Button
              if (_activity != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    children: [
                      if (_activity!.isBreathingActivity) ...[
                        BloomButton(
                          label: l10n?.breathingStartButton ??
                              'Start Mindful Breathing',
                          icon: Icons.air_rounded,
                          onPressed: () {
                            context.push('/breathe');
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      BloomButton(
                        label:
                            l10n?.activityStartButton ?? 'Start gentle guide',
                        icon: Icons.play_arrow_rounded,
                        variant: _activity!.isBreathingActivity
                            ? BloomButtonVariant.subtle
                            : BloomButtonVariant.primary,
                        onPressed: () {
                          StepByStepGuideDialog.show(context, _activity!);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
