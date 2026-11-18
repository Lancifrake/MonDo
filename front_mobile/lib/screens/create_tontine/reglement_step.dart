import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tontine_draft.dart';
import '../../models/api_models.dart';
import '../../providers/cercles_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/counter_row.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';

/// Étape 3 : le rythme, la première échéance, les pénalités et les frais par place.
/// Tout ce qui est ici est signé et ne se modifie plus.
class ReglementStep extends ConsumerWidget {
  const ReglementStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged;

  void _update(VoidCallback change) {
    change();
    if (draft.delaiGraceJours > draft.graceMax) draft.delaiGraceJours = draft.graceMax;
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = draft;
    final bareme = ref.watch(baremeProvider((nombreMembres: d.nombreMembres, montant: d.montant)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('À quel rythme ?'),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Chaque semaine',
          subtitle: 'Un tour tous les 7 jours',
          selected: d.frequence == 'hebdomadaire',
          onTap: () => _update(() => d.frequence = 'hebdomadaire'),
        ),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Chaque mois',
          subtitle: 'Le même jour chaque mois',
          selected: d.frequence == 'mensuelle',
          onTap: () => _update(() => d.frequence = 'mensuelle'),
        ),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Tous les X jours',
          subtitle: 'Un rythme sur mesure, de 1 à 60 jours',
          selected: d.frequence == 'jours',
          onTap: () => _update(() => d.frequence = 'jours'),
        ),
        if (d.frequence == 'jours') ...[
          const SizedBox(height: 10),
          CounterRow(
            label: 'Jours entre deux tours',
            value: d.periodeJours,
            onMinus: d.periodeJours > 2 ? () => _update(() => d.periodeJours--) : null,
            onPlus: d.periodeJours < 60 ? () => _update(() => d.periodeJours++) : null,
          ),
        ],
        const SizedBox(height: 24),
        const SectionLabel('Première échéance'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text(formatDate(d.datePremierTour.toIso8601String())),
          onPressed: () async {
            final choisie = await showDatePicker(
              context: context,
              initialDate: d.datePremierTour,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (choisie != null) {
              _update(() => d.datePremierTour = DateTime(choisie.year, choisie.month, choisie.day, 18));
            }
          },
        ),
        const SizedBox(height: 24),
        const SectionLabel('En cas de retard'),
        const SizedBox(height: 10),
        CounterRow(
          label: 'Délai de grâce (jours)',
          value: d.delaiGraceJours,
          onMinus: d.delaiGraceJours > 0 ? () => _update(() => d.delaiGraceJours--) : null,
          onPlus: d.delaiGraceJours < d.graceMax ? () => _update(() => d.delaiGraceJours++) : null,
        ),
        const SizedBox(height: 10),
        CounterRow(
          label: 'Pénalité (FCFA)',
          value: d.penaliteRetard,
          onMinus: d.penaliteRetard >= 500 ? () => _update(() => d.penaliteRetard -= 500) : null,
          onPlus: () => _update(() => d.penaliteRetard += 500),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Options'),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: d.rappels,
          onChanged: (v) => _update(() => d.rappels = v),
          title: const Text('Rappels avant chaque échéance'),
          subtitle: const Text('L’assistant prévient 3 jours puis 1 jour avant.'),
        ),
        if (!d.isPrivate) ...[
          CounterRow(
            label: 'Score minimum pour entrer',
            value: d.scoreMinimum ?? 0,
            onMinus: (d.scoreMinimum ?? 0) > 0 ? () => _update(() => d.scoreMinimum = (d.scoreMinimum ?? 0) - 5) : null,
            onPlus: (d.scoreMinimum ?? 0) < 100 ? () => _update(() => d.scoreMinimum = (d.scoreMinimum ?? 0) + 5) : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: d.parrainageAccepte,
            onChanged: (v) => _update(() => d.parrainageAccepte = v),
            title: const Text('Accepter les filleuls'),
            subtitle: const Text('Un filleul peut entrer sous le score minimum si son parrain est membre.'),
          ),
        ],
        const SizedBox(height: 10),
        CounterRow(
          label: 'Ma place souhaitée',
          value: d.placeSouhaitee ?? d.nombreMembres,
          onMinus: (d.placeSouhaitee ?? d.nombreMembres) > 1
              ? () => _update(() => d.placeSouhaitee = (d.placeSouhaitee ?? d.nombreMembres) - 1)
              : null,
          onPlus: (d.placeSouhaitee ?? d.nombreMembres) < d.nombreMembres
              ? () => _update(() => d.placeSouhaitee = (d.placeSouhaitee ?? d.nombreMembres) + 1)
              : null,
        ),
        const Text(
          'Recevoir tôt dépend de ton score : la dernière place est toujours permise.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Frais par place'),
        const SizedBox(height: 6),
        const Text(
          'Recevoir tôt coûte des frais ; les dernières places reçoivent une remise. Calculé par MonDo.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        bareme.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Barème indisponible : $e', style: const TextStyle(color: Colors.red)),
          data: (liste) => _Bareme(liste: liste),
        ),
        const SizedBox(height: 16),
        const Text(
          'En créant la tontine, tu signes ce règlement avec la clé de ton téléphone. '
          'Il ne pourra plus être modifié.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }
}

class _Bareme extends StatelessWidget {
  const _Bareme({required this.liste});

  final List<FraisPlace> liste;

  @override
  Widget build(BuildContext context) {
    if (liste.isEmpty) {
      return const Text('Aucun frais pour cette tontine.', style: TextStyle(color: AppColors.textMuted));
    }
    return Column(
      children: [
        for (final f in liste)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('Place ${f.place}')),
                Text('${formatAmount(f.frais)} FCFA', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}
