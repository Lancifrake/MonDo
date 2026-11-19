import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Signature de MonDo, reprise du logo : un point par membre, placés dans l'ordre de passage.
/// Les tours joués sont pleins, le point citron est celui qui reçoit maintenant, ma place est cerclée.
/// Avant le départ, les points pleins sont les places prises. Les points apparaissent un à un
/// à l'ouverture, et le point citron glisse jusqu'au tour suivant quand un tour est confirmé.
///
/// En mode choix ([onPlace]), le cercle sert à choisir sa place : on touche un point, le point citron
/// y glisse. Les places que le score ne permet pas ([premierePlace]) sont estompées et ne répondent pas.
class CercleDesTours extends StatefulWidget {
  const CercleDesTours({
    super.key,
    required this.membres,
    this.tourEnCours = 0,
    this.maPlace,
    this.inscrits,
    this.taille = 96,
    this.surFonce = false,
    this.centre,
    this.onPlace,
    this.premierePlace = 1,
  });

  /// Nombre de places (un point par place).
  final int membres;

  /// Tour en cours, à partir de 1. 0 : pas commencé (on montre les places prises), au-delà de [membres] : terminé.
  final int tourEnCours;

  /// Ma place dans l'ordre, si elle est connue. En mode choix : la place choisie.
  final int? maPlace;

  /// Places prises, pour une tontine qui n'a pas commencé.
  final int? inscrits;
  final double taille;

  /// Sur le grand rectangle vert : points clairs.
  final bool surFonce;

  /// Ce qui s'écrit au milieu du cercle.
  final Widget? centre;

  /// Mode choix : appelé avec la place touchée.
  final ValueChanged<int>? onPlace;

  /// Mode choix : première place autorisée par le score.
  final int premierePlace;

  bool get _choix => onPlace != null;

  @override
  State<CercleDesTours> createState() => _CercleDesToursState();
}

class _CercleDesToursState extends State<CercleDesTours> with SingleTickerProviderStateMixin {
  late final _apparition = AnimationController(vsync: this, duration: Duration(milliseconds: 500 + 40 * widget.membres.clamp(0, 20)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _apparition.value = 1;
    } else if (!_apparition.isAnimating && _apparition.value == 0) {
      _apparition.forward();
    }
  }

  @override
  void dispose() {
    _apparition.dispose();
    super.dispose();
  }

  String get _description {
    final n = widget.membres;
    final t = widget.tourEnCours;
    if (widget._choix) return 'Choix de la place : place ${widget.maPlace ?? '-'} sur $n';
    final moi = widget.maPlace == null ? '' : ', ma place : ${widget.maPlace}';
    if (t <= 0) return '${widget.inscrits ?? 0} places prises sur $n$moi';
    if (t > n) return 'Tontine terminée, $n tours joués';
    return 'Tour $t sur $n$moi';
  }

  /// Place la plus proche du point touché, ou null si on touche le centre.
  int? _placeTouchee(Offset local) {
    final c = Offset(widget.taille / 2, widget.taille / 2);
    final d = local - c;
    if (d.distance < widget.taille * 0.25) return null;
    // Angle mesuré depuis le haut, dans le sens des aiguilles d'une montre.
    var angle = math.atan2(d.dy, d.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final index = (angle / (2 * math.pi) * widget.membres).round() % widget.membres;
    return index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final immobile = MediaQuery.of(context).disableAnimations;
    // Ce que suit le point citron : le tour en cours, ou la place choisie.
    final cible = widget._choix ? (widget.maPlace ?? 0) : widget.tourEnCours;
    Widget cercle = SizedBox.square(
      dimension: widget.taille,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: cible.toDouble()),
        duration: immobile ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        builder: (context, curseur, centre) => AnimatedBuilder(
          animation: _apparition,
          builder: (context, _) => CustomPaint(
            painter: _Peintre(
              membres: widget.membres,
              tour: widget._choix ? 0 : curseur,
              curseur: curseur,
              choix: widget._choix,
              premierePlace: widget.premierePlace,
              maPlace: widget.maPlace,
              inscrits: widget.inscrits,
              apparition: _apparition.value,
              surFonce: widget.surFonce,
            ),
            child: Center(child: centre),
          ),
        ),
        child: widget.centre,
      ),
    );
    if (widget._choix) {
      cercle = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final p = _placeTouchee(d.localPosition);
          if (p == null || p < widget.premierePlace || p == widget.maPlace) return;
          HapticFeedback.selectionClick();
          widget.onPlace!(p);
        },
        child: cercle,
      );
    }
    return Semantics(label: _description, child: cercle);
  }
}

