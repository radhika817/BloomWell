import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

class MoodPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const MoodPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'MoodMap & Insights',
      subtitle: 'Understand your emotional patterns over time',
      emoji: '🌸',
      phaseInfo: 'Phase 2 Feature',
      featureDescription:
          'MoodMap will provide historical charts, weekly reflections, and energy observations based on your daily check-ins. In Phase 1, you can try out the interactive mood selector directly on the Home screen.',
      onReturnHome: onReturnHome,
    );
  }
}
