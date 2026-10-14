import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Segmented pill control supporting 2 or 3 options with smooth
/// animated indicator and soft rounded styling.
class SegmentedPill<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;

  const SegmentedPill({
    super.key,
    required this.values,
    required this.labels,
    required this.selectedValue,
    required this.onValueChanged,
  }) : assert(values.length == labels.length && values.length >= 2);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(100.0);

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(values.length, (index) {
          final value = values[index];
          final label = labels[index];
          final isSelected = value == selectedValue;

          return Semantics(
            button: true,
            selected: isSelected,
            label: label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: () => onValueChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 40.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.ctaGradient : null,
                    borderRadius: borderRadius,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.ctaShadow.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color:
                            isSelected ? Colors.white : AppColors.secondaryText,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
