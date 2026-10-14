import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import 'app_card.dart';
import 'bloom_button.dart';
import 'decorative_badge.dart';

/// Honest, beautifully designed placeholder screen for features planned
/// for subsequent updates.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? arrivalInfo;
  final String featureDescription;
  final VoidCallback? onReturnHome;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.arrivalInfo,
    required this.featureDescription,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveArrival = arrivalInfo ??
        l10n?.placeholderPlannedLabel ??
        'Coming in a later update';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTypography.titleLarge),
        leading: onReturnHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: onReturnHome,
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: AppColors.lavender,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DecorativeBadge(
                    label: effectiveArrival,
                    emoji: '🌱',
                    backgroundColor: AppColors.blushPink,
                    textColor: AppColors.deepPurple,
                    borderColor: AppColors.borderSubtle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    backgroundColor: Colors.white,
                    borderColor: AppColors.borderLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.deepPurple,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n?.placeholderPlannedHeading ??
                                  'Planned Implementation',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          featureDescription,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Row(
                            children: [
                              const Text('🔒', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  l10n?.placeholderDisclaimer ??
                                      'BloomWell does not fabricate user records or mock health data. Real tracking begins when the local storage & API layers are integrated.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondaryText,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onReturnHome != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    BloomButton(
                      label: l10n?.placeholderBackToHome ?? 'Back to Home',
                      emoji: '🌸',
                      onPressed: onReturnHome,
                      variant: BloomButtonVariant.primary,
                      isExpanded: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
