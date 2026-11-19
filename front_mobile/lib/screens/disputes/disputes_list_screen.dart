import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/litiges_provider.dart';
import '../../theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Litiges', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Filtres(
                choix: const {'tous': 'Tous', 'ouvert': 'En cours', 'tranche': 'Tranchés', 'clos': 'Clos'},
                actif: _filtre,
                onChange: (v) => setState(() => _filtre = v),
              ),
            ),
            const SizedBox(height: 8),
            ...selon(litiges, (liste) {
              final vus = liste.where((l) => _filtre == 'tous' || l.statut == _filtre).toList();
              if (vus.isEmpty) {
                return const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Note('Aucun litige. Si un bénéficiaire ne confirme pas ton paiement sous 48 h, tu peux en ouvrir un.'),
                  ),
                ];
              }
              return [
                for (var i = 0; i < vus.length; i++) ...[
                  if (i > 0) const Divider(height: 1, thickness: 1, indent: 70, color: AppColors.border),
                  _Litige(l: vus[i], moi: moi),
                ],
              ];
            }, reessayer: () => ref.invalidate(mesLitigesRefreshableProvider)),
          ],
        ),
      ),
    );
  }
}

/// Un litige, à la manière du profil : icône selon l'état, intitulé et date, état et motif en dessous.
class _Litige extends StatelessWidget {
  const _Litige({required this.l, required this.moi});

  final Litige l;
  final String? moi;

  @override
  Widget build(BuildContext context) {
    final (IconData icone, Color couleur, String etat) = switch (l.statut) {
      'ouvert' => (Icons.hourglass_top, AppColors.orange, 'En examen par MonDo'),
      'tranche' when l.decision == 'paiement_refuse' => (Icons.cancel_outlined, AppColors.orange, 'Tranché : ${decisionLitige(l.decision)}'),
      'tranche' => (Icons.check_circle_outline, AppColors.green, 'Tranché : ${decisionLitige(l.decision)}'),
      'clos' => (Icons.task_alt, AppColors.textMuted, 'Clos'),
      final x => (Icons.gavel_outlined, AppColors.textMuted, x),
    };
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputeDetailScreen(litigeId: l.id))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icone, size: 24, color: couleur)),
          const SizedBox(width: 26),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    l.payeurId == moi ? 'Mon paiement contesté' : 'Paiement qu’on me déclare',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(dateCourte(l.ouvertLe), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 2),
              Text(etat, style: TextStyle(fontSize: 13.5, color: couleur == AppColors.textMuted ? AppColors.textMuted : couleur)),
              const SizedBox(height: 2),
              Text(
                l.motif,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.textMuted),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
