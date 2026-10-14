import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class BloomBuddyPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const BloomBuddyPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.bloomBuddyPlaceholderTitle ?? 'Bloom Buddy',
      subtitle: l10n?.bloomBuddyPlaceholderSubtitle ??
          'Your warm, consent-separated companion',
      emoji: '✨',
      featureDescription: l10n?.bloomBuddyPlaceholderDescription ??
          'Bloom Buddy will bring together mindful reflections and peer care. Planned sections arriving in future updates include: AI Companion (with explicit consent), I\'m Here (gentle listening), Cycle Circles (moderated topic peer support), and HelpHub (verified campus access points).',
      onReturnHome: onReturnHome,
    );
  }
}
