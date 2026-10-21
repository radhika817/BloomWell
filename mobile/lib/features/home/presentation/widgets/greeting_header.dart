import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_mascot.dart';
import '../../../../l10n/app_localizations.dart';

/// Top bar and greeting header on the BloomWell Home screen
/// featuring avatar monogram, notification bell, discreet toggle,
/// and cute mascot companion.
class GreetingHeader extends StatelessWidget {
  final VoidCallback onDiscreetToggle;
  final VoidCallback onNotificationTap;
  final VoidCallback? onQuickHide;

  const GreetingHeader({
    super.key,
    required this.onDiscreetToggle,
    required this.onNotificationTap,
    this.onQuickHide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top action bar with Avatar, Notifications, and Discreet Mode
        Row(
          children: [
            // Avatar Placeholder (circular pastel monogram)
            Semantics(
              label: 'User profile avatar',
              child: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lavender,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    l10n?.avatarInitials ?? 'BW',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Notification Bell with unread dot
            Semantics(
              button: true,
              label: l10n?.notificationsTitle ?? 'Notifications',
              child: Stack(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.0,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primaryText,
                        size: 22.0,
                      ),
                      onPressed: onNotificationTap,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onQuickHide != null) ...[
              const SizedBox(width: 8.0),
              Semantics(
                button: true,
                label: l10n?.quickHideSemanticsLabel ?? 'Quick hide screen',
                child: Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1.0,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.visibility_off_outlined,
                      color: AppColors.primaryText,
                      size: 20.0,
                    ),
                    tooltip: l10n?.quickHideHeading ?? 'Quick-Hide',
                    onPressed: onQuickHide,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8.0),

            // Discreet Mode pill button
            Semantics(
              button: true,
              label: l10n?.discreetBadge ?? 'Discreet mode information',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100.0),
                  onTap: onDiscreetToggle,
                  child: Container(
                    height: 44.0,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(100.0),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 16.0,
                          color: AppColors.deepPurple,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          l10n?.discreetBadge ?? 'Discreet',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.deepPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // Greeting Header with Bloomie Mascot
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.homeGreeting ?? 'Hey, lovely! 🌷',
                    style: AppTypography.display.copyWith(
                      fontSize: 27.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    l10n?.homeSubtitle ?? 'Take a little moment for yourself.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 15.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            const BloomMascot(size: 68.0),
          ],
        ),
      ],
    );
  }
}
