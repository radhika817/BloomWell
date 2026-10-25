import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/academic_events_notifier.dart';
import '../../domain/entities/academic_event.dart';
import '../../domain/entities/academic_event_type.dart';
import 'add_edit_exam_dialog.dart';

/// Interactive card for an academic event with neutral pacing ("in X days"),
/// strictly avoiding stress-inducing countdowns or exclamation marks.
class ExamEventCard extends ConsumerWidget {
  final AcademicEvent event;

  const ExamEventCard({
    super.key,
    required this.event,
  });

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _typeLabel(AcademicEventType type, AppLocalizations? l10n) {
    switch (type) {
      case AcademicEventType.exam:
        return l10n?.examsTypeExam ?? 'Exam';
      case AcademicEventType.assignment:
        return l10n?.examsTypeAssignment ?? 'Assignment';
      case AcademicEventType.presentation:
        return l10n?.examsTypePresentation ?? 'Presentation';
      case AcademicEventType.other:
        return l10n?.examsTypeOther ?? 'Other';
    }
  }

  Color _typePastelColor(AcademicEventType type) {
    switch (type) {
      case AcademicEventType.exam:
        return const Color(0xFFFFECE2);
      case AcademicEventType.assignment:
        return AppColors.softSky;
      case AcademicEventType.presentation:
        return AppColors.lavender;
      case AcademicEventType.other:
        return AppColors.mint;
    }
  }

  String _pacingText(AcademicEvent event, AppLocalizations? l10n) {
    final diff = event.daysDifferenceFromToday;
    if (diff == 0) {
      return l10n?.examsToday ?? 'today';
    } else if (diff == 1) {
      return l10n?.examsInOneDay ?? 'tomorrow';
    } else if (diff > 1) {
      return l10n?.examsInDays(diff) ?? 'in $diff days';
    } else {
      final pastDays = diff.abs();
      return l10n?.examsDaysAgo(pastDays) ?? '$pastDays days ago';
    }
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
          l10n?.examsDeleteButton ?? 'Delete',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          l10n?.examsDeleteConfirm ??
              'Are you sure you want to delete this event?',
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
                  .read(academicEventsNotifierProvider.notifier)
                  .deleteEvent(event.id);
            },
            child: Text(
              l10n?.examsDeleteButton ?? 'Delete',
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
    final notifier = ref.read(academicEventsNotifierProvider.notifier);
    final typeLabel = _typeLabel(event.eventType, l10n);
    final typeColor = _typePastelColor(event.eventType);
    final pacingText = _pacingText(event, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DecorativeBadge(
                            label: typeLabel,
                            backgroundColor: typeColor,
                            textColor: AppColors.deepPurple,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          DecorativeBadge(
                            label: pacingText,
                            backgroundColor:
                                AppColors.lavender.withValues(alpha: 0.5),
                            textColor: AppColors.deepPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(event.eventDate),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.secondaryText,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      AddEditExamDialog.show(
                        context,
                        event: event,
                        onSave: (clientId, title, date, type) async {
                          await notifier.updateEvent(
                            id: event.id,
                            title: title,
                            eventDate: date,
                            eventType: type,
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
                      child: Text(l10n?.examsEditTitle ?? 'Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n?.examsDeleteButton ?? 'Delete',
                        style: const TextStyle(color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
