import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';
import 'screens/pin_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

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
      home: const _Demarrage(),
    );
  }
}

/// Au lancement : si la clé de l'appareil est déjà là, on entre directement.
class _Demarrage extends ConsumerStatefulWidget {
  const _Demarrage();

  @override
  ConsumerState<_Demarrage> createState() => _DemarrageState();
}

class _DemarrageState extends ConsumerState<_Demarrage> {
  /// null : pas de compte ; false : compte sans PIN ; true : compte avec PIN à demander.
  late final Future<bool?> _session = () async {
    final ok = await ref.read(authStateProvider.notifier).restaurerSession();
    if (!ok) return null;
    return pinDefini();
  }();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _session,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return switch (snap.data) {
          null => const WelcomeScreen(),
          true => const PinScreen(verifier: true),
          false => const MainShell(),
        };
      },
    );
  }
}
