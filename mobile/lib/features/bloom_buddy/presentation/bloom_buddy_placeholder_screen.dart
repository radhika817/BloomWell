import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

class BloomBuddyPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const BloomBuddyPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Bloom Buddy',
      subtitle: 'Your warm, consent-separated AI companion',
      emoji: '✨',
      phaseInfo: 'Phase 3 Feature',
      featureDescription:
          'Bloom Buddy will offer gentle reflection prompts and comfort ideas. BloomWell requires explicit, separated consent for AI features, safeguards distress phrases locally, and never logs raw journal text without your permission.',
      onReturnHome: onReturnHome,
    );
  }
}
