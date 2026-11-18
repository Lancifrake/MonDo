import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../utils/rules_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/rule_cards.dart';
import '../../widgets/summary_card.dart';

// Le règlement en phrases simples, construit à partir des réponses
String _rulesText(TontineDraft d) {
  final deadline = deadlinePhrase(d);
  final deadlineText = deadline == null ? '' : ', au plus tard $deadline';

  final sentences = <String>[
    'Dans « ${d.name.trim()} », chaque membre verse ${fcfa(d.amount)} '
        '${frequencyPhrase(d.frequency)}$deadlineText.',
    d.collector == 'treasurer'
        ? 'Le paiement est remis au trésorier, qui le confirme.'
        : 'Chacun envoie sa part directement au bénéficiaire du tour, '
            'qui la confirme.',
    "L'ordre des tours est ${orderPhrase(d.orderMode)}.",
    'Après ${d.lateDelayDays} jours de retard : '
        '${fcfa(d.lateFeePerDay)} par jour de retard.',
    'Les décisions importantes se prennent par vote '
        '(${d.voteMajority.toLowerCase()}).',
  ];
  return sentences.join(' ');
}

class SummaryStep extends StatelessWidget {
  const SummaryStep({
    super.key,
    required this.draft,
    required this.onSign,
    required this.onEdit,
  });

  final TontineDraft draft;
  final VoidCallback onSign;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final d = draft;
    final roles = [...predefinedRoles, ...d.customRoles]
        .where(d.roles.contains)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RulesCard(text: _rulesText(d)),
        const SizedBox(height: 16),
        SummaryCard(
          rows: [
            SummaryRow('Nom', d.name.trim()),
            SummaryRow(
              'Visibilité',
              d.isPrivate ? 'Privée, sur invitation' : 'Ouverte, sur demande',
            ),
            SummaryRow(
              'Nouveaux membres',
              d.validateMembers ? 'Je les valide' : 'Ils entrent directement',
            ),
            SummaryRow('Postes', roles),
          ],
        ),
        const SizedBox(height: 12),
        RuleCards(rules: d, orderColor: AppColors.amberText),
        const SizedBox(height: 24),
        AppButton(
          label: "J'ai lu, je signe",
          icon: Icons.edit_outlined,
          onPressed: onSign,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: onEdit,
            child: const Text(
              'Modifier une réponse',
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

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le règlement, en phrases simples',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}