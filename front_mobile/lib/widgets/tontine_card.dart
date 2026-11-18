import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'app_card.dart';

/// Une tontine dans « Mes tontines » : du texte, un filet, le statut en texte.
/// Pas d'icône sur pastille ni de barre : le remplissage s'écrit en pourcentage.
class TontineCard extends StatelessWidget {
  const TontineCard({super.key, required this.tontine, this.onTap});

  final Tontine tontine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = tontine;
    final aPayer = t.status == PaymentStatus.aPayer;
    final remplissage = (t.progress * 100).round();
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(t.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Text(
                aPayer ? 'à payer' : 'à jour',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: aPayer ? AppColors.orange : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              t.frequency,
              '${t.members} ${t.members > 1 ? 'membres' : 'membre'} sur ${t.totalMembers}',
              if (remplissage < 100) 'rempli à $remplissage %',
              if (t.isTreasurer) 'tu l’organises',
            ].join(' · '),
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 10),
          Text('${formatAmount(t.amount)} FCFA par tour', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
