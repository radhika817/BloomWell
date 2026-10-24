import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cycle_care_notifier.dart';
import '../../domain/entities/cycle_estimate.dart';
import '../../domain/entities/cycle_period_entry.dart';
import '../../domain/entities/cycle_symptom_entry.dart';

/// Month calendar grid and accessible list view for CycleCare.
/// Features non-color visual cues:
/// - Logged period: water drop icon and solid border
/// - Symptom logged: dot indicator
/// - Estimated window: distinct dashed border and "estimate" label
/// - Today indicator: subtle highlight circle
/// - Accessible list view alternative toggle
class CycleMonthCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final CalendarViewMode viewMode;
  final List<CyclePeriodEntry> monthCycles;
  final List<CycleSymptomEntry> monthSymptoms;
  final CycleEstimate? estimate;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToggleViewMode;

  const CycleMonthCalendar({
    super.key,
    required this.selectedMonth,
    required this.selectedDate,
    required this.viewMode,
    required this.monthCycles,
    required this.monthSymptoms,
    required this.estimate,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToggleViewMode,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDayInPeriod(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final cycle in monthCycles) {
      final start = DateTime.tryParse(cycle.periodStart);
      if (start == null) continue;
      final normalizedStart = DateTime(start.year, start.month, start.day);

      DateTime normalizedEnd;
      if (cycle.periodEnd != null) {
        final end = DateTime.tryParse(cycle.periodEnd!);
        if (end == null) continue;
        normalizedEnd = DateTime(end.year, end.month, end.day);
      } else {
        // Ongoing period
        final now = DateTime.now();
        normalizedEnd = DateTime(now.year, now.month, now.day);
      }

      if (!target.isBefore(normalizedStart) && !target.isAfter(normalizedEnd)) {
        return true;
      }
    }
    return false;
  }

  bool _isDayInEstimate(DateTime day) {
    if (estimate == null ||
        estimate!.status != CycleEstimateStatus.estimate ||
        estimate!.estimatedRangeStart == null ||
        estimate!.estimatedRangeEnd == null) {
      return false;
    }

    final start = DateTime.tryParse(estimate!.estimatedRangeStart!);
    final end = DateTime.tryParse(estimate!.estimatedRangeEnd!);
    if (start == null || end == null) return false;

    final target = DateTime(day.year, day.month, day.day);
    final normStart = DateTime(start.year, start.month, start.day);
    final normEnd = DateTime(end.year, end.month, end.day);

    return !target.isBefore(normStart) && !target.isAfter(normEnd);
  }

  List<CycleSymptomEntry> _getSymptomsForDay(DateTime day) {
    final dayStr = _formatDate(day);
    return monthSymptoms.where((s) => s.date == dayStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthTitle =
        '${_monthNames[selectedMonth.month - 1]} ${selectedMonth.year}';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month navigation header
          Row(
            children: [
              IconButton(
                key: const Key('cycle_cal_prev_month'),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.deepPurple,
                tooltip: l10n.cycleCalendarPrevMonth,
                onPressed: onPreviousMonth,
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: const Key('cycle_cal_next_month'),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.deepPurple,
                tooltip: l10n.cycleCalendarNextMonth,
                onPressed: onNextMonth,
              ),
              IconButton(
                key: const Key('cycle_cal_view_toggle'),
                icon: Icon(
                  viewMode == CalendarViewMode.grid
                      ? Icons.view_agenda_outlined
                      : Icons.grid_view_rounded,
                ),
                color: AppColors.primaryPurple,
                tooltip: viewMode == CalendarViewMode.grid
                    ? l10n.cycleSwitchToListView
                    : l10n.cycleSwitchToGridView,
                onPressed: onToggleViewMode,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Calendar Grid or List View
          if (viewMode == CalendarViewMode.grid)
            _buildMonthGrid(context, l10n)
          else
            _buildMonthListView(context, l10n),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),

          // Visual Legend
          _buildLegend(l10n),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, AppLocalizations l10n) {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(selectedMonth.year, selectedMonth.month, 1).weekday;
    // Monday-first: Monday=1 -> offset 0; Sunday=7 -> offset 6
    final startOffset = firstWeekday - 1;

    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays.map((w) {
            return SizedBox(
              width: 36,
              height: 24,
              child: Center(
                child: Text(
                  w,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Grid cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - startOffset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final day = DateTime(
              selectedMonth.year,
              selectedMonth.month,
              dayNumber,
            );
            final isToday = _isSameDay(day, now);
            final isSelected =
                selectedDate != null && _isSameDay(day, selectedDate!);
            final isPeriod = _isDayInPeriod(day);
            final isEstimate = _isDayInEstimate(day);
            final symptoms = _getSymptomsForDay(day);

            return _CalendarDayCell(
              day: day,
              dayNumber: dayNumber,
              isToday: isToday,
              isSelected: isSelected,
              isPeriod: isPeriod,
              isEstimate: isEstimate,
              symptomsCount: symptoms.length,
              onTap: () => onDaySelected(day),
              l10n: l10n,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthListView(BuildContext context, AppLocalizations l10n) {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: daysInMonth,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.borderLight),
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final day = DateTime(
          selectedMonth.year,
          selectedMonth.month,
          dayNumber,
        );
        final isToday = _isSameDay(day, now);
        final isSelected =
            selectedDate != null && _isSameDay(day, selectedDate!);
        final isPeriod = _isDayInPeriod(day);
        final isEstimate = _isDayInEstimate(day);
        final symptoms = _getSymptomsForDay(day);

        final semanticParts = <String>[
          '${_monthNames[day.month - 1]} $dayNumber',
          if (isToday) 'Today',
          if (isPeriod) l10n.cycleDayPeriodLogged,
          if (isEstimate) l10n.cycleDayEstimateWindow,
          if (symptoms.isNotEmpty) '${symptoms.length} symptoms logged',
        ];

        return Semantics(
          label: semanticParts.join(', '),
          button: true,
          child: InkWell(
            key: Key('cycle_day_list_$dayNumber'),
            onTap: () => onDaySelected(day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48.0),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.lavender.withValues(alpha: 0.6)
                    : (isPeriod
                        ? AppColors.blushPink.withValues(alpha: 0.5)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primaryPurple, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? AppColors.primaryPurple.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: AppTypography.titleSmall.copyWith(
                        color: isToday
                            ? AppColors.primaryPurple
                            : AppColors.primaryText,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isPeriod)
                          _ListBadge(
                            icon: Icons.water_drop_rounded,
                            label: l10n.cycleLegendLogged,
                            color: AppColors.softRose,
                            textColor: AppColors.deepPurple,
                          ),
                        if (isEstimate)
                          _ListBadge(
                            icon: Icons.access_time_rounded,
                            label: l10n.cycleLegendEstimate,
                            color: AppColors.lavender,
                            textColor: AppColors.deepPurple,
                            isDashed: true,
                          ),
                        if (symptoms.isNotEmpty)
                          _ListBadge(
                            icon: Icons.circle,
                            iconSize: 8,
                            label: '${symptoms.length} symptoms',
                            color: AppColors.mint,
                            textColor: AppColors.deepPurple,
                          ),
                        if (!isPeriod && !isEstimate && symptoms.isEmpty)
                          Text(
                            l10n.cycleDayNoLogs,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _LegendItem(
          visual: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.blushPink,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.softRose, width: 1.5),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 9,
              color: AppColors.deepPurple,
            ),
          ),
          label: l10n.cycleLegendLogged,
        ),
        _LegendItem(
          visual: CustomPaint(
            size: const Size(14, 14),
            painter: _DashedCirclePainter(
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.lavender.withValues(alpha: 0.5),
            ),
          ),
          label: l10n.cycleLegendEstimate,
        ),
        _LegendItem(
          visual: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          label: l10n.cycleLegendSymptoms,
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final int dayNumber;
  final bool isToday;
  final bool isSelected;
  final bool isPeriod;
  final bool isEstimate;
  final int symptomsCount;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _CalendarDayCell({
    required this.day,
    required this.dayNumber,
    required this.isToday,
    required this.isSelected,
    required this.isPeriod,
    required this.isEstimate,
    required this.symptomsCount,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final semanticParts = <String>[
      'Day $dayNumber',
      if (isToday) 'Today',
      if (isPeriod) l10n.cycleDayPeriodLogged,
      if (isEstimate) l10n.cycleDayEstimateWindow,
      if (symptomsCount > 0) '$symptomsCount symptoms logged',
      if (isSelected) 'Selected',
    ];

    Widget content = InkWell(
      key: Key('cycle_day_grid_$dayNumber'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Period water drop indicator behind number
            if (isPeriod)
              Positioned(
                top: 4,
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 16,
                  color: AppColors.softRose.withValues(alpha: 0.9),
                ),
              ),

            // Day number with Today ring
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: AppColors.primaryPurple, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight:
                      isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isPeriod
                      ? AppColors.primaryText
                      : (isToday
                          ? AppColors.primaryPurple
                          : AppColors.primaryText),
                ),
              ),
            ),

            // Symptom dot indicators at bottom
            if (symptomsCount > 0)
              Positioned(
                bottom: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    symptomsCount.clamp(1, 3),
                    (i) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Apply dashed border for estimates or solid for period / selected
    BoxDecoration? decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple, width: 2.0),
      );
    } else if (isPeriod) {
      decoration = BoxDecoration(
        color: AppColors.blushPink.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softRose, width: 1.5),
      );
    }

    if (isEstimate && !isPeriod && !isSelected) {
      return Semantics(
        label: semanticParts.join(', '),
        button: true,
        child: CustomPaint(
          painter: _DashedRectPainter(
            color: AppColors.primaryPurple,
            backgroundColor: AppColors.lavender.withValues(alpha: 0.35),
            radius: 12,
          ),
          child: content,
        ),
      );
    }

    return Semantics(
      label: semanticParts.join(', '),
      button: true,
      child: Container(
        decoration: decoration,
        child: content,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Widget visual;
  final String label;

  const _LegendItem({
    required this.visual,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        visual,
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ListBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final Color color;
  final Color textColor;
  final bool isDashed;

  const _ListBadge({
    required this.icon,
    this.iconSize = 14,
    required this.label,
    required this.color,
    required this.textColor,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isDashed
            ? Border.all(
                color: AppColors.primaryPurple,
                width: 1.0,
                style: BorderStyle.solid,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return body;
  }
}

/// Custom painter for dashed rounded rectangle around estimated cycle windows.
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.backgroundColor,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    // Fill background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Draw dashed border path
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      const dashLength = 4.0;
      const spaceLength = 3.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.radius != radius;
  }
}

/// Custom painter for dashed circle in legend.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;

  _DashedCirclePainter({
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 2) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      const dashLength = 3.0;
      const spaceLength = 2.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
