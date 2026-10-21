import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../application/app_lock_notifier.dart';
import '../domain/weak_pin_validator.dart';
import 'widgets/numeric_keypad.dart';

/// Screen allowing the student to set or update their 4 to 6 digit convenience PIN.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    // If reached minimum length and user enters, we can let them submit or automatically proceed on 4/6
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handleContinue() async {
    final l10n = AppLocalizations.of(context);

    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = l10n?.pinTooShortMessage ?? 'PIN must be 4 to 6 digits';
      });
      return;
    }

    if (!_isConfirming) {
      if (WeakPinValidator.isWeak(_enteredPin)) {
        setState(() {
          _errorMessage = l10n?.pinWeakMessage ??
              'Please choose a stronger PIN (avoid 1234, 0000, or repeated digits)';
        });
        return;
      }

      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirming = true;
        _errorMessage = null;
      });
    } else {
      if (_enteredPin != _firstPin) {
        setState(() {
          _errorMessage =
              l10n?.pinMismatchMessage ?? 'PINs do not match. Try again';
          _enteredPin = '';
        });
        return;
      }

      final success =
          await ref.read(appLockNotifierProvider.notifier).setPin(_enteredPin);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.pinSetupSuccess ?? 'App lock PIN set successfully 🌸',
            ),
            backgroundColor: AppColors.deepPurple,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primaryText,
          onPressed: () {
            if (_isConfirming) {
              setState(() {
                _isConfirming = false;
                _enteredPin = '';
                _errorMessage = null;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🔐', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isConfirming
                          ? (l10n?.pinConfirmTitle ?? 'Confirm Your PIN')
                          : (l10n?.pinCreateTitle ?? 'Set Up App Lock PIN'),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConfirming
                          ? (l10n?.pinConfirmSubtitle ??
                              'Re-enter your 4 to 6 digit PIN to confirm.')
                          : (l10n?.pinCreateSubtitle ??
                              'Choose a 4 to 6 digit convenience PIN to shield your space.'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PIN Dots indicator with Semantics
                    Semantics(
                      label:
                          'PIN entered ${_enteredPin.length} digits of at least 4',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final isFilled = index < _enteredPin.length;
                          return AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 150),
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
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.moodSad,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),

                    const SizedBox(height: 12),
                    NumericKeypad(
                      onDigitPressed: _onDigitPressed,
                      onDeletePressed: _onDeletePressed,
                      leftActionWidget: _enteredPin.length >= 4
                          ? IconButton(
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryPurple,
                                size: 36,
                              ),
                              tooltip: 'Submit PIN',
                              onPressed: _handleContinue,
                            )
                          : null,
                    ),

                    const SizedBox(height: 20),
                    if (_enteredPin.length >= 4)
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        onTap: _handleContinue,
                        backgroundColor:
                            AppColors.primaryPurple.withValues(alpha: 0.15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isConfirming
                                  ? (l10n?.pinSaveButton ?? 'Save PIN')
                                  : (l10n?.pinContinueButton ?? 'Continue'),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.deepPurple,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.deepPurple,
                            ),
                          ],
                        ),
                      ),
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
