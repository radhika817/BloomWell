import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_mascot.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';

/// Welcome preview screen displaying BloomWell's core pillars,
/// the vector mascot, and soft glass cards.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12.0),
                    // Bloomie Mascot
                    const BloomMascot(size: 110.0),
                    const SizedBox(height: 20.0),

                    // Title & Subtitle
                    Text(
                      l10n?.welcomeTitle ?? 'Welcome to BloomWell',
                      textAlign: TextAlign.center,
                      style: AppTypography.display.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      l10n?.welcomeSubtitle ??
                          'A gentle, private wellness companion made for students.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28.0),

                    // 3 Feature Glass Cards
                    _buildFeatureCard(
                      context,
                      icon: Icons.shield_outlined,
                      title: l10n?.welcomeFeature1Title ?? 'Privacy First',
                      description: l10n?.welcomeFeature1Desc ??
                          'Your journal, mood, and cycle reflections are private and owner-scoped.',
                    ),
                    const SizedBox(height: 14.0),
                    _buildFeatureCard(
                      context,
                      icon: Icons.spa_outlined,
                      title: l10n?.welcomeFeature2Title ?? 'Calm & Supportive',
                      description: l10n?.welcomeFeature2Desc ??
                          'Gentle pacing, mindful breathing, and non-judgmental comfort.',
                    ),
                    const SizedBox(height: 14.0),
                    _buildFeatureCard(
                      context,
                      icon: Icons.menu_book_rounded,
                      title: l10n?.welcomeFeature3Title ?? 'Academic Pacing',
                      description: l10n?.welcomeFeature3Desc ??
                          'Cycle-aware, exam-aware suggestions to pace study and rest.',
                    ),
                    const SizedBox(height: 32.0),

                    // CTA Button
                    GradientButton(
                      label: l10n?.welcomeCta ?? 'Explore BloomWell',
                      isExpanded: true,
                      onPressed: () => context.go('/'),
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

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(
              icon,
              color: AppColors.deepPurple,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
