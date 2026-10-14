import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mood_bubble.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../mood/application/mood_notifier.dart';
import '../../../mood/domain/mood_kind.dart';

class _MoodVisual {
  final MoodKind kind;
  final String emoji;
  final String motif;
  final Color pastelColor;

  const _MoodVisual(this.kind, this.emoji, this.motif, this.pastelColor);
}

const List<_MoodVisual> _moodVisuals = [
  _MoodVisual(MoodKind.happy, '😊', '🌸', AppColors.moodHappy),
  _MoodVisual(MoodKind.calm, '😌', '🌿', AppColors.moodCalm),
  _MoodVisual(MoodKind.okay, '🙂', '☁️', AppColors.moodOkay),
  _MoodVisual(MoodKind.sad, '🥺', '🌧️', AppColors.moodSad),
  _MoodVisual(MoodKind.stressed, '😣', '⚡', AppColors.moodStressed),
];

/// Interactive mood check-in card using frosted glass and pastel MoodBubbles.
class MoodCheckinCard extends ConsumerWidget {
  final VoidCallback onNavigateToComfort;
  final VoidCallback onNavigateToHelp;

  const MoodCheckinCard({
    super.key,
    required this.onNavigateToComfort,
    required this.onNavigateToHelp,
  });

  String _label(MoodKind kind, AppLocalizations? l10n) {
    switch (kind) {
      case MoodKind.happy:
        return l10n?.moodHappy ?? 'Happy';
      case MoodKind.calm:
        return l10n?.moodCalm ?? 'Calm';
      case MoodKind.okay:
        return l10n?.moodOkay ?? 'Okay';
      case MoodKind.sad:
        return l10n?.moodSad ?? 'Sad';
      case MoodKind.stressed:
        return l10n?.moodStressed ?? 'Stressed';
    }
  }

  String _affirmation(MoodKind kind, AppLocalizations? l10n) {
    switch (kind) {
      case MoodKind.happy:
        return l10n?.moodHappyAffirmation ??
            'So glad you\'re feeling radiant today! Let this light nourish your day. ✨';
      case MoodKind.calm:
        return l10n?.moodCalmAffirmation ??
            'Cherish this peaceful energy. May your day stay gentle and unhurried. 🌿';
      case MoodKind.okay:
        return l10n?.moodOkayAffirmation ??
            'Steady and okay is wonderful. Honor wherever you are today. ☁️';
      case MoodKind.sad:
        return l10n?.moodSadAffirmation ??
            'It is okay to be gentle and slow today, darling. Sending warm thoughts. 🤍';
      case MoodKind.stressed:
        return l10n?.moodStressedAffirmation ??
            'Take a slow, deep breath. You are capable and more than your worries. 💜';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMood = ref.watch(moodNotifierProvider);
    final notifier = ref.read(moodNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context);

    _MoodVisual? selectedVisual;
    if (selectedMood != null) {
      selectedVisual =
          _moodVisuals.firstWhere((visual) => visual.kind == selectedMood);
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n?.moodQuestion ?? 'How are you feeling right now?',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selectedMood != null)
                Semantics(
                  button: true,
                  label: l10n?.moodReset ?? 'Reset mood selection',
                  child: GestureDetector(
                    onTap: notifier.clearMood,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        l10n?.moodReset ?? 'Reset',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Mood bubbles row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moodVisuals.map((visual) {
              final isSelected = selectedMood == visual.kind;
              final labelText = _label(visual.kind, l10n);
              return Expanded(
                child: MoodBubble(
                  label: labelText,
                  emoji: visual.emoji,
                  bubbleColor: visual.pastelColor,
                  isSelected: isSelected,
                  onTap: () => notifier.selectMood(visual.kind),
                ),
              );
            }).toList(),
          ),

          // Feedback container when a mood is selected
          if (selectedVisual != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: selectedVisual.pastelColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.25),
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
                        selectedVisual.motif,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _affirmation(selectedVisual.kind, l10n),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Supportive message and actions for Sad & Stressed
                  if (selectedVisual.kind.needsSupportOptions) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.moodSupportiveMessage ??
                                'It looks like today might be a bit heavy. You don\'t have to carry it alone. Please be extra gentle with yourself.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryText,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _SupportActionChip(
                                  label: l10n?.tryComfortMode ??
                                      'Try Comfort Mode',
                                  emoji: '🧸',
                                  onTap: onNavigateToComfort,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _SupportActionChip(
                                  label: l10n?.findSupport ?? 'Find support',
                                  emoji: '🤝',
                                  onTap: onNavigateToHelp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n?.moodDisclaimer ??
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

class _SupportActionChip extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;

  const _SupportActionChip({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(100.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100.0),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.0),
            border: Border.all(color: AppColors.primaryPurple, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
