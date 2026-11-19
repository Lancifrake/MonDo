import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Les trois illustrations animées de l'accueil. Tout est dessiné ici, sans image ni bibliothèque :
/// le logo MonDo (huit points en cercle) qui prend vie, le score qui monte, les reçus qui s'empilent.

/// Boucle d'animation partagée par les trois illustrations. Si le téléphone demande moins
/// d'animations, l'image reste figée sur son état complet.
mixin _Boucle<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  Duration get duree;
  late final AnimationController boucle = AnimationController(vsync: this, duration: duree);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      boucle
        ..stop()
        ..value = 0.85;
    } else if (!boucle.isAnimating) {
      boucle.repeat();
    }
  }

  @override
  void dispose() {
    boucle.dispose();
    super.dispose();
  }
}

double _entre(double t, double debut, double fin) => ((t - debut) / (fin - debut)).clamp(0.0, 1.0);

/// Un membre : silhouette neutre, jamais d'initiales.
void _silhouette(Canvas canvas, Offset c, double r, Color couleur) {
  canvas.save();
  canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
  final p = Paint()..color = couleur;
  canvas.drawCircle(c + Offset(0, -r * 0.22), r * 0.32, p);
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, r * 0.78), width: r * 1.35, height: r * 1.1), p);
  canvas.restore();
}

// ---------------------------------------------------------------------------------------------
// 1. Le cercle : huit membres, la cagnotte passe de l'un à l'autre.

class IllustrationCercle extends StatefulWidget {
  const IllustrationCercle({super.key});

  @override
  State<IllustrationCercle> createState() => _CercleState();
}

class _CercleState extends State<IllustrationCercle> with SingleTickerProviderStateMixin, _Boucle {
  @override
  Duration get duree => const Duration(seconds: 12);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(math.min(c.maxWidth, c.maxHeight), 340.0);
      return SizedBox.square(
        dimension: s,
        child: AnimatedBuilder(
          animation: boucle,
          builder: (context, _) {
            final t = boucle.value;
            final tour = (t * 8).floor() % 8;
            final local = t * 8 - (t * 8).floor();
            final battement = 1 + 0.035 * math.sin(math.pi * _entre(local, 0.35, 0.75));
            return Stack(alignment: Alignment.center, children: [
              CustomPaint(size: Size.square(s), painter: _PeintreCercle(t: t, tour: tour, local: local)),
              Transform.scale(
                scale: battement,
                child: Container(
                  width: s * 0.36,
                  height: s * 0.36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lime,
                    boxShadow: [BoxShadow(color: AppColors.lime.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 4)],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Cagnotte',
                        style: TextStyle(fontSize: s * 0.037, color: AppColors.darkGreen, fontWeight: FontWeight.w500)),
                    Text('80 000',
                        style: TextStyle(
                          fontSize: s * 0.075,
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                    Text('FCFA', style: TextStyle(fontSize: s * 0.034, color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]);
          },
        ),
      );
    });
  }
}

class _PeintreCercle extends CustomPainter {
  _PeintreCercle({required this.t, required this.tour, required this.local});

  final double t;
  final int tour;
  final double local;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = size.center(Offset.zero);
    final rayon = s * 0.38;
    final membre = s * 0.075;

    // Halo et anneau en pointillés qui tourne doucement
    canvas.drawCircle(
      c,
      s * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [AppColors.lime.withValues(alpha: 0.16), AppColors.lime.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: s * 0.5)),
    );
    final anneau = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const traits = 48;
    for (var i = 0; i < traits; i++) {
      final a = t * math.pi * 0.5 + i * 2 * math.pi / traits;
      canvas.drawArc(Rect.fromCircle(center: c, radius: rayon), a, math.pi / traits, false, anneau);
    }

    Offset position(int i) => c + Offset(math.cos(-math.pi / 2 + i * math.pi / 4), math.sin(-math.pi / 2 + i * math.pi / 4)) * rayon;

    // Le faisceau : la cagnotte part du centre vers celui dont c'est le tour
    final avance = Curves.easeInOutCubic.transform(_entre(local, 0.05, 0.45));
    final cible = position(tour);
    final depart = c + (cible - c) * 0.22;
    final bout = Offset.lerp(depart, cible, avance)!;
    if (avance > 0) {
      canvas.drawLine(
        depart,
        bout,
        Paint()
          ..shader = LinearGradient(colors: [AppColors.lime.withValues(alpha: 0), AppColors.lime])
              .createShader(Rect.fromPoints(depart, bout))
          ..strokeWidth = s * 0.012
          ..strokeCap = StrokeCap.round,
      );
      if (avance < 1) canvas.drawCircle(bout, s * 0.018, Paint()..color = AppColors.lime);
    }

    for (var i = 0; i < 8; i++) {
      final p = position(i);
      final aRecu = i < tour; // a déjà reçu ce cycle
      final sonTour = i == tour;
      final arrivee = sonTour ? Curves.easeOutBack.transform(_entre(local, 0.4, 0.6)) : 0.0;
      final r = membre * (1 + 0.28 * arrivee * (1 - _entre(local, 0.85, 1)));
      if (sonTour && arrivee > 0) {
        canvas.drawCircle(p, r * 1.9, Paint()..color = AppColors.lime.withValues(alpha: 0.18 * arrivee));
      }
      canvas.drawCircle(
        p,
        r,
        Paint()..color = sonTour && arrivee > 0 ? Color.lerp(Colors.white.withValues(alpha: 0.1), AppColors.lime, arrivee)! : Colors.white.withValues(alpha: 0.1),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = aRecu ? AppColors.lime : Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = aRecu ? 2.2 : 1.4,
      );
      _silhouette(canvas, p, r * 0.92,
          sonTour && arrivee > 0.5 ? AppColors.darkGreen : Colors.white.withValues(alpha: aRecu ? 0.95 : 0.7));
    }
  }

