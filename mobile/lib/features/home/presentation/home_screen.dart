import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/decorative_badge.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/breathing_card.dart';
import 'widgets/encouragement_card.dart';
import 'widgets/greeting_header.dart';
import 'widgets/mood_checkin_card.dart';
import 'widgets/self_care_section.dart';

/// The BloomWell Home Screen.
///
/// Features a soft, feminine, calming pastel UI with local mood check-in,
/// supportive daily thought, self-care shortcuts, study planner banner,
/// hard-day care shortcut, and calibrated mindful breathing.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showDiscreetInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🛡️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n?.discreetSheetTitle ?? 'Discreet Mode (Planned)',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n?.discreetSheetBody ??
                    'BloomWell is designed with privacy as a foundation. In a future update, you will be able to lock the app with PIN or biometrics, obscure switcher previews, and configure neutral notifications. Currently, this mode is planned and not yet active.',
                style: AppTypography.bodyMedium.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n?.discreetSheetButton ?? 'Got it 🌸',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Discreet Mode Badge
                  GreetingHeader(
                    onDiscreetToggle: () => _showDiscreetInfo(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Interactive Mood Check-in
                  MoodCheckinCard(
                    onNavigateToComfort: () => context.push('/comfort'),
                    onNavigateToHelp: () => context.push('/help'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // "I'm having a hard day" supportive action button
                  BloomButton(
                    label:
                        l10n?.hardDayButtonLabel ?? 'I\'m having a hard day 🤍',
                    variant: BloomButtonVariant.subtle,
                    isExpanded: true,
                    onPressed: () => context.push('/comfort'),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Daily Encouragement Card
                  const EncouragementCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // Full-width "Plan my study week" card
                  Semantics(
                    button: true,
                    label: l10n?.planStudyWeekTitle ??
                        'Plan my study week, cycle and exam pacing',
                    child: AppCard(
                      onTap: () => context.push('/study-planner'),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF7F2FF), // Soft Lavender glow
                          Color(0xFFFFF4EC), // Soft Peach
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderColor: const Color(0xFFE4D8F5),
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.lavender,
                              borderRadius: AppSpacing.roundedMd,
                            ),
                            alignment: Alignment.center,
                            child: const Text('📚',
                                style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n?.planStudyWeekTitle ??
                                            'Plan my study week 📚',
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DecorativeBadge(
                                      label: l10n?.comingSoonBadge ??
                                          'Coming soon',
                                      backgroundColor: Colors.white,
                                      textColor: AppColors.deepPurple,
                                      borderColor: AppColors.borderSubtle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n?.planStudyWeekSubtitle ??
                                      'Cycle-aware, exam-aware suggestions to pace your study and rest.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondaryText,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Two-column Self-Care Section
                  SelfCareSection(
                    onNavigateToJournal: () => context.push('/journal'),
                    onNavigateToCycleCare: () => context.go('/cycle-care'),
                    onNavigateToBreathe: () => context.push('/breathe'),
                    onNavigateToBloomBuddy: () => context.go('/bloom-buddy'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Mindful Breathing Card
                  const BreathingCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Footer Motifs
                  Center(
                    child: Column(
                      children: [
                        Text(
                          l10n?.footerMotifs ?? '🌸 · ☁️ · 🤍 · 🌙 · ✨',
                          style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n?.footerTagline ??
                              'BloomWell · Gentle, private self-care',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
