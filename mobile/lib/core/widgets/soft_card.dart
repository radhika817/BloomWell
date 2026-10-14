import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Solid white card with rounded friendly corners, subtle border,
/// and gentle elevation for high readability and structured layouts.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.radius = 22.0,
    this.backgroundColor = Colors.white,
    this.borderColor = AppColors.softCardBorder,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: AppColors.shadowMedium.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
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
}
