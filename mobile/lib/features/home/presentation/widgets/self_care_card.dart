import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/soft_card.dart';

/// Individual self-care routine card with distinct pastel theme,
/// soft card elevation, and responsive typography.
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
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: pastelBackground,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: DecorativeBadge(
                    label: badgeText,
                    backgroundColor: pastelBackground,
                    textColor: AppColors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
