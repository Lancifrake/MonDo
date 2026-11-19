import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Le logo qui tourne, sur l'écran de démarrage : les membres passent à tour de rôle.
class LogoQuiTourne extends StatefulWidget {
  const LogoQuiTourne({super.key, this.taille = 96});

  final double taille;

  @override
  State<LogoQuiTourne> createState() => _LogoQuiTourneState();
}

class _LogoQuiTourneState extends State<LogoQuiTourne> with SingleTickerProviderStateMixin {
  late final AnimationController _tour = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: CurvedAnimation(parent: _tour, curve: Curves.easeInOutCubic),
        child: LogoMonDo(taille: widget.taille),
      );
}

/// Écran de démarrage : fond vert MonDo, logo qui tourne, le temps d'ouvrir la session.
class EcranDeDemarrage extends StatelessWidget {
  const EcranDeDemarrage({super.key});

  @override
  Widget build(BuildContext context) => const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light, // heure et batterie en blanc sur le vert
        child: Scaffold(
          backgroundColor: AppColors.darkGreen,
          body: Center(child: LogoQuiTourne(taille: 96)),
        ),
      );
}
