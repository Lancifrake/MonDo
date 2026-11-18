import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/storage_provider.dart';

/// EXEMPLE D'INTÉGRATION - Initialisation de l'Application
/// 
/// Cet exemple montre comment initialiser l'app au démarrage
/// et restaurer la session sauvegardée

class AppInitialization extends ConsumerWidget {
  const AppInitialization({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarder si une session existe
    final hasSessionAsync = ref.watch(hasSessionProvider);
    final savedSessionAsync = ref.watch(savedSessionProvider);

    return hasSessionAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) {
        // En cas d'erreur lors de la vérification de session,
        // afficher l'écran de login
        return const _LoginRouteScreen();
      },
      data: (hasSession) {
        if (!hasSession) {
          // Aucune session sauvegardée -> écran de login
          return const _LoginRouteScreen();
        }

        // Une session existe -> vérifier les détails
        return savedSessionAsync.when(
          loading: () => const _LoadingScreen(),
          error: (error, stackTrace) => const _LoginRouteScreen(),
          data: (savedSession) {
            if (savedSession == null) {
              // Session corrompue -> retour au login
              return const _LoginRouteScreen();
            }

            // Session valide -> charger le profil et naviguer vers l'accueil
            return _RestoreSessionAndNavigate(savedSession: savedSession);
          },
        );
      },
    );
  }
}

/// Écran de chargement
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text('Initialisation...'),
          ],
        ),
      ),
    );
  }
}

/// Écran de route de login
class _LoginRouteScreen extends StatelessWidget {
  const _LoginRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 64),
            const SizedBox(height: 24),
            const Text('Bienvenue sur MonDo'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers l'écran d'inscription
                // Navigator.pushNamed(context, '/signup');
              },
              child: const Text('S\'inscrire'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // Naviguer vers l'écran de récupération
                // Navigator.pushNamed(context, '/recovery');
              },
              child: const Text('Récupérer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget qui restaure la session et navigue
class _RestoreSessionAndNavigate extends ConsumerStatefulWidget {
  final SavedSession savedSession;

  const _RestoreSessionAndNavigate({
    required this.savedSession,
  });

  @override
  ConsumerState<_RestoreSessionAndNavigate> createState() =>
      _RestoreSessionAndNavigateState();
}

class _RestoreSessionAndNavigateState
    extends ConsumerState<_RestoreSessionAndNavigate> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  /// Restaure la session sauvegardée
  Future<void> _restoreSession() async {
    try {
      // Récupérer le service d'authentification
      final authNotifier = ref.read(authStateProvider.notifier);

      // Récupérer le profil depuis le serveur pour vérifier que
      // la session est toujours valide
      final authService = ref.read(authServiceProvider);
      final compte = await authService.getMoi();

      // Mettre à jour l'état
      ref.read(authStateProvider.notifier).state = AuthState(
        compte: compte,
      );

      // Naviguer vers l'écran d'accueil
      if (mounted) {
        // Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // La session est invalide (erreur 401 probablement)
      // Effacer les données et retour au login
      try {
        final storage = ref.read(localStorageProvider);
        await storage.clearSession();
      } catch (_) {}

      ref.read(authStateProvider.notifier).logout();

      if (mounted) {
        // Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Restauration de votre session...'),
          ],
        ),
      ),
    );
  }
}

/// EXEMPLE COMPLET: Écran racine de l'app
class AppRootExample extends ConsumerWidget {
  const AppRootExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarder l'état d'authentification
    final authState = ref.watch(authStateProvider);

    // Routage basé sur l'authentification
    return MaterialApp(
      title: 'MonDo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: authState.isAuthenticated
          ? const _HomeScreenPlaceholder() // Écran d'accueil
          : const AppInitialization(), // Écran d'initialisation/login
      routes: {
        '/signup': (_) => const _SignupScreenPlaceholder(),
        '/recovery': (_) => const _RecoveryScreenPlaceholder(),
        '/home': (_) => const _HomeScreenPlaceholder(),
      },
    );
  }
}

// Placeholders pour les écrans (à implémenter avec vos widgets réels)
class _SignupScreenPlaceholder extends StatelessWidget {
  const _SignupScreenPlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Inscription')),
        body: const Center(child: Text('Écran d\'inscription')),
      );
}

class _RecoveryScreenPlaceholder extends StatelessWidget {
  const _RecoveryScreenPlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Récupération')),
        body: const Center(child: Text('Écran de récupération')),
      );
}

class _HomeScreenPlaceholder extends StatelessWidget {
  const _HomeScreenPlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Accueil')),
        body: const Center(child: Text('Écran d\'accueil')),
      );
}