  @override
  bool shouldRepaint(_PeintreCercle old) => old.t != t;
}

// ---------------------------------------------------------------------------------------------
// 2. Le score : la jauge monte, les points gagnés s'affichent, les premières places s'ouvrent.

class IllustrationScore extends StatefulWidget {
  const IllustrationScore({super.key});

  @override
  State<IllustrationScore> createState() => _ScoreState();
}

class _ScoreState extends State<IllustrationScore> with SingleTickerProviderStateMixin, _Boucle {
  @override
  Duration get duree => const Duration(seconds: 7);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(math.min(c.maxWidth, c.maxHeight), 340.0);
      return SizedBox.square(
        dimension: s,
        child: AnimatedBuilder(
          animation: boucle,
          builder: (context, _) {
            final t = boucle.value;
            final sortie = 1 - _entre(t, 0.92, 1);
            final valeur = 76 * Curves.easeOutCubic.transform(_entre(t, 0.04, 0.55)) * sortie;
            Widget pastille(double debut, Alignment ou, String points, String texte, {IconData? icone}) {
              final v = Curves.easeOutBack.transform(_entre(t, debut, debut + 0.1)) * sortie;
              final flotte = 4 * math.sin(2 * math.pi * (t * 2 + debut));
              return Align(
                alignment: ou,
                child: Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - v) + flotte),
                    child: _Pastille(points: points, texte: texte, icone: icone, taille: s),
                  ),
                ),
              );
            }

            return Stack(children: [
              CustomPaint(size: Size.square(s), painter: _PeintreJauge(valeur: valeur)),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    valeur.round().toString(),
                    style: TextStyle(
                      fontSize: s * 0.22,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('sur 100', style: TextStyle(fontSize: s * 0.045, color: Colors.white.withValues(alpha: 0.6))),
                ]),
              ),
              pastille(0.14, const Alignment(-1, -0.7), '+4', 'à temps'),
              pastille(0.5, const Alignment(0, 0.92), '', '1res places', icone: Icons.lock_open_rounded),
            ]);
          },
        ),
      );
    });
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.points, required this.texte, required this.taille, this.icone});

  final String points;
  final String texte;
  final double taille;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
          child: icone != null
              ? Icon(icone, size: 16, color: AppColors.lime)
              : Text(points, style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Text(texte, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

class _PeintreJauge extends CustomPainter {
  _PeintreJauge({required this.valeur});

  final double valeur;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: s * 0.36);
    const debut = math.pi * 5 / 6;
    const ouverture = math.pi * 4 / 3;
    final epaisseur = s * 0.075;
    canvas.drawCircle(c, s * 0.29, Paint()..color = Colors.white.withValues(alpha: 0.05));
    canvas.drawArc(
      rect,
      debut,
      ouverture,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = StrokeCap.round,
    );
    if (valeur <= 0) return;
    final balayage = ouverture * valeur / 100;
    canvas.drawArc(
      rect,
      debut,
      balayage,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: debut,
          endAngle: debut + ouverture,
          colors: const [AppColors.mint, AppColors.lime],
          transform: const GradientRotation(0),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = StrokeCap.round,
    );
    final a = debut + balayage;
    final bout = c + Offset(math.cos(a), math.sin(a)) * s * 0.36;
    canvas.drawCircle(bout, epaisseur * 0.62, Paint()..color = Colors.white);
    canvas.drawCircle(bout, epaisseur * 0.32, Paint()..color = AppColors.lime);
  }

  @override
  bool shouldRepaint(_PeintreJauge old) => old.valeur != valeur;
}

