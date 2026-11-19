import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fond à motifs discrets, dans l'esprit des fonds de discussion : de petits dessins de la vie
/// d'une tontine (cagnotte, téléphone, poignée de main, calendrier, groupe, reçu, bouclier et le
/// cercle de points du logo), semés sur une tuile qui se répète. Très pâle : il donne de la
/// matière à la page sans gêner la lecture.
class FondMotif extends StatelessWidget {
  const FondMotif({super.key, required this.child, this.surFonce = false});

  final Widget child;

  /// Sur le vert foncé de l'accueil d'ouverture : motifs clairs.
  final bool surFonce;

  @override
  Widget build(BuildContext context) {
    final couleur = surFonce
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.sombre
            ? Colors.white.withValues(alpha: 0.045)
            // Le jour, un vert pâle plus marqué : à 5 % il disparaissait sur le fond crème.
            : AppColors.green.withValues(alpha: 0.11);
    return CustomPaint(
      painter: _Motif(couleur),
      child: child,
    );
  }
}

/// Un dessin de la tuile : position (en fraction de la tuile), angle, taille.
typedef _Dessin = ({IconData? icone, double x, double y, double angle, double taille});

const _tuile = 168.0;

// Placement fixe (pas de hasard à chaque ouverture) : réparti pour éviter les alignements.
const List<_Dessin> _dessins = [
  (icone: Icons.savings_outlined, x: 0.12, y: 0.10, angle: -0.25, taille: 22),
  (icone: null, x: 0.55, y: 0.08, angle: 0, taille: 18), // cercle de points du logo
  (icone: Icons.smartphone_outlined, x: 0.86, y: 0.20, angle: 0.3, taille: 20),
  (icone: Icons.handshake_outlined, x: 0.34, y: 0.33, angle: 0.15, taille: 24),
  (icone: Icons.event_outlined, x: 0.72, y: 0.45, angle: -0.2, taille: 20),
  (icone: Icons.groups_outlined, x: 0.10, y: 0.55, angle: 0.1, taille: 24),
  (icone: Icons.receipt_long_outlined, x: 0.45, y: 0.66, angle: -0.35, taille: 20),
  (icone: Icons.verified_user_outlined, x: 0.88, y: 0.74, angle: 0.25, taille: 20),
  (icone: null, x: 0.22, y: 0.88, angle: 0, taille: 14),
  (icone: Icons.payments_outlined, x: 0.64, y: 0.90, angle: 0.2, taille: 20),
];

class _Motif extends CustomPainter {
  _Motif(this.couleur);

  final Color couleur;

  void _cercleDuLogo(Canvas canvas, Offset centre, double taille, Paint pinceau) {
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      canvas.drawCircle(centre + Offset(math.cos(a), math.sin(a)) * taille / 2, taille * 0.09, pinceau);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pinceau = Paint()..color = couleur;
    // Une icône dessinée une fois par sorte, réutilisée à chaque tuile.
    final peintres = <IconData, TextPainter>{};
    TextPainter peintre(IconData icone, double taille) => peintres.putIfAbsent(
          icone,
          () => TextPainter(
            text: TextSpan(
              text: String.fromCharCode(icone.codePoint),
              style: TextStyle(fontFamily: icone.fontFamily, package: icone.fontPackage, fontSize: taille, color: couleur),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var ty = 0.0; ty < size.height; ty += _tuile) {
      // Une rangée sur deux décalée d'une demi-tuile : le motif ne forme pas de colonnes.
      final decalage = ((ty / _tuile).round().isOdd) ? _tuile / 2 : 0.0;
      for (var tx = -decalage; tx < size.width; tx += _tuile) {
        for (final d in _dessins) {
          final centre = Offset(tx + d.x * _tuile, ty + d.y * _tuile);
          final icone = d.icone;
          if (icone == null) {
            _cercleDuLogo(canvas, centre, d.taille, pinceau);
            continue;
          }
          final tp = peintre(icone, d.taille);
          canvas.save();
          canvas.translate(centre.dx, centre.dy);
          canvas.rotate(d.angle);
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Motif old) => old.couleur != couleur;
}
