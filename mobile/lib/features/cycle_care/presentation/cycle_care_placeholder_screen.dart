import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

class CycleCarePlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const CycleCarePlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'CycleCare',
      subtitle: 'Gentle, private menstrual and symptom logging',
      emoji: '🌷',
      phaseInfo: 'Phase 2 Feature',
      featureDescription:
          'CycleCare will allow you to log period dates, cramp severity, bloating, and fatigue. All cycle estimates will be clearly distinguished from recorded dates, strictly non-diagnostic, and stored securely.',
      onReturnHome: onReturnHome,
    );
  }
}
