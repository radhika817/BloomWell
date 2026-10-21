import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_background.dart';
import '../../../../core/widgets/bloom_mascot.dart';

/// Full-screen neutral privacy cover displayed during app switcher transitions
/// or when Quick-Hide is triggered without an active PIN lock.
///
/// Strictly conceals all private health reflections, charts, and journal notes.
class PrivacyCoverWidget extends StatelessWidget {
  const PrivacyCoverWidget({
    super.key,
    this.onTapToDismiss,
    this.canDismissOnTap = false,
  });

  final VoidCallback? onTapToDismiss;
  final bool canDismissOnTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BloomWell Privacy Screen',
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: canDismissOnTap ? onTapToDismiss : null,
          child: BloomBackground(
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BloomMascot(size: 96),
                    const SizedBox(height: 20),
                    Text(
                      'BloomWell',
                      style: AppTypography.display.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🌸 · ☁️ · 🤍 · 🌙 · ✨',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 4,
                      ),
                    ),
                    if (canDismissOnTap) ...[
                      const SizedBox(height: 36),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'Tap anywhere to resume',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
