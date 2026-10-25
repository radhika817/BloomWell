import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/routine_item.dart';

/// Interactive tile for a single activity inside a routine.
/// Features a gentle done checkbox toggle, activity details, and delete action.
class RoutineItemTile extends ConsumerWidget {
  final String routineId;
  final RoutineItem item;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onDelete;

  const RoutineItemTile({
    super.key,
    required this.routineId,
    required this.item,
    required this.onToggleDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = item.activityTitle.isNotEmpty
        ? item.activityTitle
        : (l10n?.routinesAddItem ?? 'Activity');
    final targetActivityId = item.activityId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        onTap: () {
          if (targetActivityId.isNotEmpty) {
            context.push('/self-care/activity/$targetActivityId');
          }
        },
        child: Row(
          children: [
            // Done Toggle Button (min 48x48 tap target for a11y)
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: Icon(
                  item.isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: item.isDone
                      ? AppColors.primaryPurple
                      : AppColors.mutedText,
                  size: 22,
                ),
                tooltip: item.isDone ? 'Mark not done' : 'Mark done',
                onPressed: () => onToggleDone(!item.isDone),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Activity Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration:
                          item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone
                          ? AppColors.secondaryText
                          : AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Delete item button
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
              tooltip: l10n?.routinesDeleteButton ?? 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
