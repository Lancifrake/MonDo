import 'package:flutter/material.dart';
import '../data/tontine_draft.dart';
import '../theme/app_colors.dart';
import '../utils/rules_format.dart';
import 'summary_card.dart';

/// Les six cartes de règles : utilisées dans le résumé de création
/// et dans la fiche d'une tontine.
class RuleCards extends StatelessWidget {
  const RuleCards({
    super.key,
    required this.rules,
    this.orderColor = AppColors.link,
  });

  final TontineDraft rules;
  final Color orderColor; // couleur de « Tirage au sort »

  @override
  Widget build(BuildContext context) {
    final d = rules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryCard(
          title: 'Cotisation',
          rows: [
            SummaryRow('Montant', fcfa(d.amount)),
            SummaryRow('Rythme', frequencyLabel(d.frequency)),
            SummaryRow('Date limite', deadlineValue(d)),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Membres',
          rows: [
            SummaryRow(
              'Nombre de personnes',
              'de ${d.minMembers} à ${d.maxMembers}',
            ),
            SummaryRow('Arriver en cours de cycle', yesNo(d.joinMidCycle)),
            SummaryRow('Partir avant la fin', yesNo(d.leaveEarly)),
            SummaryRow('Remplacer un membre', yesNo(d.allowReplacement)),
            SummaryRow('En cas de décès', d.deathRule),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Tours et bénéficiaire',
          rows: [
            SummaryRow(
              'Ordre des tours',
              orderLabel(d.orderMode),
              valueColor: orderColor,
            ),
            SummaryRow('Échange de place entre membres', yesNo(d.allowSwap)),
            SummaryRow(
              'Versement',
              d.payout == 'immediate' ? 'Tout de suite' : 'À une date fixée',
            ),
            SummaryRow(
              'Il faut être à jour pour recevoir',
              yesNo(d.requireUpToDate),
            ),
            SummaryRow(
              "Part gardée pour l'entraide",
              d.solidarityPercent == 0 ? 'Aucune' : '${d.solidarityPercent} %',
            ),
            SummaryRow(
              'Qui reçoit les cotisations',
              d.collector == 'treasurer'
                  ? 'Le trésorier'
                  : 'Le bénéficiaire du tour',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Retards et impayés',
          rows: [
            SummaryRow('Délai avant pénalité', '${d.lateDelayDays} jours'),
                        SummaryRow(
              'Pénalité de retard',
              d.lateFeePerDay == 0
                  ? 'Aucune'
                  : '${fcfa(d.lateFeePerDay)} par jour de retard',
            ),
            SummaryRow(
              'Plafond des pénalités',
              d.lateFeeCap == 0 ? 'Aucun' : fcfa(d.lateFeeCap),
            ),
   
            SummaryRow('Absence à une réunion', d.absencePenalty),
            SummaryRow("Si quelqu'un ne paie pas", d.nonPaymentRule),
            SummaryRow('Rappels automatiques', yesNo(d.autoReminders)),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Argent liquide',
          rows: [
            SummaryRow('Témoin obligatoire', yesNo(d.cashWitness)),
            SummaryRow('Deux validations', yesNo(d.cashDoubleValidation)),
            SummaryRow(
              'Délai pour confirmer un paiement',
              '${d.cashConfirmHours} heures',
            ),
            SummaryRow(
              'Caisse vérifiée à chaque réunion',
              yesNo(d.cashCheckEveryMeeting),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Décisions du groupe',
          rows: [
            SummaryRow(
              'Présence minimale pour voter',
              '${d.voteMinPresencePercent} % des membres',
            ),
            SummaryRow("Pour qu'une décision passe", d.voteMajority),
            SummaryRow("Durée d'un vote", '${d.voteDurationHours} heures'),
          ],
        ),
      ],
    );
  }
}