import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class HelpPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const HelpPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.helpPlaceholderTitle ?? 'Support Resources & HelpHub',
      subtitle: l10n?.helpPlaceholderSubtitle ??
          'Verified campus care and period-product access',
      emoji: '🤝',
      featureDescription: l10n?.helpPlaceholderDescription ??
          'HelpHub connects you to verified campus dispensers, health center resources, helplines, and period-product access points with real verification dates and student reporting.',
      onReturnHome: onReturnHome,
    );
  }
}
