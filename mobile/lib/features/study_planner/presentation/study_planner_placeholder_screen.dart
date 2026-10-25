import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../l10n/app_localizations.dart';

class StudyPlannerPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;

  const StudyPlannerPlaceholderScreen({super.key, this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n?.studyPlannerPlaceholderTitle ?? 'Study Planner',
      subtitle: l10n?.studyPlannerPlaceholderSubtitle ??
          'Cycle-aware, exam-aware academic pacing',
      emoji: '📚',
      featureDescription: l10n?.studyPlannerPlaceholderDescription ??
          'The Study Planner suggests lighter or heavier study blocks and rest breaks around your own energy check-ins and entered exam dates — as gentle suggestions, never rigid predictions.',
      extraChild: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: BloomButton(
          label: l10n?.examsTitle ?? 'Exams & Deadlines',
          icon: Icons.calendar_month_rounded,
          onPressed: () => context.push('/exams'),
        ),
      ),
      onReturnHome: onReturnHome,
    );
  }
}
