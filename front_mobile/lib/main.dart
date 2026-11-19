import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/compte/recuperation_screen.dart';
import 'screens/main_shell.dart';
import 'services/recuperation_locale.dart';
import 'screens/pin_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/logo_mondo.dart';

void main() {
  runApp(const ProviderScope(child: MonDoApp()));
}

class MonDoApp extends StatelessWidget {
  const MonDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonDo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Suit le réglage du téléphone (clair ou sombre).
      themeMode: ThemeMode.system,
      builder: (context, enfant) => _SuiviDuMode(
        sombre: Theme.of(context).brightness == Brightness.dark,
        child: enfant!,
      ),
      home: const _Demarrage(),
    );
  }
}

/// Règle [AppColors.sombre] avant chaque construction, et redessine tous les écrans ouverts quand
/// le téléphone passe du clair au sombre : les couleurs de l'app sont lues dans [AppColors],
/// pas dans le thème, donc un simple changement de thème ne suffirait pas à les mettre à jour.
class _SuiviDuMode extends StatefulWidget {
  const _SuiviDuMode({required this.sombre, required this.child});

  final bool sombre;
  final Widget child;

  @override
  State<_SuiviDuMode> createState() => _SuiviDuModeState();
}

class _SuiviDuModeState extends State<_SuiviDuMode> {
  @override
  void initState() {
    super.initState();
    AppColors.sombre = widget.sombre;
  }

  @override
  void didUpdateWidget(_SuiviDuMode ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.sombre == widget.sombre) return;
    AppColors.sombre = widget.sombre;
    void toutReconstruire(Element e) {
      e.markNeedsBuild();
      e.visitChildren(toutReconstruire);
    }

    (context as Element).visitChildren(toutReconstruire);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Au lancement : si la clé de l'appareil est déjà là, on entre directement.
class _Demarrage extends ConsumerStatefulWidget {
  const _Demarrage();

  @override
  ConsumerState<_Demarrage> createState() => _DemarrageState();
}

class _DemarrageState extends ConsumerState<_Demarrage> {
  /// null : pas de compte ; false : compte sans PIN ; true : compte avec PIN à demander.
  RecuperationLocale? _reprise;

  // Le logo tourne au moins un tour et demi, même si la session s'ouvre plus vite.
  late final Future<bool?> _session = () async {
    final r = await Future.wait<Object?>([_ouvrirSession(), Future<void>.delayed(const Duration(milliseconds: 2100))]);
    return r[0] as bool?;
  }();

  Future<bool?> _ouvrirSession() async {
    final ok = await ref.read(authStateProvider.notifier).restaurerSession();
    if (!ok) {
      _reprise = await RecuperationLocale.lire(); // récupération demandée ici et pas encore aboutie
      return null;
    }
    return pinDefini();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _session,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const EcranDeDemarrage();
        }
        return switch (snap.data) {
          null => _reprise != null ? RecuperationScreen(reprise: _reprise) : const WelcomeScreen(),
          true => const PinScreen(verifier: true),
          false => const MainShell(),
        };
      },
    );
  }
}
