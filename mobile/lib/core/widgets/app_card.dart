import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Reusable premium card widget with soft elevation, rounded corners,
/// and optional gradient background and tap interactions.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? customShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.backgroundColor = AppColors.cardSurface,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.onTap,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppSpacing.roundedLg;
    final effectiveBorderColor = borderColor ?? AppColors.borderLight;

    final shadows = customShadow ??
        const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16.0,
            offset: Offset(0, 6),
            spreadRadius: 0,
          ),
        ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: AppColors.primaryPurple.withValues(alpha: 0.12),
          highlightColor: AppColors.primaryPurple.withValues(alpha: 0.06),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: content,
      ),
    );
  }
}
