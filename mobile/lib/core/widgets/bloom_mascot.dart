import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// "Bloomie" — A friendly original flower-cloud character drawn
/// purely with Flutter vectors, gradients, and canvas arcs.
class BloomMascot extends StatelessWidget {
  final double size;
  final bool isWaving;

  const BloomMascot({
    super.key,
    this.size = 80.0,
    this.isWaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BloomMascotPainter(),
      ),
    );
  }
}

class _BloomMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final radius = size.width * 0.36;

    // Draw 6 soft pastel flower petals around the body
    final petalPaint = Paint()
      ..color = AppColors.blushPink
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * (radius * 0.72),
        center.dy + math.sin(angle) * (radius * 0.72),
      );
      canvas.drawCircle(petalCenter, radius * 0.44, petalPaint);
    }

    // Mascot Main Face Body
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFBF4FF)],
        stops: [0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Soft shadow under body
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()
        ..color = AppColors.shadowMedium.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawCircle(center, radius, bodyPaint);

    // Cute Cheeks (Blush)
    final blushPaint = Paint()
      ..color = AppColors.softRose.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.46, center.dy + radius * 0.12),
        width: radius * 0.32,
        height: radius * 0.20,
      ),
      blushPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.46, center.dy + radius * 0.12),
        width: radius * 0.32,
        height: radius * 0.20,
      ),
      blushPaint,
    );

    // Cheerful Eyes (Happy curved arcs)
    final eyePaint = Paint()
      ..color = AppColors.primaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.width * 0.035)
      ..strokeCap = StrokeCap.round;

    // Left Eye arc
    final leftEyeRect = Rect.fromCenter(
      center: Offset(center.dx - radius * 0.30, center.dy - radius * 0.08),
      width: radius * 0.28,
      height: radius * 0.24,
    );
    canvas.drawArc(leftEyeRect, math.pi * 1.15, math.pi * 0.7, false, eyePaint);

    // Right Eye arc
    final rightEyeRect = Rect.fromCenter(
      center: Offset(center.dx + radius * 0.30, center.dy - radius * 0.08),
      width: radius * 0.28,
      height: radius * 0.24,
    );
    canvas.drawArc(
        rightEyeRect, math.pi * 1.15, math.pi * 0.7, false, eyePaint);

    // Sweet Smile
    final mouthPaint = Paint()
      ..color = AppColors.primaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.03)
      ..strokeCap = StrokeCap.round;

    final mouthRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.18),
      width: radius * 0.32,
      height: radius * 0.24,
    );
    canvas.drawArc(mouthRect, 0.2, math.pi - 0.4, false, mouthPaint);

    // Little top sprout leaf
    final sproutPaint = Paint()
      ..color = const Color(0xFFB8E6CE)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(center.dx, center.dy - radius * 0.95);
    leafPath.quadraticBezierTo(
      center.dx + radius * 0.3,
      center.dy - radius * 1.35,
      center.dx + radius * 0.15,
      center.dy - radius * 1.5,
    );
    leafPath.quadraticBezierTo(
      center.dx - radius * 0.05,
      center.dy - radius * 1.3,
      center.dx,
      center.dy - radius * 0.95,
    );
    leafPath.close();
    canvas.drawPath(leafPath, sproutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
