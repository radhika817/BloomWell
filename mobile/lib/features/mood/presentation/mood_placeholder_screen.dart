import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class MoodPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const MoodPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.moodPlaceholderTitle ?? 'MoodMap & Insights',
      subtitle: l10n?.moodPlaceholderSubtitle ??
          'Understand your emotional patterns over time',
      emoji: '🌸',
      featureDescription: l10n?.moodPlaceholderDescription ??
          'MoodMap will provide historical charts, weekly reflections, and energy observations based on your daily check-ins. Today, you can try out the interactive mood selector directly on the Home screen.',
      onReturnHome: onReturnHome,
    );
  }
}
