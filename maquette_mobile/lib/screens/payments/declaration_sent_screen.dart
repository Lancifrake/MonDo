import 'package:flutter/material.dart';
import '../../data/payments_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/summary_card.dart';

class DeclarationSentScreen extends StatelessWidget {
  const DeclarationSentScreen({super.key, required this.declaration});

  final Declaration declaration;

  @override
  Widget build(BuildContext context) {
    final d = declaration;

    return Scaffold(
      appBar: buildAppBar(context, 'Ma déclaration'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.blueBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: AppColors.link,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Déclaration envoyée',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'La personne qui encaisse va la vérifier. Tu seras notifié.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatAmount(d.amount),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: '  FCFA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const StatusBadge(
                        label: 'En attente de validation',
                        background: AppColors.blueBg,
                        foreground: AppColors.link,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SummaryCard(
                    rows: [
                      SummaryRow('Groupe', d.groupLabel),
                      SummaryRow('Payé par', d.payer),
                      SummaryRow('Mode', d.modeLabel),
                      if (d.reference != null)
                        SummaryRow('Référence', d.reference!),
                      const SummaryRow('Date', "À l'instant"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: "Retour à l'accueil",
              background: Colors.white,
              foreground: AppColors.textDark,
              borderColor: AppColors.border,
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}