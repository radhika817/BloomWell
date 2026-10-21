import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_notifier.dart';

class ProfilePlaceholderScreen extends ConsumerWidget {
  final VoidCallback? onReturnHome;

  const ProfilePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return PlaceholderScreen(
      title: l10n?.profilePlaceholderTitle ?? 'Profile & Privacy Center',
      subtitle: l10n?.profilePlaceholderSubtitle ??
          'Complete control over your personal data',
      emoji: '🤍',
      featureDescription: l10n?.profilePlaceholderDescription ??
          'The Privacy Center will host Discreet Mode (app lock, neutral notifications), exportable Doctor-visit summaries, language selection (English, Hindi, Marathi), and full one-tap data deletion.',
      onReturnHome: onReturnHome,
      extraChild: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (authState.isAuthenticated && user != null) ...[
            GlassCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.deepPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Student',
                              style: AppTypography.titleSmall,
                            ),
                            Text(
                              '${user.role} · ${user.timezone}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            BloomButton(
              label: l10n?.privacyCenterTitle ?? 'Privacy Center',
              variant: BloomButtonVariant.subtle,
              icon: Icons.shield_outlined,
              isExpanded: true,
              onPressed: () => context.push('/profile/privacy'),
            ),
            const SizedBox(height: 12.0),
            BloomButton(
              label: l10n?.authLogout ?? 'Log Out',
              variant: BloomButtonVariant.secondary,
              icon: Icons.logout_rounded,
              isExpanded: true,
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ] else ...[
            GradientButton(
              label: l10n?.authCreateAccount ?? 'Create Account',
              isExpanded: true,
              onPressed: () => context.go('/register'),
            ),
            const SizedBox(height: 10.0),
            BloomButton(
              label: l10n?.authSignIn ?? 'Sign In',
              variant: BloomButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.go('/login'),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 12.0),
            TextButton.icon(
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
            ),
          ],
        ],
      ),
    );
  }
}
