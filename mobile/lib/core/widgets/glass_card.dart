import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Frosted translucent card widget with blurred background,
/// thin white borders, and an accessible high-contrast fallback.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double blurSigma;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.radius = 24.0,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.blurSigma = 16.0,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = MediaQuery.highContrastOf(context);
    final borderRadius = BorderRadius.circular(radius);

    // Fallback to solid opaque card when high contrast is active
    if (isHighContrast) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor ?? AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: shadows ??
              const [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    final effectiveBgColor = backgroundColor ?? AppColors.glassBackground;
    final effectiveBorderColor = borderColor ?? AppColors.glassBorder;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: AppColors.shadowMedium.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: borderRadius,
              border: Border.all(
                color: effectiveBorderColor,
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
