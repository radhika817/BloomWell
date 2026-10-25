import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../self_care/application/self_care_notifier.dart';
import '../../../self_care/domain/entities/activity_entry.dart';

/// Dialog to select and add a self-care activity to a routine.
class AddRoutineItemDialog extends ConsumerStatefulWidget {
  final Future<void> Function(String activityId, DateTime? scheduledDate) onAdd;

  const AddRoutineItemDialog({
    super.key,
    required this.onAdd,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String activityId, DateTime? scheduledDate)
        onAdd,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddRoutineItemDialog(onAdd: onAdd),
    );
  }

  @override
  ConsumerState<AddRoutineItemDialog> createState() =>
      _AddRoutineItemDialogState();
}

class _AddRoutineItemDialogState extends ConsumerState<AddRoutineItemDialog> {
  ActivityEntry? _selectedActivity;
  DateTime? _scheduledDate;
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studioState = ref.watch(selfCareNotifierProvider);
    final activities = studioState.activities;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n?.routinesAddItem ?? 'Add activity',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Activity Selection List
              Expanded(
                child: activities.isEmpty
                    ? Center(
                        child: Text(
                          'No activities available.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final act = activities[index];
                          final isSelected = _selectedActivity?.id == act.id;

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor:
                                  AppColors.lavender.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primaryPurple
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              title: Text(
                                act.title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                act.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              trailing: DecorativeBadge(
                                label: l10n?.selfCareDurationMinutes(
                                        act.durationMinutes) ??
                                    '${act.durationMinutes} min',
                                backgroundColor: AppColors.lavender,
                                textColor: AppColors.deepPurple,
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedActivity = act;
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFD32F2F),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n?.activityStepBack ?? 'Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : BloomButton(
                          label: l10n?.routinesAddItem ?? 'Add activity',
                          onPressed: _selectedActivity == null
                              ? null
                              : () async {
                                  final nav = Navigator.of(context);
                                  setState(() {
                                    _isSaving = true;
                                    _error = null;
                                  });
                                  try {
                                    await widget.onAdd(
                                      _selectedActivity!.id,
                                      _scheduledDate,
                                    );
                                    if (mounted) {
                                      nav.pop();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _isSaving = false;
                                        _error = e
                                            .toString()
                                            .replaceFirst('Exception: ', '');
                                      });
                                    }
                                  }
                                },
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
