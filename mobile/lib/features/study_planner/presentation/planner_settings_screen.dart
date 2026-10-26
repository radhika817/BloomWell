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
import '../../cycle_care/application/cycle_care_notifier.dart';
import '../application/planner_consent_notifier.dart';
import '../application/study_planner_notifier.dart';

/// Study Planner Settings screen managing optional period log access with full consent transparency.
class PlannerSettingsScreen extends ConsumerStatefulWidget {
  const PlannerSettingsScreen({super.key});

  @override
  ConsumerState<PlannerSettingsScreen> createState() =>
      _PlannerSettingsScreenState();
}

class _PlannerSettingsScreenState extends ConsumerState<PlannerSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plannerConsentNotifierProvider.notifier).loadConsent();
    });
  }

  Future<void> _showOptInConsentDialog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.studyPlannerConsentDialogTitle ??
              'Use Period Logs for Study Planning?',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.studyPlannerConsentDialogBody ??
              'We can use your recorded period days and your own energy check-ins to suggest gentler study pacing. Estimates and predicted dates are never used. Your data never leaves BloomWell and no AI has access to it. This is completely optional and can be turned off at any time. Turning this off will delete any plans that used your period logs.',
          style: AppTypography.bodySmall.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              l10n?.studyPlannerConsentDialogCancel ?? 'Not now',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          BloomButton(
            label: l10n?.studyPlannerConsentDialogConfirm ??
                'I understand & allow',
            height: 38.0,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(plannerConsentNotifierProvider.notifier);
      await notifier.updateConsent(enabled: true);
      if (mounted) {
        ref.read(studyPlannerNotifierProvider.notifier).loadPlan(refresh: true);
      }
    }
  }

  Future<void> _showRevocationDialog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.studyPlannerRevokeDialogTitle ?? 'Turn Off Period Log Access?',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.studyPlannerRevokeDialogBody ??
              'Turning this off will delete all study plans that used your period logs. Are you sure you want to turn it off?',
          style: AppTypography.bodySmall.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              l10n?.activityStepBack ?? 'Cancel',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              l10n?.studyPlannerRevokeConfirm ?? 'Turn off & delete plans',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(plannerConsentNotifierProvider.notifier);
      final deletedCount = await notifier.updateConsent(enabled: false);

      if (!mounted) return;
      ref.read(studyPlannerNotifierProvider.notifier).loadPlan(refresh: true);
      if (deletedCount != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.studyPlannerRevokeResult(deletedCount) ??
                'Period log access turned off. $deletedCount plans deleted.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;

    if (isLocked) {
      return const SizedBox.shrink();
    }

    final consentState = ref.watch(plannerConsentNotifierProvider);
    final cycleCareState = ref.watch(cycleCareNotifierProvider);
    final isTrackingOn = cycleCareState.isTrackingEnabled;
    final isConsentOn = consentState.isConsentEnabled;

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          tooltip: l10n?.activityStepBack ?? 'Back',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/study-planner');
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n?.studyPlannerSettingsTitle ??
                                'Study Planner Settings',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Consent Toggle Card
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n?.studyPlannerConsentSwitchTitle ??
                                  'Use my period logs to shape my plan',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                l10n?.studyPlannerConsentSwitchSubtitle ??
                                    'Optional pacing suggestions based on your recorded period days and energy check-ins.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            value: isTrackingOn && isConsentOn,
                            activeTrackColor: AppColors.primaryPurple,
                            onChanged:
                                (!isTrackingOn || consentState.isActionLoading)
                                    ? null
                                    : (newVal) {
                                        if (newVal) {
                                          _showOptInConsentDialog();
                                        } else {
                                          _showRevocationDialog();
                                        }
                                      },
                          ),

                          // Cycle tracking disabled notice
                          if (!isTrackingOn) ...[
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.lavender.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: AppColors.deepPurple,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n?.studyPlannerCycleTrackingDisabledNotice ??
                                              'Cycle tracking is currently off. Turn on CycleCare to enable this option.',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: AppColors.deepPurple,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          context.push('/cycle-care'),
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16),
                                      label: Text(
                                        l10n?.studyPlannerOpenCycleCare ??
                                            'Open CycleCare',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Privacy Assurance Note
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'BloomWell never predicts period days, never sends health records to AI models, and strictly isolates your consent preferences. Turning off access deletes all plans that used period logs.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.mutedText,
                          height: 1.4,
                        ),
                      ),
                    ),
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
