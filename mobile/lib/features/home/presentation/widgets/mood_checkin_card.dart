import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
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
  _MoodVisual(MoodKind.happy, '😊', '🌸', AppColors.peach),
  _MoodVisual(MoodKind.calm, '😌', '🌿', AppColors.mint),
  _MoodVisual(MoodKind.okay, '🙂', '☁️', AppColors.lavender),
  _MoodVisual(MoodKind.sad, '🥺', '🌧️', Color(0xFFDCEBFF)),
  _MoodVisual(MoodKind.stressed, '😣', '⚡', AppColors.blushPink),
];

/// Interactive mood check-in card connected to Riverpod session state.
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Mood items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moodVisuals.map((visual) {
              final isSelected = selectedMood == visual.kind;
              final labelText = _label(visual.kind, l10n);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: '$labelText, mood check-in',
                    child: _MoodButton(
                      visual: visual,
                      label: labelText,
                      isSelected: isSelected,
                      onTap: () => notifier.selectMood(visual.kind),
                    ),
                  ),
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
                color: selectedVisual.pastelColor.withValues(alpha: 0.5),
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.2),
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
                            fontWeight: FontWeight.w500,
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
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: AppSpacing.roundedSm,
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
      borderRadius: AppSpacing.roundedPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7.0),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedPill,
            border: Border.all(color: AppColors.primaryPurple, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
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

class _MoodButton extends StatelessWidget {
  final _MoodVisual visual;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.visual,
    required this.label,
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
        splashColor: AppColors.primaryPurple.withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
            color: isSelected ? visual.pastelColor : AppColors.surfaceElevated,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color:
                  isSelected ? AppColors.primaryPurple : AppColors.borderLight,
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
                visual.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.deepPurple
                      : AppColors.secondaryText,
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
