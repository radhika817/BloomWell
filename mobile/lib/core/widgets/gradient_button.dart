import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Pill-shaped CTA button with a vibrant purple gradient,
/// soft purple glow shadow, and responsive touch feedback.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final double height;
  final TextStyle? textStyle;
  final Gradient gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
    this.height = 52.0,
    this.textStyle,
    this.gradient = AppColors.ctaGradient,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(100.0);
    final isEnabled = onPressed != null;

    final content = Container(
      height: height,
      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : AppColors.borderSubtle,
        borderRadius: borderRadius,
        boxShadow: isEnabled
            ? [
                const BoxShadow(
                  color: AppColors.ctaShadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8.0),
                ],
                Text(
                  label,
                  style: textStyle ??
                      AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: isExpanded
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }
}
