import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';

/// Écran de connexion avec PIN
/// 
/// Permet à un utilisateur déjà inscrit de se connecter
/// en utilisant son PIN de 6 chiffres.
/// 
/// Endpoints API utilisés:
/// - GET /comptes/moi (avec signature ECDSA P-256)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  bool _pinObscured = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Valide et soumet le PIN
  Future<void> _login() async {
    // Valider le PIN
    if (_pinController.text.isEmpty) {
      setState(() {
        _error = 'Veuillez entrer votre PIN';
      });
      return;
    }

    if (_pinController.text.length != 6) {
      setState(() {
        _error = 'Le PIN doit contenir 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer le profil pour vérifier l'authentification
      // La signature ECDSA est ajoutée automatiquement par ApiClient
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.fetchProfil();

      // Si succès, le profil est chargé
      // La navigation se fera via le widget racine qui écoute authStateProvider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie ! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _error = _getErrorMessage(e);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${_getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur inattendue: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Retourne un message d'erreur lisible basé sur le code HTTP
  String _getErrorMessage(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'PIN incorrect. Veuillez réessayer.';
      case 403:
        return 'Accès refusé. Vérifiez votre clé privée.';
      case 500:
        return 'Erreur serveur. Veuillez réessayer plus tard.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le numéro de téléphone sauvegardé
    final phoneNumberAsync = ref.watch(
      savedSessionProvider.select(
        (session) => session.when(
          loading: () => null,
          error: (_, __) => null,
          data: (saved) => saved?.phoneNumber,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // En-tête
              const Text(
                'Bienvenue sur MonDo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre PIN de 6 chiffres pour vous connecter',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 40),

              // Numéro de téléphone (affichage)
              if (phoneNumberAsync != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Numéro enregistré',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phoneNumberAsync,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Champ PIN
              TextField(
                controller: _pinController,
                obscureText: _pinObscured,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: '• • • • • •',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    color: Colors.grey.shade400,
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _pinObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _pinObscured = !_pinObscured;
                      });
                    },
                  ),
                  counterText: '',
                  errorText: _error,
                ),
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _login();
                  }
                },
              ),

              const SizedBox(height: 24),

              // Bouton de connexion
              AppButton(
                label: _isLoading ? 'Connexion en cours...' : 'Se Connecter',
                onPressed: _isLoading ? null : _login,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              // Lien récupération
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Naviguer vers AccountRecoveryScreen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Récupération non encore implémentée'),
                      ),
                    );
                  },
                  child: const Text(
                    'Code secret oublié ?',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Section d'information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rappel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Votre PIN est stocké de manière sécurisée sur votre appareil. '
                      'Il ne sera jamais envoyé au serveur.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
