import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/academic_event.dart';
import '../../domain/entities/academic_event_type.dart';

/// Dialog to create or edit an academic milestone or deadline.
/// Employs client_id idempotency to prevent duplicated events on retry.
class AddEditExamDialog extends StatefulWidget {
  final AcademicEvent? event;
  final Future<void> Function(
    String clientId,
    String title,
    DateTime eventDate,
    AcademicEventType eventType,
  ) onSave;

  const AddEditExamDialog({
    super.key,
    this.event,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    AcademicEvent? event,
    required Future<void> Function(
      String clientId,
      String title,
      DateTime eventDate,
      AcademicEventType eventType,
    ) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddEditExamDialog(
        event: event,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditExamDialog> createState() => _AddEditExamDialogState();
}

class _AddEditExamDialogState extends State<AddEditExamDialog> {
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  late AcademicEventType _selectedType;
  late final String _clientId;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _selectedDate = widget.event?.eventDate ?? DateTime.now();
    _selectedType = widget.event?.eventType ?? AcademicEventType.exam;
    _clientId = widget.event?.clientId ?? generateUuidV4();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = 'Please enter a title.';
      });
      return;
    }
    if (title.length > 80) {
      setState(() {
        _error = 'Title must be 80 characters or less.';
      });
      return;
    }

    final nav = Navigator.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        _clientId,
        title,
        _selectedDate,
        _selectedType,
      );
      if (mounted) {
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.event != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? (l10n?.examsEditTitle ?? 'Edit Academic Event')
                    : (l10n?.examsCreateTitle ?? 'Add Academic Event'),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title Field (Max 80)
              TextField(
                controller: _titleController,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l10n?.examsTitleLabel ?? 'Title (max 80 chars)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Date Picker Field
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  '${l10n?.examsDateLabel ?? 'Event Date'}: ${_formatDate(_selectedDate)}',
                  style: AppTypography.bodySmall,
                ),
                onPressed: _pickDate,
              ),
              const SizedBox(height: AppSpacing.md),

              // Event Type Selector
              Text(
                l10n?.examsTypeLabel ?? 'Event Type',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: AcademicEventType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(_typeLabel(type, l10n)),
                    selected: isSelected,
                    selectedColor: AppColors.lavender,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                        });
                      }
                    },
                  );
                }).toList(),
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

              const SizedBox(height: AppSpacing.lg),

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
                          label: l10n?.examsSaveButton ?? 'Save Event',
                          onPressed: _handleSave,
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
