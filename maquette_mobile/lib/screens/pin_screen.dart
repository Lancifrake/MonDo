import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/pin_pad.dart';
import 'main_shell.dart';

class PinScreen extends StatelessWidget {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Choisis ton code PIN'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ce code à 4 chiffres protège l'application sur ce téléphone.",
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            PinPad(
              onCompleted: (_) => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}