import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class CycleCarePlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const CycleCarePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.cycleCarePlaceholderTitle ?? 'CycleCare',
      subtitle: l10n?.cycleCarePlaceholderSubtitle ??
          'Gentle, private menstrual and symptom logging',
      emoji: '🌷',
      featureDescription: l10n?.cycleCarePlaceholderDescription ??
          'CycleCare will allow you to log period dates, cramp severity, bloating, and fatigue. All cycle estimates will be clearly distinguished from recorded dates, strictly non-diagnostic, and stored securely.',
      onReturnHome: onReturnHome,
    );
  }
}
