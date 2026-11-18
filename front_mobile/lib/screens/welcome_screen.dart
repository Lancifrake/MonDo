import 'package:flutter/material.dart';
import 'compte/recuperation_screen.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/logo_mondo.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // icônes claires sur fond sombre
      child: Scaffold(
        backgroundColor: AppColors.darkGreen,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Logo(),
                const Spacer(),
                const Text(
                  'Ta tontine, sans dispute, sans cahier, sans risque.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cotise en espèces ou en Mobile Money. Chaque paiement est confirmé par celui qui le reçoit '
                  'et inscrit au registre : l’argent ne passe jamais par MonDo.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'Créer mon compte',
                  background: AppColors.lime,
                  foreground: AppColors.darkGreen,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: "J'ai déjà un compte",
                  background: Colors.transparent,
                  foreground: Colors.white,
                  borderColor: Colors.white.withValues(alpha: 0.25),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecuperationScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        LogoMonDo(taille: 40),
        SizedBox(width: 10),
        Text('MonDo', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
