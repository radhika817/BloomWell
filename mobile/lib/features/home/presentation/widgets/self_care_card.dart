import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/decorative_badge.dart';

/// Individual self-care routine card with distinct pastel theme and icon.
class SelfCareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String badgeText;
  final Color pastelBackground;
  final Color accentColor;
  final VoidCallback onTap;

  const SelfCareCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.badgeText,
    required this.pastelBackground,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: Colors.white,
      borderColor: AppColors.borderLight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pastelBackground,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              DecorativeBadge(
                label: badgeText,
                backgroundColor: pastelBackground,
                textColor: AppColors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
