import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/litiges_provider.dart';
import '../../widgets/sobre.dart';
import 'disputes_list_screen.dart' show decisionLitige;

/// Détail d'un litige (GET /litiges/:id). Le membre suit ; un administrateur tranche.
class DisputeDetailScreen extends ConsumerWidget {
  const DisputeDetailScreen({super.key, required this.litigeId});

  final String litigeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litige = ref.watch(litigeProvider(litigeId));
    final moi = ref.read(apiClientProvider).membreId;
    return Ecran(
      titre: 'Litige',
      enfants: selon(litige, (l) {
        final ouvertPar = switch (l.ouvertPar) {
          'payeur' => l.payeurId == moi ? 'moi, en tant que payeur' : 'le payeur',
          'beneficiaire' => l.beneficiaireId == moi ? 'moi, en tant que bénéficiaire' : 'le bénéficiaire',
          'automatique' => 'MonDo, automatiquement',
          _ => l.ouvertPar,
        };
        return [
          Text(
            switch (l.statut) { 'ouvert' => 'En examen', 'tranche' => 'Tranché : ${decisionLitige(l.decision)}', 'clos' => 'Clos', _ => l.statut },
            style: styleStatut(l.statut == 'ouvert' ? Ton.action : Ton.encre).copyWith(fontSize: 16),
          ),
          const Titre('Motif'),
          Note(l.motif),
          const Titre('Déroulé'),
          Bloc(enfants: [
            Ligne('Ouvert par', valeur: ouvertPar),
            Ligne('Ouvert le', valeur: dateCourte(l.ouvertLe)),
            Ligne('Je suis', valeur: l.payeurId == moi ? 'le payeur' : 'le bénéficiaire'),
            if (l.trancheLe != null) Ligne('Tranché le', valeur: dateCourte(l.trancheLe)),
          ]),
          if (l.motifDecision != null) ...[
            const Titre('Motif de la décision'),
            Note(l.motifDecision!),
          ],
          if (l.statut == 'ouvert')
            const Note('Un administrateur MonDo examine le litige et tranche. Tu seras notifié de sa décision.'),
        ];
      }, reessayer: () => ref.invalidate(litigeProvider(litigeId))),
    );
  }
}
