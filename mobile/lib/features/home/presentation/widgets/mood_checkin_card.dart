import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// The 5 supported moods for check-in.
enum BloomMood {
  happy('Happy', '😊', '🌸', AppColors.peach,
      'So glad you\'re feeling radiant today! Let this light nourish your day. ✨'),
  calm('Calm', '😌', '🌿', AppColors.mint,
      'Cherish this peaceful energy. May your day stay gentle and unhurried. 🌿'),
  okay('Okay', '🙂', '☁️', AppColors.lavender,
      'Steady and okay is wonderful. Honor wherever you are today. ☁️'),
  sad('Sad', '🥺', '🌧️', Color(0xFFDCEBFF),
      'It is okay to be gentle and slow today, darling. Sending warm thoughts. 🤍'),
  stressed('Stressed', '😣', '⚡', AppColors.blushPink,
      'Take a slow, deep breath. You are capable and more than your worries. 💜');

  final String label;
  final String emoji;
  final String motif;
  final Color pastelColor;
  final String affirmation;

  const BloomMood(
    this.label,
    this.emoji,
    this.motif,
    this.pastelColor,
    this.affirmation,
  );
}

/// Interactive mood check-in card using local state.
class MoodCheckinCard extends StatelessWidget {
  final BloomMood? selectedMood;
  final ValueChanged<BloomMood?> onMoodChanged;

  const MoodCheckinCard({
    super.key,
    required this.selectedMood,
    required this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.borderLight,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How are you feeling right now?',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selectedMood != null)
                GestureDetector(
                  onTap: () => onMoodChanged(null),
                  child: Text(
                    'Reset',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Mood items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: BloomMood.values.map((mood) {
              final isSelected = selectedMood == mood;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: _MoodButton(
                    mood: mood,
                    isSelected: isSelected,
                    onTap: () {
                      onMoodChanged(isSelected ? null : mood);
                    },
                  ),
                ),
              );
            }).toList(),
          ),

          // Feedback container when a mood is selected
          if (selectedMood != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: selectedMood!.pastelColor.withOpacity(0.5),
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedMood!.motif,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          selectedMood!.affirmation,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Session check-in · Not persisted',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final BloomMood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        splashColor: AppColors.primaryPurple.withOpacity(0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? mood.pastelColor : AppColors.surfaceElevated,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isSelected ? AppColors.primaryPurple : AppColors.borderLight,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                mood.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.deepPurple : AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
