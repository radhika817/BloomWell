import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_heading.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          title: 'Self-Care Routines 🌿',
          subtitle: 'Gentle rituals to nourish your body and mind',
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.15,
          children: [
            SelfCareCard(
              title: 'Journal',
              subtitle: 'Private thoughts & feelings',
              emoji: '📖',
              badgeText: 'Private',
              pastelBackground: AppColors.blushPink,
              accentColor: AppColors.primaryPurple,
              onTap: onNavigateToJournal,
            ),
            SelfCareCard(
              title: 'CycleCare',
              subtitle: 'Symptom & cycle tracking',
              emoji: '🌷',
              badgeText: 'Optional',
              pastelBackground: AppColors.peach,
              accentColor: AppColors.deepPurple,
              onTap: onNavigateToCycleCare,
            ),
            SelfCareCard(
              title: 'Breathe & Relax',
              subtitle: 'Guided grounding exercises',
              emoji: '🍃',
              badgeText: '2 min',
              pastelBackground: AppColors.mint,
              accentColor: AppColors.deepPurple,
              onTap: onNavigateToBreathe,
            ),
            SelfCareCard(
              title: 'Bloom Buddy',
              subtitle: 'Gentle AI companion',
              emoji: '✨',
              badgeText: 'AI Support',
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
