import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'compte/compte_demo_screen.dart';
import 'compte/recuperation_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/accueil_illustrations.dart';
import '../widgets/app_button.dart';
import '../widgets/logo_mondo.dart';
import 'signup_screen.dart';

/// Une page de l'accueil : sa couleur, son illustration et ses deux phrases.
class _Page {
  const _Page({
    required this.fond,
    required this.encre,
    required this.bouton,
    required this.texteBouton,
    required this.titre,
    required this.texte,
    required this.illustration,
  });

  final Color fond;
  final Color encre;
  final Color bouton;
  final Color texteBouton;
  final String titre;
  final String texte;
  final Widget illustration;
}

// Un seul fond, sobre : la couleur vient des illustrations, pas de la page.
const _pages = [
  _Page(
    fond: AppColors.darkGreen,
    encre: Colors.white,
    bouton: AppColors.lime,
    texteBouton: AppColors.darkGreen,
    titre: 'Ta tontine,\nsans palabres.',
    texte: '',
    illustration: IllustrationCercle(),
  ),
  _Page(
    fond: AppColors.darkGreen,
    encre: Colors.white,
    bouton: AppColors.lime,
    texteBouton: AppColors.darkGreen,
    titre: 'Ton sérieux\ndevient un score.',
    texte: '',
    illustration: IllustrationScore(),
  ),
  _Page(
    fond: AppColors.darkGreen,
    encre: Colors.white,
    bouton: AppColors.lime,
    texteBouton: AppColors.darkGreen,
    titre: 'Chaque franc,\nprouvé.',
    texte: '',
    illustration: IllustrationPreuve(),
  ),
];

/// Accueil : trois pages qui défilent seules (comme des stories), on peut aussi les balayer.
/// Les boutons restent en bas, pour qu'un habitué n'ait rien à faire défiler.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final _defilement = PageController();
  late final AnimationController _progres = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _suivante();
    });
  double _position = 0;
  int _index = 0;
  bool _anime = true;

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      setState(() => _position = (_defilement.page ?? 0).clamp(0, _pages.length - 1).toDouble());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _anime = !MediaQuery.of(context).disableAnimations;
    if (_anime && !_progres.isAnimating && _progres.value == 0) _progres.forward();
  }

  @override
  void dispose() {
    _progres.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _suivante() {
    _defilement.animateToPage(
      (_index + 1) % _pages.length,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chaque page a son propre fond, qui glisse avec elle. L'en-tête et les boutons, posés par-dessus,
    // prennent les couleurs de la page la plus visible, en fondu.
    final proche = _pages[_position.round().clamp(0, _pages.length - 1)];
    final hauteurBas = 8 + 56 + 12 + 56 + (comptesDemoActifs ? 48 : 8) + 8.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: proche.fond.computeLuminance() > 0.5 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: proche.fond,
        body: Stack(children: [
          Positioned.fill(
            child: Listener(
              // Un doigt posé met la page en pause, comme une story.
              onPointerDown: (_) => _progres.stop(),
              onPointerUp: (_) => _anime ? _progres.forward() : null,
              onPointerCancel: (_) => _anime ? _progres.forward() : null,
              child: PageView.builder(
                controller: _defilement,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  if (_anime) _progres.forward(from: 0);
                },
                itemBuilder: (context, i) => ColoredBox(
                  color: _pages[i].fond,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(top: 70, bottom: hauteurBas),
                      child: _Contenu(page: _pages[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _EnFondu(
              encre: proche.encre,
              bouton: proche.bouton,
              texteBouton: proche.texteBouton,
              builder: (encre, bouton, texteBouton) => Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(children: [
                    LogoMonDo(taille: 34, couleur: encre),
                    const SizedBox(width: 10),
                    Text('MonDo', style: TextStyle(color: encre, fontSize: 22, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _Barres(nombre: _pages.length, index: _index, progres: _progres, couleur: encre, anime: _anime),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Column(children: [
                    AppButton(
                      label: 'Créer mon compte',
                      background: bouton,
                      foreground: texteBouton,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: "J'ai déjà un compte",
                      background: Colors.transparent,
                      foreground: encre,
                      borderColor: encre.withValues(alpha: 0.3),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecuperationScreen()),
                      ),
                    ),
                    if (comptesDemoActifs)
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CompteDemoScreen()),
                        ),
                        child: Text(
                          'Utiliser un compte de démonstration',
                          style: TextStyle(color: encre.withValues(alpha: 0.8)),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Les couleurs de l'en-tête et des boutons passent d'une page à l'autre en fondu court.
class _EnFondu extends StatelessWidget {
  const _EnFondu({required this.encre, required this.bouton, required this.texteBouton, required this.builder});

  final Color encre;
  final Color bouton;
  final Color texteBouton;
  final Widget Function(Color encre, Color bouton, Color texteBouton) builder;

  @override
  Widget build(BuildContext context) {
    const duree = Duration(milliseconds: 280);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: encre),
      duration: duree,
      builder: (context, e, _) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: bouton),
        duration: duree,
        builder: (context, b, _) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: texteBouton),
          duration: duree,
          builder: (context, tb, _) => builder(e ?? encre, b ?? bouton, tb ?? texteBouton),
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Center(child: page.illustration),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            page.titre,
            style: TextStyle(
              color: page.encre,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 1.05,
              letterSpacing: -1,
            ),
          ),
        ),
        if (page.texte.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              page.texte,
              style: TextStyle(color: page.encre.withValues(alpha: 0.78), fontSize: 16, height: 1.45),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Les barres de progression en haut, une par page.
class _Barres extends StatelessWidget {
  const _Barres({
    required this.nombre,
    required this.index,
    required this.progres,
    required this.couleur,
    required this.anime,
  });

  final int nombre;
  final int index;
  final Animation<double> progres;
  final Color couleur;
  final bool anime;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progres,
      builder: (context, _) => Row(children: [
        for (var k = 0; k < nombre; k++) ...[
          if (k > 0) const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 3,
                value: k < index ? 1 : (k == index ? (anime ? progres.value : 1) : 0),
                backgroundColor: couleur.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation(couleur),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
