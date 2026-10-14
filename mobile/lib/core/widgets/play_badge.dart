import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Circular or rounded pill gradient badge indicating playable/interactive content.
class PlayBadge extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const PlayBadge({
    super.key,
    this.size = 44.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.ctaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.ctaShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
