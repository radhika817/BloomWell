import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const ProfilePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.profilePlaceholderTitle ?? 'Profile & Privacy Center',
      subtitle: l10n?.profilePlaceholderSubtitle ??
          'Complete control over your personal data',
      emoji: '🤍',
      featureDescription: l10n?.profilePlaceholderDescription ??
          'The Privacy Center will host Discreet Mode (app lock, neutral notifications), exportable Doctor-visit summaries, language selection (English, Hindi, Marathi), and full one-tap data deletion.',
      onReturnHome: onReturnHome,
      extraChild: kDebugMode
          ? TextButton.icon(
              onPressed: () => context.push('/welcome'),
              icon: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppColors.deepPurple,
              ),
              label: Text(
                l10n?.debugPreviewWelcome ?? 'Preview Welcome Screen (Debug)',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.deepPurple,
                ),
              ),
            )
          : null,
    );
  }
}
