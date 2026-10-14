import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Small decorative tag / badge with icon and label in gentle pastel coloring.
class DecorativeBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const DecorativeBadge({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.backgroundColor = AppColors.lavender,
    this.textColor = AppColors.deepPurple,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedPill,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.0)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(
              emoji!,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: AppSpacing.xs),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: textColor,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
