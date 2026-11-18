import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/activity_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/summary_card.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final r = receipt;

    return Scaffold(
      appBar: buildAppBar(context, 'Reçu'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête centré
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cotisation validée',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Voici ton reçu numérique.',
                        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatAmount(r.amount),
                              style: const TextStyle(
                                fontSize: 40,
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
                        label: 'Validée',
                        background: AppColors.mint,
                        foreground: AppColors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SummaryCard(
                    rows: [
                      SummaryRow('Groupe', r.groupLabel),
                      SummaryRow('Payé par', r.payer),
                      SummaryRow('Mode', r.mode),
                      // Ces deux lignes dépendent du mode de paiement
                      if (r.receivedBy != null)
                        SummaryRow('Remis à', r.receivedBy!),
                      if (r.reference != null)
                        SummaryRow('Référence', r.reference!),
                      SummaryRow('Date', r.date),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QrImageView(
                          // Temporaire : le vrai lien de vérification viendra du serveur
                          data: 'mondo://recu/${r.number}',
                          version: QrVersions.auto,
                          size: 88,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.darkGreen,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reçu n° ${r.number}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Empreinte '),
                                    TextSpan(text: r.hash),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Scanne le QR pour vérifier ce reçu.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: 'Partager le reçu',
              icon: Icons.share_outlined,
              onPressed: () {
                // Le vrai partage (feuille de partage Android) viendra ensuite
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le partage arrive bientôt')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}