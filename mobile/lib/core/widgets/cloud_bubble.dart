import 'package:flutter/material.dart';

/// Decorative cloud bubble widget with custom organic bezier curves
/// that can serve as a soft backdrop or greeting frame.
class CloudBubble extends StatelessWidget {
  final Widget? child;
  final double width;
  final double height;
  final Color color;
  final EdgeInsetsGeometry padding;

  const CloudBubble({
    super.key,
    this.child,
    this.width = 160.0,
    this.height = 100.0,
    this.color = const Color(0x99FFFFFF),
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CloudPainter(color: color),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final Color color;

  const _CloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Organic cloud shape using connected cubic and quadratic bezier curves
    path.moveTo(w * 0.22, h * 0.75);

    // Bottom line
    path.lineTo(w * 0.78, h * 0.75);

    // Right small puff
    path.cubicTo(w * 0.95, h * 0.75, w * 0.98, h * 0.45, w * 0.82, h * 0.40);

    // Top-right puff
    path.cubicTo(w * 0.84, h * 0.15, w * 0.58, h * 0.10, w * 0.48, h * 0.28);

    // Top-left puff
    path.cubicTo(w * 0.38, h * 0.12, w * 0.15, h * 0.20, w * 0.16, h * 0.45);

    // Left puff
    path.cubicTo(w * 0.02, h * 0.50, w * 0.05, h * 0.75, w * 0.22, h * 0.75);

    path.close();

    // Soft blur shadow behind the cloud
    canvas.drawShadow(path, Colors.purple.withValues(alpha: 0.08), 8.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
