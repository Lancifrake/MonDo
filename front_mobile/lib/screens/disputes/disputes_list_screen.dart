import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/litiges_provider.dart';
import '../../widgets/sobre.dart';
import 'dispute_detail_screen.dart';
import 'open_dispute_screen.dart';

/// Texte d'une décision de litige.
String decisionLitige(String? d) => switch (d) {
      'paiement_valide' => 'paiement reconnu',
      'paiement_refuse' => 'paiement non reconnu',
      'confirme_par_beneficiaire' => 'confirmé par le bénéficiaire',
      null => 'en attente',
      _ => d,
    };

/// Mes litiges : un paiement déclaré que le bénéficiaire ne confirme pas.
/// Seul un administrateur MonDo tranche.
class DisputesListScreen extends ConsumerStatefulWidget {
  const DisputesListScreen({super.key});

  @override
  ConsumerState<DisputesListScreen> createState() => _DisputesState();
}

class _DisputesState extends ConsumerState<DisputesListScreen> {
  String _filtre = 'tous';

  @override
  Widget build(BuildContext context) {
    final litiges = ref.watch(mesLitigesRefreshableProvider);
    final moi = ref.read(apiClientProvider).membreId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Litiges'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenDisputeScreen()));
              ref.invalidate(mesLitigesRefreshableProvider);
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mesLitigesRefreshableProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Filtres(
              choix: const {'tous': 'Tous', 'ouvert': 'En cours', 'tranche': 'Tranchés', 'clos': 'Clos'},
              actif: _filtre,
              onChange: (v) => setState(() => _filtre = v),
            ),
            const SizedBox(height: 12),
            ...selon(litiges, (liste) {
              final vus = liste.where((l) => _filtre == 'tous' || l.statut == _filtre).toList();
              if (vus.isEmpty) {
                return const [
                  Note('Aucun litige. Si un bénéficiaire ne confirme pas ton paiement sous 48 h, tu peux en ouvrir un.'),
                ];
              }
              return [for (final l in vus) _Litige(l: l, moi: moi)];
            }, reessayer: () => ref.invalidate(mesLitigesRefreshableProvider)),
          ],
        ),
      ),
    );
  }
}

class _Litige extends StatelessWidget {
  const _Litige({required this.l, required this.moi});

  final Litige l;
  final String? moi;

  @override
  Widget build(BuildContext context) {
    final (statut, ton) = switch (l.statut) {
      'ouvert' => ('en examen', Ton.action),
      'tranche' => (decisionLitige(l.decision), Ton.encre),
      'clos' => ('clos', Ton.gris),
      _ => (l.statut, Ton.gris),
    };
    return Carte(
      titre: l.payeurId == moi ? 'Mon paiement contesté' : 'Paiement qu’on me déclare',
      detail: '${l.motif}\nOuvert le ${dateCourte(l.ouvertLe)}',
      statut: statut,
      ton: ton,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputeDetailScreen(litigeId: l.id))),
    );
  }
}
