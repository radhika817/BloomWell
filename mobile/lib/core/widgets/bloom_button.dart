import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum BloomButtonVariant { primary, secondary, subtle }

/// Reusable feminine rounded button with subtle animations and tactile feedback.
class BloomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? emoji;
  final BloomButtonVariant variant;
  final bool isExpanded;
  final double height;

  const BloomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emoji,
    this.variant = BloomButtonVariant.primary,
    this.isExpanded = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (variant) {
      case BloomButtonVariant.primary:
        backgroundColor = AppColors.primaryPurple;
        foregroundColor = Colors.white;
        border = null;
        break;
      case BloomButtonVariant.secondary:
        backgroundColor = AppColors.lavender;
        foregroundColor = AppColors.deepPurple;
        border = const BorderSide(color: AppColors.borderSubtle, width: 1.0);
        break;
      case BloomButtonVariant.subtle:
        backgroundColor = Colors.white;
        foregroundColor = AppColors.primaryText;
        border = const BorderSide(color: AppColors.borderLight, width: 1.0);
        break;
    }

    Widget content = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return SizedBox(
      height: height,
      width: isExpanded ? double.infinity : null,
      child: Material(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedPill,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.roundedPill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedPill,
              border: border != null ? Border.fromBorderSide(border) : null,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
