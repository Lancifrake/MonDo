import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value,
    required this.child,
    this.size = 88,
    this.strokeWidth = 10,
  });

  final double value; // entre 0 et 1
  final Widget child; // ce qu'on affiche au centre
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0.0, 1.0), strokeWidth),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.strokeWidth);

  final double value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);

    final track = Paint()
      ..color = AppColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * pi, false, track);

    final progress = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // On part du haut (-90°) et on tourne dans le sens des aiguilles d'une montre
    canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, progress);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.strokeWidth != strokeWidth;
}