// ---------------------------------------------------------------------------------------------
// 3. La preuve : les reçus de cotisation arrivent, confirmés, puis le sceau du registre.

class IllustrationPreuve extends StatefulWidget {
  const IllustrationPreuve({super.key});

  @override
  State<IllustrationPreuve> createState() => _PreuveState();
}

class _PreuveState extends State<IllustrationPreuve> with SingleTickerProviderStateMixin, _Boucle {
  @override
  Duration get duree => const Duration(seconds: 7);

  static const _recus = [
    ('Tour 1', 'Paul'),
    ('Tour 2', 'Awa'),
    ('Tour 3', 'Joëlle'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(math.min(c.maxWidth, c.maxHeight), 340.0);
      final largeurRecu = math.min(c.maxWidth, 360.0) * 0.94;
      return SizedBox(
        width: math.min(c.maxWidth, 360.0),
        height: s,
        child: AnimatedBuilder(
          animation: boucle,
          builder: (context, _) {
            final t = boucle.value;
            final sortie = 1 - _entre(t, 0.92, 1);
            final sceau = Curves.easeOutBack.transform(_entre(t, 0.62, 0.74)) * sortie;
            return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.lime.withValues(alpha: 0.12), AppColors.lime.withValues(alpha: 0)]),
                ),
              ),
              for (var k = 0; k < _recus.length; k++)
                Builder(builder: (_) {
                  final v = Curves.easeOutCubic.transform(_entre(t, 0.06 + k * 0.16, 0.22 + k * 0.16)) * sortie;
                  final profondeur = (_recus.length - 1 - k).toDouble(); // 0 = devant
                  return Opacity(
                    opacity: profondeur == 0 ? v : (v > 0.02 ? 1 : 0),
                    child: Transform.translate(
                      offset: Offset(0, s * 0.1 - profondeur * s * 0.17 + 70 * (1 - v)),
                      child: Transform.rotate(
                        angle: (k - 1) * 0.035,
                        child: Transform.scale(
                          scale: 1 - profondeur * 0.06,
                          child: _Recu(tour: _recus[k].$1, par: _recus[k].$2, largeur: largeurRecu, devant: profondeur == 0, sceau: profondeur == 0 ? sceau : 0),
                        ),
                      ),
                    ),
                  );
                }),
            ]);
          },
        ),
      );
    });
  }
}

class _Recu extends StatelessWidget {
  const _Recu({required this.tour, required this.par, required this.largeur, required this.devant, this.sceau = 0});

  final String tour;
  final String par;
  final double largeur;
  final bool devant;
  final double sceau; // 0 à 1 : le tampon du registre qui se pose

  @override
  Widget build(BuildContext context) {
    final taille = largeur * 0.27;
    return Stack(clipBehavior: Clip.none, children: [
      _carte(),
      if (sceau > 0)
        Positioned(
          right: -taille * 0.18,
          bottom: -taille * 0.42,
          child: Opacity(
            opacity: sceau.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: -0.22 + 0.1 * sceau,
              child: Transform.scale(scale: 1.6 - 0.6 * sceau, child: _Sceau(taille: taille)),
            ),
          ),
        ),
    ]);
  }

  Widget _carte() {
    return Container(
      width: largeur,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tour, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              const Text('10 000 FCFA',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textDark, letterSpacing: -0.3)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_rounded, size: 14, color: AppColors.darkGreen),
              SizedBox(width: 3),
              Text('Confirmée', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
            ]),
          ),
        ]),
      ]),
    );
  }
}

/// Le sceau du registre : un tampon rond, lisible d'un coup d'œil.
class _Sceau extends StatelessWidget {
  const _Sceau({required this.taille});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lime,
        border: Border.all(color: AppColors.darkGreen, width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Container(
        margin: EdgeInsets.all(taille * 0.07),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.5), width: 1.2),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.verified_rounded, color: AppColors.darkGreen, size: taille * 0.34),
          Text('INSCRIT AU',
              style: TextStyle(fontSize: taille * 0.085, fontWeight: FontWeight.w600, color: AppColors.darkGreen, letterSpacing: 0.6)),
          Text('REGISTRE',
              style: TextStyle(fontSize: taille * 0.11, fontWeight: FontWeight.w600, color: AppColors.darkGreen, letterSpacing: 0.8)),
        ]),
      ),
    );
  }
}
