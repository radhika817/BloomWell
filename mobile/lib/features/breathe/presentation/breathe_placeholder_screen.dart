import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

class BreathePlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const BreathePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Breathe & Relax',
      subtitle: 'Gentle somatic calming & grounding exercises',
      emoji: '🍃',
      phaseInfo: 'Phase 2 Feature',
      featureDescription:
          'Expanded audio sessions, 4-7-8 breathing techniques, progressive muscle relaxation, and warm compress reminders will be available here. For now, try out the 2-minute mindful breathing exercise right on your Home screen!',
      onReturnHome: onReturnHome,
    );
  }
}
