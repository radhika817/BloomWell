import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Circular pastel emoji bubble with active selection glow
/// and accessible semantics.
class MoodBubble extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final Color bubbleColor;
  final double diameter;

  const MoodBubble({
    super.key,
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    this.bubbleColor = AppColors.lavender,
    this.diameter = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label mood',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: diameter,
                  height: diameter,
                  constraints:
                      const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bubbleColor,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : Colors.white.withValues(alpha: 0.9),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: AppColors.shadowMedium
                                  .withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize: diameter * 0.44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.deepPurple
                        : AppColors.secondaryText,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
