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
          'Il ne pourra plus être modifié. Tu prends la dernière place.',
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
