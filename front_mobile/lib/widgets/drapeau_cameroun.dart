import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Le drapeau du Cameroun, dessiné (pas d'image) : vert, rouge à étoile jaune, jaune.
class DrapeauCameroun extends StatelessWidget {
  const DrapeauCameroun({super.key, this.largeur = 30});

  final double largeur;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cameroun, indicatif +237',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(size: Size(largeur, largeur * 2 / 3), painter: _Drapeau()),
        ),
      ),
    );
  }
}

class _Drapeau extends CustomPainter {
  static const _vert = Color(0xFF007A5E);
  static const _rouge = Color(0xFFCE1126);
  static const _jaune = Color(0xFFFCD116);

  @override
  void paint(Canvas canvas, Size size) {
    final tiers = size.width / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, tiers, size.height), Paint()..color = _vert);
    canvas.drawRect(Rect.fromLTWH(tiers, 0, tiers, size.height), Paint()..color = _rouge);
    canvas.drawRect(Rect.fromLTWH(tiers * 2, 0, size.width - tiers * 2, size.height), Paint()..color = _jaune);
    final c = size.center(Offset.zero);
    final exterieur = size.height * 0.2;
    final interieur = exterieur * 0.382;
    final etoile = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? exterieur : interieur;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? etoile.moveTo(p.dx, p.dy) : etoile.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(etoile..close(), Paint()..color = _jaune);
  }

  @override
  bool shouldRepaint(_Drapeau old) => false;
}
