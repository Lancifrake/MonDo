import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';
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
  late final Future<bool> _session =
      ref.read(authStateProvider.notifier).restaurerSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data! ? const MainShell() : const WelcomeScreen();
      },
    );
  }
}
