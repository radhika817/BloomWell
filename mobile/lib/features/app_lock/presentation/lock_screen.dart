import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_mascot.dart';
import '../../../l10n/app_localizations.dart';
import '../application/app_lock_notifier.dart';
import 'widgets/numeric_keypad.dart';

/// The full-screen App Lock screen displayed whenever the app is locked.
///
/// Completely replaces the underlying navigator content to ensure screen readers
/// and operating system screenshots cannot inspect private data.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onDigitPressed(String digit) {
    final lockState = ref.read(appLockNotifierProvider);
    final clock = ref.read(clockProvider);
    if (lockState.isLockoutActive(clock.now())) return;
    if (_enteredPin.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    // Auto verify if 4 to 6 digits can be submitted with check button
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handleUnlock() async {
    final l10n = AppLocalizations.of(context);
    final clock = ref.read(clockProvider);
    final lockState = ref.read(appLockNotifierProvider);

    if (lockState.isLockoutActive(clock.now())) {
      return;
    }

    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage =
            l10n?.pinTooShortMessage ?? 'PIN must be at least 4 digits';
      });
      return;
    }

    final success = await ref
        .read(appLockNotifierProvider.notifier)
        .unlockWithPin(_enteredPin);

    if (mounted) {
      if (success) {
        setState(() {
          _enteredPin = '';
          _errorMessage = null;
        });
        context.go('/');
      } else {
        final updatedState = ref.read(appLockNotifierProvider);
        final remaining = updatedState.remainingLockoutSeconds(clock.now());

        setState(() {
          _enteredPin = '';
          if (remaining > 0) {
            _errorMessage = l10n?.lockoutActiveMessage(remaining) ??
                'Too many failed attempts. Try again in $remaining seconds.';
          } else {
            final attempts = updatedState.failedAttempts;
            _errorMessage = l10n?.pinIncorrectAttempts(attempts) ??
                'Incorrect PIN. ($attempts failed attempts)';
          }
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    final l10n = AppLocalizations.of(context);
    final reason = l10n?.biometricUnlockPrompt ??
        'Unlock BloomWell to access your private space';
    final success = await ref
        .read(appLockNotifierProvider.notifier)
        .unlockWithBiometrics(localizedReason: reason);

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _showForgotPinDialog() async {
    final l10n = AppLocalizations.of(context);

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.forgotPinDialogTitle ?? 'Forgot PIN?',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.forgotPinDialogBody ??
              'There is no server-side PIN recovery. To reset your PIN, you must log out. This will clear the PIN on this device and your local session. You can then log back in with your account password.',
          style: AppTypography.bodyMedium.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n?.forgotPinCancel ?? 'Cancel',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.mutedText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n?.forgotPinLogoutConfirm ?? 'Log Out & Reset',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.moodSad,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldReset == true && mounted) {
      await ref.read(appLockNotifierProvider.notifier).forgotPinAndLogout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lockState = ref.watch(appLockNotifierProvider);
    final clock = ref.watch(clockProvider);
    final isLockedOut = lockState.isLockoutActive(clock.now());
    final lockoutSeconds = lockState.remainingLockoutSeconds(clock.now());

    return PopScope(
      canPop: false, // Cannot be popped by Android back button
      child: Scaffold(
        body: BloomBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BloomMascot(size: 72),
                      const SizedBox(height: 16),
                      Text(
                        l10n?.appLockTitle ?? 'BloomWell Locked',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n?.appLockSubtitle ??
                            'Enter your PIN to resume your gentle space.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PIN Dots Display
                      Semantics(
                        label:
                            'PIN entered ${_enteredPin.length} of 4 to 6 digits',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final isFilled = index < _enteredPin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled
                                    ? AppColors.primaryPurple
                                    : Colors.white.withValues(alpha: 0.6),
                                border: Border.all(
                                  color: isFilled
                                      ? AppColors.deepPurple
                                      : AppColors.borderLight,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lockout Countdown or Error Feedback
                      if (isLockedOut)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                AppColors.moodStressed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.moodStressed,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            l10n?.lockoutActiveMessage(lockoutSeconds) ??
                                'Too many failed attempts. Try again in $lockoutSeconds seconds.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.deepPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.moodSad,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const SizedBox(height: 20),

                      const SizedBox(height: 14),

                      // Numeric Keypad
                      IgnorePointer(
                        ignoring: isLockedOut,
                        child: Opacity(
                          opacity: isLockedOut ? 0.4 : 1.0,
                          child: NumericKeypad(
                            onDigitPressed: _onDigitPressed,
                            onDeletePressed: _onDeletePressed,
                            leftActionWidget: lockState.isBiometricsEnabled
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 32,
                                      color: AppColors.deepPurple,
                                    ),
                                    tooltip: l10n?.biometricsButtonTooltip ??
                                        'Unlock with biometrics',
                                    onPressed: _handleBiometricAuth,
                                  )
                                : (_enteredPin.length >= 4
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 36,
                                          color: AppColors.primaryPurple,
                                        ),
                                        tooltip: 'Submit PIN',
                                        onPressed: _handleUnlock,
                                      )
                                    : null),
                          ),
                        ),
                      ),

                      if (_enteredPin.length >= 4 && !isLockedOut) ...[
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: _handleUnlock,
                          icon: const Icon(Icons.lock_open_rounded, size: 18),
                          label: Text(
                            l10n?.unlockButtonLabel ?? 'Unlock',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _showForgotPinDialog,
                        child: Text(
                          l10n?.forgotPinButton ?? 'Forgot PIN?',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.mutedText,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
