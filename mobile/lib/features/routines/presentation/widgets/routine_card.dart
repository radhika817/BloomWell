import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/routines_notifier.dart';
import '../../domain/entities/routine.dart';
import 'add_routine_item_dialog.dart';
import 'create_edit_routine_dialog.dart';
import 'routine_item_tile.dart';

/// Card displaying a single routine, its items, peaceful progress text ("x of y done"),
/// and strict 50-item limit protection. Strictly avoids streaks and percentages.
class RoutineCard extends ConsumerWidget {
  final Routine routine;

  const RoutineCard({
    super.key,
    required this.routine,
  });

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.routinesDeleteButton ?? 'Delete Routine',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          l10n?.routinesDeleteConfirm ??
              'Are you sure you want to delete this routine?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.activityStepBack ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(routinesNotifierProvider.notifier)
                  .deleteRoutine(routine.id);
            },
            child: Text(
              l10n?.routinesDeleteButton ?? 'Delete',
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(routinesNotifierProvider.notifier);
    final isLimitReached = routine.items.length >= 50;

    String? dateRangeText;
    if (routine.startDate != null && routine.endDate != null) {
      dateRangeText =
          '${_formatDate(routine.startDate!)} — ${_formatDate(routine.endDate!)}';
    } else if (routine.startDate != null) {
      dateRangeText = 'From ${_formatDate(routine.startDate!)}';
    } else if (routine.endDate != null) {
      dateRangeText = 'Until ${_formatDate(routine.endDate!)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (dateRangeText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateRangeText,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit & Delete Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.secondaryText),
                  onSelected: (val) {
                    if (val == 'edit') {
                      CreateEditRoutineDialog.show(
                        context,
                        routine: routine,
                        onSave: (title, start, end) async {
                          await notifier.updateRoutine(
                            id: routine.id,
                            title: title,
                            startDate: start,
                            endDate: end,
                            clearStartDate: start == null,
                            clearEndDate: end == null,
                          );
                        },
                      );
                    } else if (val == 'delete') {
                      _showDeleteConfirmation(context, ref, l10n);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n?.routinesEditTitle ?? 'Edit Routine'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n?.routinesDeleteButton ?? 'Delete',
                        style: const TextStyle(color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Peaceful progress counter ("x of y done" text) - Strictly NO streaks or %
            Row(
              children: [
                DecorativeBadge(
                  label: l10n?.routinesProgressText(routine.completedItemsCount,
                          routine.totalItemsCount) ??
                      routine.progressText,
                  backgroundColor: AppColors.mint.withValues(alpha: 0.6),
                  textColor: AppColors.deepPurple,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Routine Items List
            if (routine.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'No activities added yet.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...routine.items.map((item) {
                return RoutineItemTile(
                  routineId: routine.id,
                  item: item,
                  onToggleDone: (done) {
                    notifier.toggleItemDone(
                      routineId: routine.id,
                      itemId: item.id,
                      isDone: done,
                    );
                  },
                  onDelete: () {
                    notifier.deleteItem(
                      routineId: routine.id,
                      itemId: item.id,
                    );
                  },
                );
              }),

            const SizedBox(height: AppSpacing.sm),

            // 50-Item Limit Guard Notice
            if (isLimitReached)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n?.routinesItemLimitExceeded ??
                      'You have reached the maximum limit of 50 activities for this routine.',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFD32F2F),
                  ),
                ),
              ),

            // Add Activity Button
            BloomButton(
              label: l10n?.routinesAddItem ?? 'Add activity',
              icon: Icons.add_rounded,
              variant: BloomButtonVariant.subtle,
              onPressed: isLimitReached
                  ? null
                  : () {
                      AddRoutineItemDialog.show(
                        context,
                        onAdd: (actId, scheduled) async {
                          await notifier.addItem(
                            routineId: routine.id,
                            activityId: actId,
                            scheduledDate: scheduled,
                          );
                        },
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
