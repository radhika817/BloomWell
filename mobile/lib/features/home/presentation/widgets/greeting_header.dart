import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/decorative_badge.dart';

/// Top greeting header on the BloomWell Home screen.
class GreetingHeader extends StatelessWidget {
  final VoidCallback? onDiscreetToggle;

  const GreetingHeader({
    super.key,
    this.onDiscreetToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hey, lovely! 🌷',
                        style: AppTypography.display.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Take a little moment for yourself.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDiscreetToggle,
              child: const DecorativeBadge(
                label: 'Discreet',
                icon: Icons.shield_outlined,
                backgroundColor: AppColors.blushPink,
                textColor: AppColors.deepPurple,
                borderColor: AppColors.borderSubtle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
