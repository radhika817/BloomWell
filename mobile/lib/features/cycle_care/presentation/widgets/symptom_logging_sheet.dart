import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cycle_care_notifier.dart';
import '../../domain/entities/cycle_symptom_entry.dart';
import 'cycle_day_sheet.dart';
import 'period_logging_dialog.dart';

/// Bottom sheet for logging and editing cycle symptoms with neutral 1-5 severity scale,
/// gentle clinic prompt for strong/very strong sensations, live 500-char notes counter,
/// and retry-safe client_id idempotency.
class SymptomLoggingSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final CycleSymptomEntry? existingEntry;

  const SymptomLoggingSheet({
    super.key,
    this.initialDate,
    this.existingEntry,
  });

  static Future<bool?> show(
    BuildContext context, {
    DateTime? initialDate,
    CycleSymptomEntry? existingEntry,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SymptomLoggingSheet(
        initialDate: initialDate,
        existingEntry: existingEntry,
      ),
    );
  }

  @override
  ConsumerState<SymptomLoggingSheet> createState() =>
      _SymptomLoggingSheetState();
}

class _SymptomLoggingSheetState extends ConsumerState<SymptomLoggingSheet> {
  late final String _clientId;
  late DateTime _date;
  late CycleSymptomType _selectedType;
  late int _severity;
  late final TextEditingController _customLabelController;
  late final TextEditingController _notesController;
  String? _clientError;

  @override
  void initState() {
    super.initState();
    _clientId = widget.existingEntry?.clientId ?? generateCycleClientId();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (widget.existingEntry != null) {
      final parsed = DateTime.tryParse(widget.existingEntry!.date);
      _date = parsed ?? today;
      _selectedType = widget.existingEntry!.symptomType;
      _severity = widget.existingEntry!.severity;
      _customLabelController =
          TextEditingController(text: widget.existingEntry!.customLabel ?? '');
      _notesController =
          TextEditingController(text: widget.existingEntry!.notes ?? '');
    } else {
      final init = widget.initialDate ?? today;
      _date = DateTime(init.year, init.month, init.day);
      if (_date.isAfter(today)) {
        _date = today;
      }
      _selectedType = CycleSymptomType.cramps;
      _severity = 2; // neutral mild
      _customLabelController = TextEditingController();
      _notesController = TextEditingController();
    }

    _notesController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _getSeverityName(int severity, AppLocalizations l10n) {
    switch (severity) {
      case 1:
        return l10n.cycleSeverity1;
      case 2:
        return l10n.cycleSeverity2;
      case 3:
        return l10n.cycleSeverity3;
      case 4:
        return l10n.cycleSeverity4;
      case 5:
        return l10n.cycleSeverity5;
      default:
        return l10n.cycleSeverity2;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
        _clientError = null;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_date.isAfter(today)) {
      setState(() {
        _clientError = l10n.cycleErrorFutureDate;
      });
      return;
    }

    final customLabel = _selectedType == CycleSymptomType.other
        ? _customLabelController.text.trim()
        : null;

    final notes = _notesController.text.trim();

    final notifier = ref.read(cycleCareNotifierProvider.notifier);
    final success = await notifier.logSymptom(
      clientId: _clientId,
      date: _date,
      symptomType: _selectedType,
      severity: _severity,
      customLabel:
          customLabel != null && customLabel.isNotEmpty ? customLabel : null,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(cycleCareNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final notesLength = _notesController.text.length;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.existingEntry != null
                              ? l10n.cycleEditSymptomTitle
                              : l10n.cycleLogSymptomTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.deepPurple,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('cycle_symptom_close_button'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Error Banner
                  if (_clientError != null || state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blushPink,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.softRose.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.deepPurple,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _clientError ??
                                  state.errorMessage ??
                                  l10n.cycleErrorInvalidRange,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Date Picker Field
                  Text(
                    l10n.cycleSymptomDateLabel,
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    key: const Key('cycle_symptom_date_picker'),
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(_date),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Symptom Type Chips (12 types)
                  Text(
                    l10n.cycleSymptomTypeLabel,
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CycleSymptomType.values.map((type) {
                      final isSelected = _selectedType == type;
                      final typeName = getLocalizedSymptomName(type, l10n);

                      return ChoiceChip(
                        key: Key('cycle_symptom_chip_${type.apiValue}'),
                        label: Text(typeName),
                        selected: isSelected,
                        selectedColor: AppColors.primaryPurple,
                        backgroundColor: Colors.white,
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.primaryText,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.borderLight,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Custom Label Input if type == other
                  if (_selectedType == CycleSymptomType.other) ...[
                    Text(
                      l10n.cycleCustomLabelLabel,
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('cycle_custom_label_input'),
                      controller: _customLabelController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        hintText: l10n.cycleCustomLabelPlaceholder,
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Neutral Severity Scale (1 - 5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cycleSeverityLabel(
                              _getSeverityName(_severity, l10n)),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$_severity / 5',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 1-5 Segmented Pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final score = index + 1;
                      final isSelected = _severity == score;

                      return InkWell(
                        key: Key('cycle_severity_pill_$score'),
                        onTap: () {
                          setState(() {
                            _severity = score;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 50,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$score',
                            style: AppTypography.titleSmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryText,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Gentle clinic advice prompt when severity is 4 or 5
                  if (_severity >= 4) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.cycleSeverityDisclaimer,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Notes Field with Live Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cycleNotesLabel,
                          style: AppTypography.labelMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.cycleNotesCounter(notesLength),
                        style: AppTypography.labelSmall.copyWith(
                          color: notesLength > 500
                              ? const Color(0xFFC2415E)
                              : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('cycle_symptom_notes_input'),
                    controller: _notesController,
                    onChanged: (_) => setState(() {}),
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.cycleNotesPlaceholder,
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Save Button
                  if (state.isActionLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    BloomButton(
                      key: const Key('cycle_symptom_save_button'),
                      label: l10n.cycleSaveButton,
                      variant: BloomButtonVariant.primary,
                      isExpanded: true,
                      onPressed: _save,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
