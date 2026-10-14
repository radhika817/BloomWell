import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class BreathePlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const BreathePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.breathePlaceholderTitle ?? 'Breathe & Relax',
      subtitle: l10n?.breathePlaceholderSubtitle ??
          'Gentle somatic calming & grounding exercises',
      emoji: '🍃',
      featureDescription: l10n?.breathePlaceholderDescription ??
          'Expanded audio sessions, 4-7-8 breathing techniques, progressive muscle relaxation, and warm compress reminders will be available here. For now, try out the mindful breathing exercise right on your Home screen!',
      onReturnHome: onReturnHome,
    );
  }
}
