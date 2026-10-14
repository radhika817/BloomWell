import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';

enum BreathingPhase {
  idle('Ready to relax', 'Take a comfortable breath when you are ready'),
  inhale('Breathe In', 'Inhale peace and clarity...'),
  holdIn('Hold Gently', 'Hold your breath softly...'),
  exhale('Breathe Out', 'Release all tightness and worries...'),
  holdOut('Rest', 'Rest in this gentle stillness...');

  final String title;
  final String instruction;

  const BreathingPhase(this.title, this.instruction);
}

/// Mindful breathing card with an animated expanding/contracting circle
/// and interactive breathing session controls.
class BreathingCard extends StatefulWidget {
  const BreathingCard({super.key});

  @override
  State<BreathingCard> createState() => _BreathingCardState();
}

class _BreathingCardState extends State<BreathingCard>
    with SingleTickerProviderStateMixin {
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
        // Hold at peak
        break;
      case BreathingPhase.exhale:
        _controller.reverse(from: 1.0);
        break;
      case BreathingPhase.holdOut:
        // Hold at base
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
        setState(() {
          _cycleCount++;
        });
        _transitionToPhase(BreathingPhase.inhale);
        break;
      case BreathingPhase.idle:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Mindful Breathing',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              DecorativeBadge(
                label: _isActive ? 'Cycle $_cycleCount' : '2 min',
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
              final scale = _isActive ? _scaleAnimation.value : 0.82;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.mint.withOpacity(0.9),
                        AppColors.lavender.withOpacity(0.6),
                        Colors.white.withOpacity(0.4),
                      ],
                      stops: const [0.4, 0.75, 1.0],
                    ),
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.35),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withOpacity(0.12),
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
                          _currentPhase.title,
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
            _currentPhase.instruction,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Control Button
          BloomButton(
            label: _isActive ? 'Pause Exercise' : 'Start Quick Session',
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
        ],
      ),
    );
  }
}
