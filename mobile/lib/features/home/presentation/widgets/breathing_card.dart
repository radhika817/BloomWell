import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../l10n/app_localizations.dart';

enum BreathingPhase {
  idle,
  inhale,
  holdIn,
  exhale,
  holdOut,
}

/// Mindful breathing card with an animated expanding/contracting circle,
/// 8-cycle (about 2 min) calibrated timing, and accessibility motion support.
class BreathingCard extends StatefulWidget {
  const BreathingCard({super.key});

  @override
  State<BreathingCard> createState() => _BreathingCardState();
}

class _BreathingCardState extends State<BreathingCard>
    with SingleTickerProviderStateMixin {
  static const int _totalCycles = 8;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  Timer? _phaseTimer;

  bool _isActive = false;
  BreathingPhase _currentPhase = BreathingPhase.idle;
  int _secondsLeftInPhase = 4;
  int _cycleCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _cycleCount = 1;
      _transitionToPhase(BreathingPhase.inhale);
    });
  }

  void _stopBreathing() {
    _phaseTimer?.cancel();
    _controller.stop();
    _controller.reset();
    setState(() {
      _isActive = false;
      _currentPhase = BreathingPhase.idle;
      _secondsLeftInPhase = 4;
      _cycleCount = 0;
    });
  }

  void _transitionToPhase(BreathingPhase nextPhase) {
    if (!mounted || !_isActive) return;

    _phaseTimer?.cancel();
    setState(() {
      _currentPhase = nextPhase;
      _secondsLeftInPhase = 4;
    });

    switch (nextPhase) {
      case BreathingPhase.inhale:
        _controller.forward(from: 0.0);
        break;
      case BreathingPhase.holdIn:
        break;
      case BreathingPhase.exhale:
        _controller.reverse(from: 1.0);
        break;
      case BreathingPhase.holdOut:
        break;
      case BreathingPhase.idle:
        break;
    }

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsLeftInPhase--;
      });

      if (_secondsLeftInPhase <= 0) {
        timer.cancel();
        _advanceToNextPhase();
      }
    });
  }

  void _advanceToNextPhase() {
    if (!_isActive) return;

    switch (_currentPhase) {
      case BreathingPhase.inhale:
        _transitionToPhase(BreathingPhase.holdIn);
        break;
      case BreathingPhase.holdIn:
        _transitionToPhase(BreathingPhase.exhale);
        break;
      case BreathingPhase.exhale:
        _transitionToPhase(BreathingPhase.holdOut);
        break;
      case BreathingPhase.holdOut:
        if (_cycleCount >= _totalCycles) {
          _stopBreathing();
        } else {
          setState(() {
            _cycleCount++;
          });
          _transitionToPhase(BreathingPhase.inhale);
        }
        break;
      case BreathingPhase.idle:
        break;
    }
  }

  String _phaseTitle(BreathingPhase phase, AppLocalizations? l10n) {
    switch (phase) {
      case BreathingPhase.idle:
        return l10n?.breathingPhaseIdleTitle ?? 'Ready to relax';
      case BreathingPhase.inhale:
        return l10n?.breathingPhaseInhaleTitle ?? 'Breathe In';
      case BreathingPhase.holdIn:
        return l10n?.breathingPhaseHoldInTitle ?? 'Hold Gently';
      case BreathingPhase.exhale:
        return l10n?.breathingPhaseExhaleTitle ?? 'Breathe Out';
      case BreathingPhase.holdOut:
        return l10n?.breathingPhaseHoldOutTitle ?? 'Rest';
    }
  }

  String _phaseInstruction(BreathingPhase phase, AppLocalizations? l10n) {
    switch (phase) {
      case BreathingPhase.idle:
        return l10n?.breathingPhaseIdleInstruction ??
            'Take a comfortable breath when you are ready';
      case BreathingPhase.inhale:
        return l10n?.breathingPhaseInhaleInstruction ??
            'Inhale peace and clarity...';
      case BreathingPhase.holdIn:
        return l10n?.breathingPhaseHoldInInstruction ??
            'Hold your breath softly...';
      case BreathingPhase.exhale:
        return l10n?.breathingPhaseExhaleInstruction ??
            'Release all tightness and worries...';
      case BreathingPhase.holdOut:
        return l10n?.breathingPhaseHoldOutInstruction ??
            'Rest in this gentle stillness...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final badgeLabel = _isActive
        ? (l10n?.breathingCycleCount(_cycleCount, _totalCycles) ??
            'Cycle $_cycleCount of $_totalCycles')
        : (l10n?.breathingDurationBadge ?? 'about 2 min');

    return AppCard(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFE8F7F0), // Soft Mint
          Color(0xFFF3EDFF), // Soft Lavender
          Colors.white,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: const Color(0xFFD6EFE1),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🫧', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n?.breathingCardTitle ?? 'Mindful Breathing',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              DecorativeBadge(
                label: badgeLabel,
                icon: Icons.timer_outlined,
                backgroundColor: Colors.white,
                textColor: AppColors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Calming animated breathing bubble
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final double scale;
              if (reduceMotion) {
                scale = 1.0;
              } else {
                scale = _isActive ? _scaleAnimation.value : 0.82;
              }

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.mint.withValues(alpha: 0.9),
                        AppColors.lavender.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.4),
                      ],
                      stops: const [0.4, 0.75, 1.0],
                    ),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withValues(alpha: 0.12),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isActive ? '$_secondsLeftInPhase s' : '🌿',
                        style: TextStyle(
                          fontSize: _isActive ? 22 : 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepPurple,
                        ),
                      ),
                      if (_isActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          _phaseTitle(_currentPhase, l10n),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            _phaseInstruction(_currentPhase, l10n),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Control Button
          Semantics(
            button: true,
            label: _isActive
                ? (l10n?.breathingPauseButton ?? 'Pause Exercise')
                : (l10n?.breathingStartButton ?? 'Start Quick Session'),
            child: BloomButton(
              label: _isActive
                  ? (l10n?.breathingPauseButton ?? 'Pause Exercise')
                  : (l10n?.breathingStartButton ?? 'Start Quick Session'),
              icon: _isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
              emoji: _isActive ? null : '🌸',
              variant: _isActive
                  ? BloomButtonVariant.subtle
                  : BloomButtonVariant.primary,
              isExpanded: true,
              onPressed: () {
                if (_isActive) {
                  _stopBreathing();
                } else {
                  _startBreathing();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
