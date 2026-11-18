import 'package:flutter/material.dart';
import '../data/user_data.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/pin_pad.dart';
import 'main_shell.dart';

class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  void _unlocked(BuildContext context) {
    // On vide la pile d'écrans : le retour ne ramène plus à la connexion
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le prénom viendra du compte retrouvé grâce au numéro (back end)
    final firstName = demoUser.name.split(' ').first;

    return Scaffold(
      appBar: buildAppBar(context, 'Bonjour $firstName'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Saisis ton code PIN pour ouvrir MonDo.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PinPad(onCompleted: (_) => _unlocked(context)),
                ],
              ),
            ),
          ),
          BottomBar(
            child: Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La récupération par SMS arrive bientôt'),
                    ),
                  );
                },
                child: const Text(
                  'Code PIN oublié ? Récupérer par SMS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}