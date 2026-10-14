import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const ProfilePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Profile & Privacy Center',
      subtitle: 'Complete control over your personal data',
      emoji: '🤍',
      phaseInfo: 'Phase 4 Feature',
      featureDescription:
          'The Privacy Center will host Discreet Mode (app lock, neutral notifications), exportable Doctor-visit summaries, language selection (English, Hindi, Marathi), and full one-tap data deletion.',
      onReturnHome: onReturnHome,
    );
  }
}
