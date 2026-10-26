import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';

/// The My Mood screen offering an educational overview, empty state
/// with a pastel bubble cluster, and on-device privacy guarantee.
class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n?.myMoodTitle ?? 'My Mood',
                        style: AppTypography.display.copyWith(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Decorative Pastel Bubble Cluster
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 10,
                            left: 40,
                            child: _buildDecorativeBubble(
                                '🌿', AppColors.moodCalm, 64),
                          ),
                          Positioned(
                            top: 0,
                            right: 50,
                            child: _buildDecorativeBubble(
                                '✨', AppColors.moodHappy, 72),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 80,
                            child: _buildDecorativeBubble(
                                '☁️', AppColors.moodOkay, 68),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 70,
                            child: _buildDecorativeBubble(
                                '💜', AppColors.moodStressed, 60),
                          ),
                          Positioned(
                            top: 48,
                            child: _buildDecorativeBubble('🌸',
                                AppColors.softRose.withValues(alpha: 0.7), 80),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Main Glass Content Card
                    GlassCard(
                      padding: const EdgeInsets.all(26.0),
                      child: Column(
                        children: [
                          Text(
                            l10n?.myMoodEmptyTitle ??
                                'Check in with your feelings',
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            l10n?.myMoodEmptySubtitle ??
                                'Notice how your body and emotions feel today. Your reflections are private and never leave your phone.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          GradientButton(
                            label:
                                l10n?.myMoodCheckInButton ?? 'Check In on Home',
                            icon: Icons.favorite_rounded,
                            isExpanded: true,
                            onPressed: () => context.go('/'),
                          ),
                          const SizedBox(height: 12.0),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              side: const BorderSide(
                                  color: AppColors.borderSubtle),
                            ),
                            icon: const Icon(Icons.insights_rounded,
                                size: 18, color: AppColors.deepPurple),
                            label: Text(
                              l10n?.insightsTitle ?? 'Personal Observations',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.deepPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => context.push('/insights'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // On-device privacy badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          l10n?.myMoodPrivacyNote ??
                              'Strictly on-device · No tracking',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
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

  Widget _buildDecorativeBubble(String emoji, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.42),
        ),
      ),
    );
  }
}
