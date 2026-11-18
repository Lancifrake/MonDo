import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

/// EXEMPLE D'INTÉGRATION - Écran d'inscription
/// 
/// Cet exemple montre comment connecter un écran existant à l'API
/// Adapter le code à votre interface réelle
class SignupScreenExample extends ConsumerStatefulWidget {
  const SignupScreenExample({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreenExample> createState() =>
      _SignupScreenExampleState();
}

class _SignupScreenExampleState extends ConsumerState<SignupScreenExample> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  int _step = 0; // 0: demander OTP, 1: entrer OTP, 2: données

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Étape 1: Demander le code OTP
  Future<void> _requestOtp() async {
    final authNotifier = ref.read(authStateProvider.notifier);

    try {
      await authNotifier.requestOtp(_phoneController.text);
      setState(() => _step = 1);

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code OTP envoyé par SMS')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.message}')),
        );
      }
    }
  }

  /// Étape 2: Valider l'OTP et entrer le nom
  void _validateOtp() {
    setState(() => _step = 2);
  }

  /// Étape 3: Finaliser l'inscription
  Future<void> _finishSignup() async {
    final authNotifier = ref.read(authStateProvider.notifier);

    try {
      await authNotifier.signup(
        phoneNumber: _phoneController.text,
        nom: _nameController.text,
        otp: _otpController.text,
      );

      if (mounted) {
        // Inscription réussie - naviguer vers l'écran d'accueil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigator.pushReplacementNamed(context, '/home');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Étape 1: Numéro de téléphone
            if (_step == 0) ...[
              const Text('Étape 1: Numéro de téléphone'),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '237123456789',
                  prefixText: '+',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _requestOtp,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Demander le code'),
              ),
            ],

            // Étape 2: Code OTP
            if (_step == 1) ...[
              const Text('Étape 2: Code OTP'),
              const SizedBox(height: 16),
              const Text(
                'Un code OTP a été envoyé par SMS',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Code OTP',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _validateOtp,
                child: const Text('Continuer'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('Retour'),
              ),
            ],

            // Étape 3: Données personnelles
            if (_step == 2) ...[
              const Text('Étape 3: Données personnelles'),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  hintText: 'Jean Dupont',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _finishSignup,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Terminer l\'inscription'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Retour'),
              ),
            ],

            // Affichage des erreurs
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  authState.error!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
