import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Full-screen soft pastel background featuring a dreamy gradient
/// and subtle organic canvas motifs for a premium soft glass aesthetic.
class BloomBackground extends StatelessWidget {
  final Widget child;

  const BloomBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle organic background orbs to enhance frosted glass blur
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BackgroundOrbsPainter(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackgroundOrbsPainter extends CustomPainter {
  const _BackgroundOrbsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-right soft lavender glow
    paint.color = AppColors.lavender.withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.08),
      size.width * 0.42,
      paint,
    );

    // Top-left soft peach glow
    paint.color = AppColors.peach.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.22),
      size.width * 0.32,
      paint,
    );

    // Middle-right soft rose glow
    paint.color = AppColors.softRose.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.55),
      size.width * 0.38,
      paint,
    );

    // Bottom-left mint glow
    paint.color = AppColors.mint.withValues(alpha: 0.4);
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.82),
      size.width * 0.45,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
