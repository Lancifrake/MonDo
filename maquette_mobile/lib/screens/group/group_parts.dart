import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../data/group_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/rules_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/ring_progress.dart';
import '../../widgets/status_badge.dart';

const _greyBadge = Color(0xFFEBEDE7);

// Haut de page : tour en cours, cagnotte, bénéficiaire
class RunningSummaryCard extends StatelessWidget {
  const RunningSummaryCard({
    super.key,
    required this.tontine,
    required this.progress,
  });

  final CatalogTontine tontine;
  final TontineProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: 'Tour ${p.currentTurn} sur ${p.totalTurns}',
                background: AppColors.mint,
                foreground: AppColors.green,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: tontine.isPrivate ? 'Privée' : 'Ouverte',
                icon: tontine.isPrivate ? Icons.lock_outline : Icons.public,
                background: _greyBadge,
                foreground: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RingProgress(
                value: p.collectedPercent / 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${p.collectedPercent}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'collecté',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cagnotte du tour ${p.currentTurn}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatAmount(p.pot),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(
                            text: ' FCFA',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'sur ${fcfa(p.potTarget)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.amberText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFE9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                PersonAvatar(name: p.beneficiary, index: 4),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bénéficiaire de ce tour',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    Text(
                      p.beneficiary,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Carte verte « Ta cotisation »
class MyContributionCard extends StatelessWidget {
  const MyContributionCard({
    super.key,
    required this.tontine,
    required this.progress,
  });

  final CatalogTontine tontine;
  final TontineProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.schedule, size: 16, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ta cotisation · ${tontine.name}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatAmount(tontine.rules.amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: '  FCFA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (progress.paidThisTurn)
            const StatusBadge(
              label: 'Payée pour ce tour',
              icon: Icons.check,
              background: AppColors.mint,
              foreground: AppColors.darkGreen,
            )
          else ...[
            StatusBadge(
              label: 'À payer avant ${deadlineValue(tontine.rules)}',
              background: AppColors.amberBg,
              foreground: AppColors.amberText,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Déclarer mon paiement',
              background: AppColors.lime,
              foreground: AppColors.darkGreen,
              onPressed: () {}, // écran de déclaration à venir
            ),
          ],
        ],
      ),
    );
  }
}

Widget _payBadge(PayStatus status) => switch (status) {
      PayStatus.pending => const StatusBadge(
          label: 'En attente',
          background: AppColors.amberBg,
          foreground: AppColors.amberText,
        ),
      PayStatus.late => const StatusBadge(
          label: 'En retard',
          background: Color(0xFFFBE3E0),
          foreground: Color(0xFFB3362B),
        ),
      PayStatus.paid => const StatusBadge(
          label: 'Payé',
          background: AppColors.mint,
          foreground: AppColors.green,
        ),
    };

// « Qui a payé ce tour »
class PayersCard extends StatelessWidget {
  const PayersCard({super.key, required this.progress});

  final TontineProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < p.payers.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  PersonAvatar(name: p.payers[i].name, index: i, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.payers[i].name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _payBadge(p.payers[i].status),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
          if (p.hiddenPayers > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'et ${p.hiddenPayers} autres',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// Une ligne du « Carnet du groupe »
class LedgerEntryCard extends StatelessWidget {
  const LedgerEntryCard({super.key, required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final number = entry.number.toString().padLeft(4, '0');

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.link, size: 18, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$number · ${entry.label}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'empreinte ',
                        style: TextStyle(color: AppColors.amberText),
                      ),
                      TextSpan(
                        text: entry.hash,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const TextSpan(
                        text: ' · ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const TextSpan(
                        text: 'précédente ',
                        style: TextStyle(color: AppColors.link),
                      ),
                      TextSpan(
                        text: entry.previous,
                        style: const TextStyle(color: AppColors.link),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}