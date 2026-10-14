import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

class JournalPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const JournalPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Private Journal',
      subtitle: 'A safe, judgment-free space to write',
      emoji: '📖',
      phaseInfo: 'Phase 2 Feature',
      featureDescription:
          'Your journal entries will be encrypted, private by default, and never browsable by moderators or administrators. An on-device safety layer ensures gentle resources appear if distress language is detected.',
      onReturnHome: onReturnHome,
    );
  }
}
