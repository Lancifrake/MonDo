import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Le logo MonDo, comme sur la console : huit points en cercle, les membres.
/// Le point du haut, vert anis, est celui qui reçoit ce tour-ci.
class LogoMonDo extends StatelessWidget {
  const LogoMonDo({super.key, this.taille = 40, this.couleur = Colors.white});

  final double taille;
  final Color couleur;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(taille), painter: _Points(couleur));
}

class _Points extends CustomPainter {
  _Points(this.couleur);

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rayon = size.width * 0.34;
    final point = size.width * 0.075;
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * rayon;
      if (i == 0) {
        canvas.drawCircle(p, point * 1.5, Paint()..color = AppColors.lime);
        canvas.drawCircle(
          p,
          point * 1.5,
          Paint()
            ..color = couleur
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.04,
        );
      } else {
        canvas.drawCircle(p, point, Paint()..color = couleur);
      }
    }
  }

  @override
  bool shouldRepaint(_Points old) => old.couleur != couleur;
}
