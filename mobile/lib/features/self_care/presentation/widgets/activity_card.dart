import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/activity_category.dart';
import '../../domain/entities/activity_entry.dart';

/// Interactive activity card displaying title, duration, category badge,
/// summary, and an accessible server-confirmed favorite toggle heart.
class ActivityCard extends StatelessWidget {
  final ActivityEntry activity;
  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.isFavorite,
    this.isFavoriteLoading = false,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  Color _categoryPastelColor(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.breathing:
        return AppColors.mint;
      case ActivityCategory.grounding:
        return AppColors.peach;
      case ActivityCategory.relaxation:
        return AppColors.lavender;
      case ActivityCategory.movement:
        return AppColors.softRose;
      case ActivityCategory.journaling:
        return AppColors.blushPink;
      case ActivityCategory.studyBreak:
        return AppColors.softSky;
      case ActivityCategory.comfort:
        return const Color(0xFFFFE8DC);
      case ActivityCategory.confidence:
        return const Color(0xFFFFF0D4);
    }
  }

  String _categoryEmoji(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.breathing:
        return '🫧';
      case ActivityCategory.grounding:
        return '🌱';
      case ActivityCategory.relaxation:
        return '🌿';
      case ActivityCategory.movement:
        return '🧘‍♀️';
      case ActivityCategory.journaling:
        return '📖';
      case ActivityCategory.studyBreak:
        return '☕';
      case ActivityCategory.comfort:
        return '🧸';
      case ActivityCategory.confidence:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pastelColor = _categoryPastelColor(activity.category);
    final emoji = _categoryEmoji(activity.category);

    final a11yFavoriteLabel = isFavorite
        ? (l10n?.selfCareRemoveFavoriteA11y ?? 'Remove from favorites')
        : (l10n?.selfCareAddFavoriteA11y ?? 'Add to favorites');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pastelColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title and duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          DecorativeBadge(
                            label: l10n?.selfCareDurationMinutes(
                                    activity.durationMinutes) ??
                                '${activity.durationMinutes} min',
                            backgroundColor: pastelColor.withValues(alpha: 0.6),
                            textColor: AppColors.deepPurple,
                          ),
                          if (activity.isComfortCategory) ...[
                            const SizedBox(width: 6),
                            DecorativeBadge(
                              label: l10n?.selfCareCategoryComfort ?? 'Comfort',
                              backgroundColor: const Color(0xFFFFECE2),
                              textColor: const Color(0xFF9E4B28),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Accessible Favorite Toggle Heart (min 48x48 tap target)
                Semantics(
                  button: true,
                  label: a11yFavoriteLabel,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: isFavoriteLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryPurple,
                                ),
                              ),
                            )
                          : Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? AppColors.primaryPurple
                                  : AppColors.mutedText,
                              size: 24,
                            ),
                      onPressed: isFavoriteLoading ? null : onFavoriteToggle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              activity.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
