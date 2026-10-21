import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Skippable bottom sheet offering Discreet Mode (app lock) setup after registration.
class DiscreetOnboardingSheet extends StatelessWidget {
  const DiscreetOnboardingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DiscreetOnboardingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.blushPink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🛡️', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.discreetOnboardingTitle ?? 'Keep Your Space Discreet 🌸',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.discreetOnboardingBody ??
                'Many students share devices or live with roommates. You can add a quick PIN lock to shield your check-ins and journal notes from casual view.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: l10n?.discreetOnboardingSetupButton ?? 'Set Up PIN Lock',
            isExpanded: true,
            icon: Icons.lock_outline_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/lock/setup');
            },
          ),
          const SizedBox(height: 10),
          BloomButton(
            label: l10n?.discreetOnboardingNotNowButton ?? 'Not Now',
            variant: BloomButtonVariant.subtle,
            isExpanded: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
