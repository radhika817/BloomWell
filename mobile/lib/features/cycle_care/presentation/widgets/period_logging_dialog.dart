import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cycle_care_notifier.dart';
import '../../domain/entities/cycle_period_entry.dart';

/// Cryptographically secure RFC-4122 v4 UUID generator for client_id idempotency.
String generateCycleClientId() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40; // version 4
  values[8] = (values[8] & 0x3f) | 0x80; // variant
  final hex = [
    for (int i = 0; i < 16; i++) values[i].toRadixString(16).padLeft(2, '0')
  ].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

/// Bottom sheet dialog for logging and editing menstrual periods with client-side
/// validations, computed duration, and retry-safe idempotency.
class PeriodLoggingSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final CyclePeriodEntry? existingEntry;

  const PeriodLoggingSheet({
    super.key,
    this.initialDate,
    this.existingEntry,
  });

  static Future<bool?> show(
    BuildContext context, {
    DateTime? initialDate,
    CyclePeriodEntry? existingEntry,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PeriodLoggingSheet(
        initialDate: initialDate,
        existingEntry: existingEntry,
      ),
    );
  }

  @override
  ConsumerState<PeriodLoggingSheet> createState() => _PeriodLoggingSheetState();
}

class _PeriodLoggingSheetState extends ConsumerState<PeriodLoggingSheet> {
  late final String _clientId;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isOngoing = false;
  String? _clientValidationError;

  @override
  void initState() {
    super.initState();
    _clientId = widget.existingEntry?.clientId ?? generateCycleClientId();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (widget.existingEntry != null) {
      final parsedStart = DateTime.tryParse(widget.existingEntry!.periodStart);
      _startDate = parsedStart ?? today;
      _endDate = widget.existingEntry!.periodEnd != null
          ? DateTime.tryParse(widget.existingEntry!.periodEnd!)
          : null;
      _isOngoing = widget.existingEntry!.isOngoing;
    } else {
      final init = widget.initialDate ?? today;
      _startDate = DateTime(init.year, init.month, init.day);
      if (_startDate.isAfter(today)) {
        _startDate = today;
      }
      _isOngoing = false;
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int? get _computedDuration {
    if (_endDate == null) return null;
    final diff = _endDate!.difference(_startDate).inDays;
    return diff >= 0 ? diff + 1 : null;
  }

  bool _validate(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_startDate.isAfter(today)) {
      setState(() {
        _clientValidationError = l10n.cycleErrorFutureDate;
      });
      return false;
    }

    if (!_isOngoing && _endDate != null) {
      if (_endDate!.isAfter(today)) {
        setState(() {
          _clientValidationError = l10n.cycleErrorFutureDate;
        });
        return false;
      }

      if (_endDate!.isBefore(_startDate)) {
        setState(() {
          _clientValidationError = l10n.cycleErrorInvalidRange;
        });
        return false;
      }
    }

    // Overlap validation with existing periods
    final state = ref.read(cycleCareNotifierProvider);
    final normStart =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final normEnd = _isOngoing || _endDate == null
        ? today
        : DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    for (final other in state.monthCycles) {
      if (widget.existingEntry != null &&
          other.id == widget.existingEntry!.id) {
        continue;
      }
      final otherStart = DateTime.tryParse(other.periodStart);
      if (otherStart == null) continue;
      final normOtherStart =
          DateTime(otherStart.year, otherStart.month, otherStart.day);

      DateTime normOtherEnd;
      if (other.periodEnd != null) {
        final otherEnd = DateTime.tryParse(other.periodEnd!);
        if (otherEnd == null) continue;
        normOtherEnd = DateTime(otherEnd.year, otherEnd.month, otherEnd.day);
      } else {
        normOtherEnd = today;
      }

      // Check overlap: start1 <= end2 && end1 >= start2
      if (!normEnd.isBefore(normOtherStart) &&
          !normStart.isAfter(normOtherEnd)) {
        setState(() {
          _clientValidationError = l10n.cycleErrorOverlap;
        });
        return false;
      }
    }

    setState(() {
      _clientValidationError = null;
    });
    return true;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        _clientValidationError = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: _startDate,
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
        _isOngoing = false;
        _clientValidationError = null;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validate(l10n)) return;

    final notifier = ref.read(cycleCareNotifierProvider.notifier);
    final effectiveEnd = _isOngoing ? null : _endDate;

    bool success;
    if (widget.existingEntry != null) {
      success = await notifier.updatePeriod(
        id: widget.existingEntry!.id,
        startDate: _startDate,
        endDate: effectiveEnd,
      );
    } else {
      success = await notifier.logPeriod(
        clientId: _clientId,
        startDate: _startDate,
        endDate: effectiveEnd,
      );
    }

    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(cycleCareNotifierProvider);
    final duration = _computedDuration;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                          color: AppColors.blushPink,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.softRose.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.existingEntry != null
                              ? l10n.cycleEditPeriodTitle
                              : l10n.cycleLogPeriodTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.deepPurple,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('cycle_period_close_button'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Validation error banner if any
                  if (_clientValidationError != null ||
                      state.errorMessage != null) ...[
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
                              _clientValidationError ??
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

                  // Start Date Picker Row
                  Text(
                    l10n.cycleStartDateLabel,
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    key: const Key('cycle_period_start_date_picker'),
                    onTap: _pickStartDate,
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
                            _formatDate(_startDate),
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

                  // Ongoing Checkbox Toggle
                  CheckboxListTile(
                    key: const Key('cycle_period_ongoing_checkbox'),
                    value: _isOngoing,
                    activeColor: AppColors.primaryPurple,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.cycleHistoryOngoing,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _isOngoing = val ?? false;
                        if (_isOngoing) {
                          _endDate = null;
                        }
                        _clientValidationError = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // End Date Picker Row (if not ongoing)
                  if (!_isOngoing) ...[
                    Text(
                      l10n.cycleEndDateLabel,
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      key: const Key('cycle_period_end_date_picker'),
                      onTap: _pickEndDate,
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
                              _endDate != null
                                  ? _formatDate(_endDate!)
                                  : 'Not specified',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _endDate != null
                                    ? AppColors.primaryText
                                    : AppColors.mutedText,
                                fontWeight: _endDate != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Computed Duration Pill
                  if (duration != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timelapse_rounded,
                            size: 16,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.cycleHistoryCycleLength(duration),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

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
                      key: const Key('cycle_period_save_button'),
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
