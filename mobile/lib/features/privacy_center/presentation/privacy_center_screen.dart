import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_button.dart';
import '../../../core/widgets/decorative_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_lock/application/app_lock_notifier.dart';
import '../../app_lock/domain/app_lock_config.dart';

/// Privacy Center settings page at `/profile/privacy`.
class PrivacyCenterScreen extends ConsumerStatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  ConsumerState<PrivacyCenterScreen> createState() =>
      _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends ConsumerState<PrivacyCenterScreen> {
  Future<void> _showDisableLockDialog() async {
    final l10n = AppLocalizations.of(context);
    final pinController = TextEditingController();
    String? errorText;

    final disabled = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              l10n?.disableLockDialogTitle ?? 'Turn Off App Lock',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.disableLockDialogBody ??
                      'Please enter your current PIN to turn off app lock.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n?.currentPinLabel ?? 'Current PIN',
                    errorText: errorText,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(
                  l10n?.pinCancel ?? 'Cancel',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.mutedText),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final entered = pinController.text.trim();
                  final success = await ref
                      .read(appLockNotifierProvider.notifier)
                      .disableLock(currentPin: entered);
                  if (success) {
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop(true);
                    }
                  } else {
                    setDialogState(() {
                      errorText = l10n?.pinIncorrect ?? 'Incorrect PIN';
                    });
                  }
                },
                child: Text(
                  l10n?.turnOffConfirm ?? 'Turn Off',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.moodSad,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (disabled == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.lockDisabledFeedback ?? 'App lock has been disabled.',
          ),
          backgroundColor: AppColors.deepPurple,
        ),
      );
    }
  }

  void _showTimeoutPicker(BuildContext context, AutoLockTimeout current) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.autoLockTimeoutTitle ?? 'Auto-Lock Timeout',
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...AutoLockTimeout.values.map((timeout) {
                final isSelected = timeout == current;
                String label;
                switch (timeout) {
                  case AutoLockTimeout.immediately:
                    label = l10n?.timeoutImmediately ?? 'Immediately';
                    break;
                  case AutoLockTimeout.thirtySeconds:
                    label = l10n?.timeout30Seconds ?? '30 seconds (Default)';
                    break;
                  case AutoLockTimeout.oneMinute:
                    label = l10n?.timeout1Minute ?? '1 minute';
                    break;
                  case AutoLockTimeout.fiveMinutes:
                    label = l10n?.timeout5Minutes ?? '5 minutes';
                    break;
                }
                return ListTile(
                  title: Text(label, style: AppTypography.bodyMedium),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primaryPurple)
                      : null,
                  onTap: () async {
                    await ref
                        .read(appLockNotifierProvider.notifier)
                        .setTimeout(timeout);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lockState = ref.watch(appLockNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.privacyCenterTitle ?? 'Privacy Center',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primaryText,
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Honest privacy disclosure card
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      backgroundColor: Colors.white.withValues(alpha: 0.88),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🛡️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.privacyHonestyTitle ??
                                      'How App Lock Works',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n?.privacyHonestyBody ??
                                      'This PIN is a convenience lock against casual access (like a roommate borrowing your phone). It does NOT encrypt device data. BloomWell records are stored safely on the BloomWell server under your account and are visible only to you.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondaryText,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: App Lock Controls
                    Text(
                      l10n?.appLockSectionHeading ?? 'App Lock & PIN',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Lock enabled toggle
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n?.enableAppLockTitle ?? 'Enable App Lock',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              lockState.isPinSet
                                  ? (l10n?.appLockActiveSubtitle ??
                                      'PIN configured and active')
                                  : (l10n?.appLockInactiveSubtitle ??
                                      'Require PIN to open BloomWell'),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            value: lockState.isPinSet,
                            activeTrackColor: AppColors.primaryPurple,
                            onChanged: (val) {
                              if (val) {
                                context.push('/lock/setup');
                              } else {
                                _showDisableLockDialog();
                              }
                            },
                          ),

                          if (lockState.isPinSet) ...[
                            const Divider(height: 20),
                            // Change PIN
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.pin_outlined,
                                  color: AppColors.deepPurple),
                              title: Text(
                                l10n?.changePinTitle ?? 'Change PIN',
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14),
                              onTap: () => context.push('/lock/setup'),
                            ),

                            // Biometrics toggle (mobile only)
                            if (!kIsWeb) ...[
                              const Divider(height: 20),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n?.biometricsToggleTitle ??
                                      'Unlock with Biometrics',
                                  style: AppTypography.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  l10n?.biometricsToggleSubtitle ??
                                      'Use fingerprint or Face ID as quick fallback',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                value: lockState.isBiometricsEnabled,
                                activeTrackColor: AppColors.primaryPurple,
                                onChanged: (enabled) async {
                                  final ok = await ref
                                      .read(appLockNotifierProvider.notifier)
                                      .setBiometricsEnabled(enabled);
                                  if (!ok && enabled && mounted) {
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n?.biometricsUnavailable ??
                                              'Biometrics not available or not enrolled on this device.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ] else ...[
                              const Divider(height: 20),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.mutedText,
                                ),
                                title: Text(
                                  l10n?.webBiometricsNote ??
                                      'Biometrics unavailable on web',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.mutedText,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],

                            const Divider(height: 20),
                            // Auto-lock timeout
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.timer_outlined,
                                  color: AppColors.deepPurple),
                              title: Text(
                                l10n?.autoLockTimeoutLabel ??
                                    'Auto-lock timeout',
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                lockState.timeout.name,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14),
                              onTap: () => _showTimeoutPicker(
                                  context, lockState.timeout),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Screen Privacy
                    Text(
                      l10n?.screenPrivacyHeading ?? 'Screen Privacy',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (!kIsWeb)
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n?.blockScreenshotsTitle ??
                                    'Hide previews & block screenshots',
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                l10n?.blockScreenshotsSubtitle ??
                                    'Covers app in recents and blocks screenshots on Android',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              value: lockState.hidePreviewsAndScreenshots,
                              activeTrackColor: AppColors.primaryPurple,
                              onChanged: (val) {
                                ref
                                    .read(appLockNotifierProvider.notifier)
                                    .setBlockScreenshots(val);
                              },
                            )
                          else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.info_outline_rounded,
                                  color: AppColors.mutedText),
                              title: Text(
                                l10n?.webScreenshotNote ??
                                    'Screenshot protection is exclusive to the mobile app',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.mutedText,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Quick-Hide
                    Text(
                      l10n?.quickHideHeading ?? 'Quick-Hide',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.quickHideExplanation ??
                                'Tap the eye-off icon in the top header anytime to instantly conceal the screen. If a PIN is active, the app locks; otherwise, a peaceful cover appears until tapped.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          BloomButton(
                            label: l10n?.testQuickHideButton ??
                                'Test Quick-Hide Now',
                            variant: BloomButtonVariant.subtle,
                            icon: Icons.visibility_off_outlined,
                            isExpanded: true,
                            onPressed: () {
                              ref
                                  .read(appLockNotifierProvider.notifier)
                                  .quickHide();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Coming Soon Section
                    Text(
                      l10n?.comingSoonHeading ?? 'Coming Soon',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildComingSoonItem(
                            emoji: '🔔',
                            title: l10n?.neutralRemindersTitle ??
                                'Discreet Neutral Reminders',
                            subtitle: l10n?.neutralRemindersSubtitle ??
                                'Local reminders with gentle, private wording',
                            badge: l10n?.comingSoonBadge ?? 'Coming soon',
                          ),
                          const Divider(height: 20),
                          _buildComingSoonItem(
                            emoji: '📄',
                            title: l10n?.exportDataTitle ?? 'Export My Data',
                            subtitle: l10n?.exportDataSubtitle ??
                                'Download a private copy of your records',
                            badge: l10n?.comingSoonBadge ?? 'Coming soon',
                          ),
                          const Divider(height: 20),
                          _buildComingSoonItem(
                            emoji: '🗑️',
                            title:
                                l10n?.deleteAccountTitle ?? 'Delete My Account',
                            subtitle: l10n?.deleteAccountSubtitle ??
                                'Permanently delete your account and all data',
                            badge: l10n?.comingSoonBadge ?? 'Coming soon',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonItem({
    required String emoji,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        DecorativeBadge(
          label: badge,
          backgroundColor: Colors.white,
          textColor: AppColors.mutedText,
          borderColor: AppColors.borderLight,
        ),
      ],
    );
  }
}
