import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/activity_category.dart';

/// Filter chips row for category and duration filters in Self-Care Studio.
class CategoryFilterChips extends StatelessWidget {
  final ActivityCategory? selectedCategory;
  final int? selectedMaxDuration;
  final ValueChanged<ActivityCategory?> onCategoryChanged;
  final ValueChanged<int?> onDurationChanged;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.selectedMaxDuration,
    required this.onCategoryChanged,
    required this.onDurationChanged,
  });

  String _categoryLabel(ActivityCategory cat, AppLocalizations? l10n) {
    switch (cat) {
      case ActivityCategory.breathing:
        return l10n?.selfCareCategoryBreathing ?? 'Breathing';
      case ActivityCategory.grounding:
        return l10n?.selfCareCategoryGrounding ?? 'Grounding';
      case ActivityCategory.relaxation:
        return l10n?.selfCareCategoryRelaxation ?? 'Relaxation';
      case ActivityCategory.movement:
        return l10n?.selfCareCategoryMovement ?? 'Movement';
      case ActivityCategory.journaling:
        return l10n?.selfCareCategoryJournaling ?? 'Journaling';
      case ActivityCategory.studyBreak:
        return l10n?.selfCareCategoryStudyBreak ?? 'Study Break';
      case ActivityCategory.comfort:
        return l10n?.selfCareCategoryComfort ?? 'Comfort';
      case ActivityCategory.confidence:
        return l10n?.selfCareCategoryConfidence ?? 'Confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Chips (Horizontal Scroll)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              PillChip(
                label: l10n?.selfCareCategoryAll ?? 'All',
                isSelected: selectedCategory == null,
                onTap: () => onCategoryChanged(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              ...ActivityCategory.values.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: PillChip(
                    label: _categoryLabel(cat, l10n),
                    isSelected: selectedCategory == cat,
                    onTap: () => onCategoryChanged(cat),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Duration Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              PillChip(
                label: l10n?.selfCareDurationAny ?? 'Any duration',
                isSelected: selectedMaxDuration == null,
                onTap: () => onDurationChanged(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              PillChip(
                label: l10n?.selfCareDuration2 ?? 'Up to 2 min',
                isSelected: selectedMaxDuration == 2,
                onTap: () => onDurationChanged(2),
              ),
              const SizedBox(width: AppSpacing.sm),
              PillChip(
                label: l10n?.selfCareDuration5 ?? 'Up to 5 min',
                isSelected: selectedMaxDuration == 5,
                onTap: () => onDurationChanged(5),
              ),
              const SizedBox(width: AppSpacing.sm),
              PillChip(
                label: l10n?.selfCareDuration10 ?? 'Up to 10 min',
                isSelected: selectedMaxDuration == 10,
                onTap: () => onDurationChanged(10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
