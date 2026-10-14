import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';

enum _BreathingPhase {
  inhale,
  holdIn,
  exhale,
  rest,
}

/// Full-screen Mindful Breathing exercise calibrated for 8 cycles
/// of 16 seconds each (~2 minutes total) with an organic undulating ring.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalCycles = 8;
  static const int _phaseDurationSec = 4;
  static const int _cycleDurationSec = _phaseDurationSec * 4; // 16 seconds
  static const int _totalSeconds = _totalCycles * _cycleDurationSec; // 128s

  late AnimationController _animController;
  Timer? _timer;

  bool _isPlaying = true;
  bool _isCompleted = false;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cycleDurationSec),
    );

    _startSession();
  }

  void _startSession() {
    _animController.repeat();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;

      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _totalSeconds) {
          _isCompleted = true;
          _isPlaying = false;
          _timer?.cancel();
          _animController.stop();
        }
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  void _restartSession() {
    setState(() {
      _elapsedSeconds = 0;
      _isCompleted = false;
      _isPlaying = true;
    });
    _animController.reset();
    _animController.repeat();
    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  _BreathingPhase get _currentPhase {
    final secondInCycle = _elapsedSeconds % _cycleDurationSec;
    if (secondInCycle < _phaseDurationSec) {
      return _BreathingPhase.inhale;
    } else if (secondInCycle < _phaseDurationSec * 2) {
      return _BreathingPhase.holdIn;
    } else if (secondInCycle < _phaseDurationSec * 3) {
      return _BreathingPhase.exhale;
    } else {
      return _BreathingPhase.rest;
    }
  }

  int get _currentCycleNumber {
    final cycle = (_elapsedSeconds ~/ _cycleDurationSec) + 1;
    return cycle > _totalCycles ? _totalCycles : cycle;
  }

  int get _remainingSeconds {
    final remaining = _totalSeconds - _elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  String _getPhaseTitle(AppLocalizations? l10n) {
    switch (_currentPhase) {
      case _BreathingPhase.inhale:
        return l10n?.breathePhaseInhale ?? 'Breathe In';
      case _BreathingPhase.holdIn:
        return l10n?.breathePhaseHold ?? 'Hold Softly';
      case _BreathingPhase.exhale:
        return l10n?.breathePhaseExhale ?? 'Breathe Out';
      case _BreathingPhase.rest:
        return l10n?.breathePhaseRest ?? 'Rest & Center';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with back button, title, and close
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n?.breatheFinish ?? 'Finish',
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primaryText,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.breatheScreenTitle ?? 'Mindful Breathing',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n?.breatheScreenSubtitle ??
                                '8 soothing cycles · ~2 min',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        l10n?.breatheFinish ?? 'Finish',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: LinearProgressIndicator(
                    value: _elapsedSeconds / _totalSeconds,
                    minHeight: 6.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),

              // Main Interactive Center
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: _isCompleted
                        ? _buildCompletedView(l10n)
                        : _buildBreathingView(l10n, disableAnimations),
                  ),
                ),
              ),

              // Non-diagnostic clinical disclaimer footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
                child: Text(
                  l10n?.breatheNonDiagnosticNote ??
                      'Non-diagnostic relaxation exercise. Stop anytime if you feel lightheaded.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.0,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingView(AppLocalizations? l10n, bool disableAnimations) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cycle & remaining time indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(100.0),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                l10n?.breathingCycleCount(_currentCycleNumber, _totalCycles) ??
                    'Cycle $_currentCycleNumber of $_totalCycles',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.deepPurple,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(100.0),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                l10n?.breatheRemainingLabel(_remainingSeconds) ??
                    '${_remainingSeconds}s remaining',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36.0),

        // Animated Organic Breathing Ring
        SizedBox(
          width: 250.0,
          height: 250.0,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return CustomPaint(
                painter: _OrganicBreathingRingPainter(
                  animationProgress:
                      disableAnimations ? 0.5 : _animController.value,
                  phase: _currentPhase,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getPhaseTitle(l10n),
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${_phaseDurationSec - (_elapsedSeconds % _phaseDurationSec)}s',
                        style: AppTypography.display.copyWith(
                          fontSize: 32.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 42.0),

        // Play/Pause and Restart Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                foregroundColor: AppColors.primaryText,
                padding: const EdgeInsets.all(14.0),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 26),
              tooltip: l10n?.breatheRestart ?? 'Breathe Again',
              onPressed: _restartSession,
            ),
            const SizedBox(width: 20.0),
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 68.0,
                height: 68.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ctaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaShadow,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedView(AppLocalizations? l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 54.0)),
          const SizedBox(height: 16.0),
          Text(
            l10n?.breatheCompletedTitle ?? 'Session Complete 🌸',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.deepPurple,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            l10n?.breatheCompletedMessage ??
                'Wonderful job taking this peaceful moment for your mind and body.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28.0),
          GradientButton(
            label: l10n?.breatheReturnHome ?? 'Return to Home',
            isExpanded: true,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 12.0),
          TextButton(
            onPressed: _restartSession,
            child: Text(
              l10n?.breatheRestart ?? 'Breathe Again',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganicBreathingRingPainter extends CustomPainter {
  final double animationProgress;
  final _BreathingPhase phase;

  const _OrganicBreathingRingPainter({
    required this.animationProgress,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.36;

    // Radius scaling based on breathing phase
    // 0.0 -> 0.25: inhale (expand 0.85 -> 1.15)
    // 0.25 -> 0.50: hold (steady 1.15)
    // 0.50 -> 0.75: exhale (contract 1.15 -> 0.85)
    // 0.75 -> 1.00: rest (steady 0.85)
    double expansionFactor;
    if (animationProgress < 0.25) {
      final t = animationProgress / 0.25;
      expansionFactor = 0.85 + 0.30 * Curves.easeInOutCubic.transform(t);
    } else if (animationProgress < 0.50) {
      expansionFactor = 1.15;
    } else if (animationProgress < 0.75) {
      final t = (animationProgress - 0.50) / 0.25;
      expansionFactor = 1.15 - 0.30 * Curves.easeInOutCubic.transform(t);
    } else {
      expansionFactor = 0.85;
    }

    final currentRadius = baseRadius * expansionFactor;

    // Draw soft glowing aura behind the ring
    final auraPaint = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, currentRadius, auraPaint);

    // Draw wavy ring using connected sinusoidal perturbation
    final path = Path();
    const pointsCount = 120;
    final waveAmplitude = 4.0 + 3.0 * math.sin(animationProgress * math.pi * 2);

    for (int i = 0; i < pointsCount; i++) {
      final theta = (i / pointsCount) * math.pi * 2;
      // 5-node organic wave
      final wave = math.sin(theta * 5 + (animationProgress * math.pi * 2)) *
          waveAmplitude;
      final r = currentRadius + wave;
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill with translucent pastel gradient
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.5),
          AppColors.lavender.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Stroke with purple-lavender gradient
    final strokePaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          AppColors.primaryPurple,
          AppColors.softRose,
          Color(0xFFB8E6CE),
          AppColors.primaryPurple,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _OrganicBreathingRingPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.phase != phase;
  }
}
