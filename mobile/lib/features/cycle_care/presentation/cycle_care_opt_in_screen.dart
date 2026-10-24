import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../application/cycle_care_notifier.dart';

/// Screen presented when a user has not opted into CycleCare tracking.
/// Provides plain-language privacy, ownership, and non-diagnostic disclosures
/// with explicit voluntary consent before any cycle features or predictions are enabled.
class CycleCareOptInScreen extends ConsumerWidget {
  final VoidCallback? onOptedIn;
  final VoidCallback? onNotNow;

  const CycleCareOptInScreen({
    super.key,
    this.onOptedIn,
    this.onNotNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(cycleCareNotifierProvider);
    final notifier = ref.read(cycleCareNotifierProvider.notifier);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gentle body rhythm emblem
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lavender.withValues(alpha: 0.5),
                          border: Border.all(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.water_drop_outlined,
                          size: 36,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      l10n.cycleOptInTitle,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Subtitle
                    Text(
                      l10n.cycleOptInSubtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Disclosures Card
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 20,
                                color: AppColors.primaryPurple,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  l10n.cycleOptInNoticeHeader,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 16,
                                    color: AppColors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DisclosureRow(
                            icon: Icons.lock_outline,
                            text: l10n.cycleOptInNoticeStorage,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DisclosureRow(
                            icon: Icons.lightbulb_outline,
                            text: l10n.cycleOptInNoticeEstimates,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DisclosureRow(
                            icon: Icons.favorite_outline,
                            text: l10n.cycleOptInNoticeNonMedical,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DisclosureRow(
                            icon: Icons.tune,
                            text: l10n.cycleOptInNoticeControl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Error banner if any
                    if (state.errorMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blushPink,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: AppColors.softRose.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.deepPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Primary Action: Turn on cycle tracking
                    if (state.isActionLoading)
                      const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      BloomButton(
                        key: const Key('cycle_opt_in_enable_button'),
                        label: l10n.cycleOptInEnableButton,
                        variant: BloomButtonVariant.primary,
                        isExpanded: true,
                        onPressed: () async {
                          final success = await notifier.enableTracking();
                          if (success && onOptedIn != null) {
                            onOptedIn!();
                          }
                        },
                      ),
                    const SizedBox(height: AppSpacing.sm),

                    // Secondary Action: Not now
                    BloomButton(
                      key: const Key('cycle_opt_in_not_now_button'),
                      label: l10n.cycleOptInNotNowButton,
                      variant: BloomButtonVariant.subtle,
                      isExpanded: true,
                      onPressed: () {
                        if (onNotNow != null) {
                          onNotNow!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
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

class _DisclosureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DisclosureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.lavender.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
