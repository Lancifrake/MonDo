import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/counter_row.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/switch_card.dart';
import '../../widgets/two_column_grid.dart';

class TurnsStep extends StatelessWidget {
  const TurnsStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged;

  void _update(VoidCallback change) {
    change();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final d = draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Comment décider de l'ordre des tours ?"),
        const SizedBox(height: 10),
        TwoColumnGrid(
          children: [
            SelectableCard(
              compact: true,
              title: 'Tirage au sort',
              subtitle: 'Public, vérifiable par tous',
              selected: d.orderMode == 'draw',
              onTap: () => _update(() => d.orderMode = 'draw'),
            ),
            SelectableCard(
              compact: true,
              title: 'Ordre choisi',
              subtitle: "Fixé à l'avance par l'organisateur",
              selected: d.orderMode == 'chosen',
              onTap: () => _update(() => d.orderMode = 'chosen'),
            ),
            SelectableCard(
              compact: true,
              title: 'Ordre négocié',
              subtitle: "Les membres s'arrangent entre eux",
              selected: d.orderMode == 'negotiated',
              onTap: () => _update(() => d.orderMode = 'negotiated'),
            ),
            SelectableCard(
              compact: true,
              title: 'Enchères',
              subtitle: 'Le tour va au plus offrant',
              badge: 'Bientôt',
              enabled: false,
              selected: false,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchCard(
          title: 'Les membres peuvent échanger leur place',
          subtitle: "Il faut l'accord des deux personnes.",
          value: d.allowSwap,
          onChanged: (value) => _update(() => d.allowSwap = value),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Qui reçoit les cotisations chaque tour ?'),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Le trésorier',
          subtitle: 'Il garde la caisse et rend des comptes à chaque réunion',
          selected: d.collector == 'treasurer',
          onTap: () => _update(() => d.collector = 'treasurer'),
        ),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Le bénéficiaire du tour',
          subtitle:
              'Chacun envoie sa part directement à la personne qui reçoit',
          selected: d.collector == 'beneficiary',
          onTap: () => _update(() => d.collector = 'beneficiary'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Dans les deux cas, la personne confirme chaque paiement et '
          'personne ne valide son propre paiement.',
          style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Quand le bénéficiaire reçoit-il la cagnotte ?'),
        const SizedBox(height: 10),
        TwoColumnGrid(
          children: [
            SelectableCard(
              compact: true,
              title: 'Tout de suite',
              subtitle: 'Dès que tout est payé',
              selected: d.payout == 'immediate',
              onTap: () => _update(() => d.payout = 'immediate'),
            ),
            SelectableCard(
              compact: true,
              title: 'À une date fixée',
              subtitle: 'Par exemple à la réunion',
              selected: d.payout == 'fixedDate',
              onTap: () => _update(() => d.payout = 'fixedDate'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchCard(
          title: 'Il faut être à jour pour recevoir',
          subtitle:
              "Celui qui n'a pas payé ses cotisations ne reçoit pas la cagnotte.",
          value: d.requireUpToDate,
          onChanged: (value) => _update(() => d.requireUpToDate = value),
        ),
        const SizedBox(height: 16),
        CounterRow(
          label: "Part gardée pour l'entraide",
          valueText: '${d.solidarityPercent} %',
          onMinus: d.solidarityPercent > 0
              ? () => _update(() => d.solidarityPercent -= 5)
              : null,
          onPlus: d.solidarityPercent < 50
              ? () => _update(() => d.solidarityPercent += 5)
              : null,
        ),
      ],
    );
  }
}