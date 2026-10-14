import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../l10n/app_localizations.dart';
import 'self_care_card.dart';

/// Two-column self-care section displaying Journal, CycleCare,
/// Breathe & Relax, and Bloom Buddy.
class SelfCareSection extends StatelessWidget {
  final VoidCallback onNavigateToJournal;
  final VoidCallback onNavigateToCycleCare;
  final VoidCallback onNavigateToBreathe;
  final VoidCallback onNavigateToBloomBuddy;

  const SelfCareSection({
    super.key,
    required this.onNavigateToJournal,
    required this.onNavigateToCycleCare,
    required this.onNavigateToBreathe,
    required this.onNavigateToBloomBuddy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: l10n?.selfCareHeading ?? 'Self-Care Routines 🌿',
          subtitle: l10n?.selfCareSubtitle ??
              'Gentle rituals to nourish your body and mind',
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.95,
          children: [
            SelfCareCard(
              title: l10n?.journalTitle ?? 'Journal',
              subtitle: l10n?.journalSubtitle ?? 'Private thoughts & feelings',
              emoji: '📖',
              badgeText: l10n?.journalBadge ?? 'Private',
              pastelBackground: AppColors.blushPink,
              accentColor: AppColors.primaryPurple,
              onTap: onNavigateToJournal,
            ),
            SelfCareCard(
              title: l10n?.cycleCareTitle ?? 'CycleCare',
              subtitle: l10n?.cycleCareSubtitle ?? 'Symptom & cycle tracking',
              emoji: '🌷',
              badgeText: l10n?.cycleCareBadge ?? 'Optional',
              pastelBackground: AppColors.peach,
              accentColor: AppColors.deepPurple,
              onTap: onNavigateToCycleCare,
            ),
            SelfCareCard(
              title: l10n?.breatheTitle ?? 'Breathe & Relax',
              subtitle: l10n?.breatheSubtitle ?? 'Guided grounding exercises',
              emoji: '🍃',
              badgeText: l10n?.breatheBadge ?? 'about 2 min',
              pastelBackground: AppColors.mint,
              accentColor: AppColors.deepPurple,
              onTap: onNavigateToBreathe,
            ),
            SelfCareCard(
              title: l10n?.bloomBuddyTitle ?? 'Bloom Buddy',
              subtitle: l10n?.bloomBuddySubtitle ?? 'Gentle companion',
              emoji: '✨',
              badgeText: l10n?.comingSoonBadge ?? 'Coming soon',
              pastelBackground: AppColors.lavender,
              accentColor: AppColors.primaryPurple,
              onTap: onNavigateToBloomBuddy,
            ),
          ],
        ),
      ],
    );
  }
}