class _Peintre extends CustomPainter {
  _Peintre({
    required this.membres,
    required this.tour,
    required this.curseur,
    required this.choix,
    required this.premierePlace,
    required this.maPlace,
    required this.inscrits,
    required this.apparition,
    required this.surFonce,
  }) : sombre = AppColors.sombre;

  final bool sombre;
  final int membres;
  final double tour;
  final double curseur;
  final bool choix;
  final int premierePlace;
  final int? maPlace;
  final int? inscrits;
  final double apparition;
  final bool surFonce;

  Offset _point(Offset c, double rayon, double index) {
    // Le premier tour en haut, puis dans le sens des aiguilles d'une montre.
    final angle = -math.pi / 2 + 2 * math.pi * index / membres;
    return c + Offset(math.cos(angle), math.sin(angle)) * rayon;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (membres <= 0) return;
    final c = size.center(Offset.zero);
    final pas = 2 * math.pi * (size.width / 2) / membres;
    final r = (pas * 0.22).clamp(2.5, size.width / 24);
    final rayon = size.width / 2 - r * 2.2;

    final plein = surFonce ? Colors.white : AppColors.vertEncre;
    final vide = surFonce ? Colors.white.withValues(alpha: 0.35) : AppColors.textMuted.withValues(alpha: 0.45);
    final pinceauPlein = Paint()..color = plein;
    final pinceauVide = Paint()
      ..color = vide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final demarre = !choix && tour >= 1;
    final termine = !choix && tour > membres;
    final fond = surFonce ? AppColors.darkGreen : AppColors.surface;

    // L'anneau qui relie les points : fin pour le cycle entier, plein pour la part déjà jouée.
    final rect = Rect.fromCircle(center: c, radius: rayon);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * apparition,
      false,
      Paint()
        ..color = vide
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final joue = termine ? 1.0 : demarre ? ((tour - 1) / membres).clamp(0.0, 1.0) : 0.0;
    if (joue > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * joue * apparition,
        false,
        Paint()
          ..color = plein
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.5,
      );
    }

    for (var i = 0; i < membres; i++) {
      // Apparition un à un : chaque point grossit à son tour.
      final echelle = Curves.easeOutBack.transform(((apparition * (membres + 2)) - i).clamp(0.0, 1.0));
      if (echelle <= 0) continue;
      final p = _point(c, rayon, i.toDouble());
      final place = i + 1;
      if (choix && place < premierePlace) {
        // Place que le score ne permet pas : à peine visible.
        canvas.drawCircle(p, r * 0.55 * echelle, Paint()..color = vide.withValues(alpha: 0.25));
        continue;
      }
      final rempli = termine || (demarre ? place < tour.round() : !choix && place <= (inscrits ?? 0));
      if (rempli) {
        canvas.drawCircle(p, r * echelle, pinceauPlein);
      } else {
        canvas.drawCircle(p, r * echelle, Paint()..color = fond);
        canvas.drawCircle(p, (r - 0.75) * echelle, pinceauVide);
      }
      if (place == maPlace) {
        canvas.drawCircle(
          p,
          (r + 3.5) * echelle,
          Paint()
            ..color = plein
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Le point citron : celui qui reçoit à ce tour (ou la place choisie). Il glisse le long du cercle.
    final citron = choix ? curseur >= 1 : demarre && !termine;
    if (citron && apparition > 0.6) {
      final p = _point(c, rayon, curseur - 1);
      final halo = ((apparition - 0.6) / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(p, r * 1.55 * halo, Paint()..color = AppColors.lime);
      if (!surFonce) {
        canvas.drawCircle(
          p,
          r * 1.55 * halo,
          Paint()
            ..color = AppColors.darkGreen
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Peintre old) =>
      old.sombre != sombre ||
      old.tour != tour ||
      old.curseur != curseur ||
      old.apparition != apparition ||
      old.membres != membres ||
      old.maPlace != maPlace ||
      old.inscrits != inscrits ||
      old.premierePlace != premierePlace;
}
