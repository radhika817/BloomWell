import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class JournalPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const JournalPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.journalPlaceholderTitle ?? 'Private Journal',
      subtitle: l10n?.journalPlaceholderSubtitle ??
          'A safe, judgment-free space to write',
      emoji: '📖',
      featureDescription: l10n?.journalPlaceholderDescription ??
          'Your journal entries will be encrypted, private by default, and never browsable by moderators or administrators. An on-device safety layer ensures gentle resources appear if distress language is detected.',
      onReturnHome: onReturnHome,
    );
  }
}
