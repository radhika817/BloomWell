import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/routine.dart';

/// Dialog for creating or editing a gentle routine.
class CreateEditRoutineDialog extends StatefulWidget {
  final Routine? routine;
  final Future<void> Function(
    String title,
    DateTime? startDate,
    DateTime? endDate,
  ) onSave;

  const CreateEditRoutineDialog({
    super.key,
    this.routine,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Routine? routine,
    required Future<void> Function(
      String title,
      DateTime? startDate,
      DateTime? endDate,
    ) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CreateEditRoutineDialog(
        routine: routine,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CreateEditRoutineDialog> createState() =>
      _CreateEditRoutineDialogState();
}

class _CreateEditRoutineDialogState extends State<CreateEditRoutineDialog> {
  late final TextEditingController _titleController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine?.title ?? '');
    _startDate = widget.routine?.startDate;
    _endDate = widget.routine?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = 'Please enter a routine title.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(title, _startDate, _endDate);
      if (mounted) {
        Navigator.of(context).pop();
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
    final isEditing = widget.routine != null;

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
                    ? (l10n?.routinesEditTitle ?? 'Edit Routine')
                    : (l10n?.routinesCreateTitle ?? 'Create Routine'),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title Field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n?.routinesTitleField ?? 'Routine Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date Pickers Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        _startDate != null
                            ? _formatDate(_startDate!)
                            : (l10n?.routinesStartDateField ?? 'Start Date'),
                        style: AppTypography.bodySmall,
                      ),
                      onPressed: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        _endDate != null
                            ? _formatDate(_endDate!)
                            : (l10n?.routinesEndDateField ?? 'End Date'),
                        style: AppTypography.bodySmall,
                      ),
                      onPressed: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
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
                          label: l10n?.routinesSaveButton ?? 'Save Routine',
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
