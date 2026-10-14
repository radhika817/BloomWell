import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class ComfortPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const ComfortPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.comfortPlaceholderTitle ?? 'Comfort Mode',
      subtitle:
          l10n?.comfortPlaceholderSubtitle ?? 'Gentle care for difficult days',
      emoji: '🧸',
      featureDescription: l10n?.comfortPlaceholderDescription ??
          'Comfort Mode offers simplified, soothing routines, warm compress reminders, calming soundscapes, and non-diagnostic grounding prompts for when you are not feeling your best.',
      onReturnHome: onReturnHome,
    );
  }
}
