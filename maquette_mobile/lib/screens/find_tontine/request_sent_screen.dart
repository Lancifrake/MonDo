import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';

class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, tontine.name),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 3),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Demande envoyée',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tontine.organizer} doit accepter ta demande.\n'
                      "Tu seras prévenu dès que c'est fait.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: "Retour à l'accueil",
              // Revient au premier écran de la pile : l'accueil
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}