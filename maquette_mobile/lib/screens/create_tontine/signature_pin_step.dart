import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pin_pad.dart';

class SignaturePinStep extends StatelessWidget {
  const SignaturePinStep({
    super.key,
    required this.onConfirmed,
    required this.onCancel,
  });

  final VoidCallback onConfirmed; // code saisi : on signe
  final VoidCallback onCancel; // « Retour au résumé »

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirme avec ton code PIN',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          "En signant, tu t'engages à respecter ce règlement. "
          "Tous les membres le liront avant d'entrer.",
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        PinPad(onCompleted: (_) => onConfirmed()),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onCancel,
            child: const Text(
              'Retour au résumé',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }
}